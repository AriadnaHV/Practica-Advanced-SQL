import os
import torch
import torch.nn as nn
import numpy as np
import pandas as pd
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms
from sklearn.cluster import KMeans
from torchvision import models


##################################
# Constants
##################################
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD  = [0.229, 0.224, 0.225]
LABEL_MAP = {-1: 0, 0: 1, 1: 2, 2: 3}

METADATA_FEATURES = [
    'tier_norm', 'xps_norm',
    'locationLon_norm', 'locationLat_norm',
    'categories_count', 'tags_count',
    'Arquitectura', 'Ciencia', 'Cine', 'Cultura', 'Escultura', 'Gastronomía',
    'Historia', 'Misterio', 'Naturaleza', 'Ocio', 'Patrimonio', 'Pintura',
    'dist_centroid_0', 'dist_centroid_1', 'dist_centroid_2', 'dist_centroid_3',
    'dist_centroid_4', 'dist_centroid_5', 'dist_centroid_6', 'dist_centroid_7',
    'dist_centroid_8', 'dist_centroid_9'
]

##################################
# Transform pipelines
##################################
transform_train = transforms.Compose([
    transforms.Resize(224),
    transforms.RandomHorizontalFlip(p=0.5),
    transforms.RandomRotation(degrees=10),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    transforms.RandomAffine(degrees=0, translate=(0.05, 0.05)),
    transforms.ToTensor(),
    transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD)
])

transform_val_test = transforms.Compose([
    transforms.Resize(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD)
])

transform_autoencoder = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD)
])

##################################
# Normalization of tier and xps
##################################
def normalize_features(df):
    """
    Applies fixed-range normalization to tier and xps.
    Returns the dataframe with added normalized columns.
    """
    df = df.copy()
    df['tier_norm'] = (df['tier'] - 1) / 3
    df['xps_norm']  = df['xps'] / 1000
    return df

##################################
# Normalization of coordinates
##################################
def normalize_coordinates(df, lon_mean, lon_std, lat_mean, lat_std):
    """
    Normalizes locationLon and locationLat using training set statistics.
    Call this separately after computing stats from df_train only.
    """
    df = df.copy()
    df['locationLon_norm'] = (df['locationLon'] - lon_mean) / lon_std
    df['locationLat_norm'] = (df['locationLat'] - lat_mean) / lat_std
    return df

##################################
# Custom POIDataset class
##################################
class POIDataset(Dataset):
    """
    Custom PyTorch Dataset for the Artgonuts POI dataset.
    Returns (image, metadata, label, score) for each POI.
    
    Args:
        df:          DataFrame (train, val, or test)
        prefix_path: Base path to image folder in Google Drive
        transform:   torchvision transform pipeline
    """
    def __init__(self, df, prefix_path, transform=None):
        self.df          = df.reset_index(drop=True)
        self.prefix_path = prefix_path
        self.transform   = transform

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]

        # --- Image ---
        img_path = os.path.join(self.prefix_path, row['main_image_path'])
        image = Image.open(img_path).convert('RGB')
        if self.transform:
            image = self.transform(image)

        # --- Metadata ---
        metadata = torch.tensor(
            row[METADATA_FEATURES].values.astype(np.float32),
            dtype=torch.float32
        )

        # --- Targets ---
        label = torch.tensor(LABEL_MAP[row['engagement_label']], dtype=torch.long)
        score = torch.tensor(row['E'], dtype=torch.float32)

        return image, metadata, label, score

#############################
# Image-only Dataset
#############################
class POIImageDataset(Dataset):
    """
    Image-only dataset for training the autoencoder.
    Returns only the image tensor for each POI.
    """
    def __init__(self, df, prefix_path, transform=None):
        self.df          = df.reset_index(drop=True)
        self.prefix_path = prefix_path
        self.transform   = transform

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row      = self.df.iloc[idx]
        img_path = os.path.join(self.prefix_path, row['main_image_path'])
        image    = Image.open(img_path).convert('RGB')
        if self.transform:
            image = self.transform(image)
        return image
    
##################################
# Geographic clustering
##################################
def fit_kmeans(df_train, k=10):
    """
    Fits KMeans on training set coordinates only.
    Returns the fitted KMeans model.
    
    Args:
        df_train: Training set DataFrame
        k:        Number of clusters (default=17)
    
    Returns:
        fitted KMeans model
    """
    coords_train = df_train[['locationLon', 'locationLat']].values
    kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
    kmeans.fit(coords_train)
    return kmeans

def compute_centroid_distances(df, kmeans, dist_mean=None, dist_std=None):
    """
    Computes distance from each POI to each cluster centroid.
    Returns DataFrame with k=10 new distance columns.
    
    For normalization, pass dist_mean and dist_std computed from
    training set only. If None, returns raw distances.
    
    Args:
        df:         DataFrame (train, val, or test)
        kmeans:     Fitted KMeans model from fit_kmeans()
        dist_mean:  Mean of distances from training set (optional)
        dist_std:   Std of distances from training set (optional)
    
    Returns:
        DataFrame with added 'dist_centroid_0' ... 'dist_centroid_9' columns
    """
    df = df.copy()
    coords = df[['locationLon', 'locationLat']].values
    centroids = kmeans.cluster_centers_
    
    for i, centroid in enumerate(centroids):
        distances = np.sqrt(((coords - centroid) ** 2).sum(axis=1))
        col_name = f'dist_centroid_{i}'
        df[col_name] = distances
        if dist_mean is not None and dist_std is not None:
            df[col_name] = (df[col_name] - dist_mean[i]) / dist_std[i]
    
    return df

def assign_clusters(df, kmeans):
    """
    Assigns cluster IDs to a DataFrame using a fitted KMeans model.
    Call this separately for train, val and test after fitting on train only.
    
    Args:
        df:     DataFrame (train, val, or test)
        kmeans: Fitted KMeans model from fit_kmeans()
    
    Returns:
        DataFrame with added 'geo_cluster' column
    """
    df = df.copy()
    coords = df[['locationLon', 'locationLat']].values
    df['geo_cluster'] = kmeans.predict(coords)
    return df

#############################
# Regression model
#############################
class POIRegressionModel(nn.Module):
    """
    Hybrid model for POI engagement score regression.
    - Image branch: pretrained ResNet-18 (frozen) + Linear(512 -> 128)
    - Metadata branch: Linear(28 -> 64) -> Linear(64 -> 64)
    - Fusion: concatenate (192) -> Linear(192 -> 64) -> Linear(64 -> 1)
    """
    def __init__(self, n_metadata_features=28, dropout=0.3):
        super(POIRegressionModel, self).__init__()

        # --- Image branch ---
        resnet = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)
        # Freeze all convolutional layers
        for param in resnet.parameters():
            param.requires_grad = False
        # Replace final FC layer with custom projection
        resnet.fc = nn.Linear(512, 128)
        # FC layer is trainable by default
        self.image_branch = resnet

        # --- Metadata branch ---
        self.metadata_branch = nn.Sequential(
            nn.Linear(n_metadata_features, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, 64),
            nn.ReLU(),
            nn.Dropout(dropout)
        )

        # --- Fusion layers ---
        self.fusion = nn.Sequential(
            nn.Linear(128 + 64, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, 1)
        )

    def forward(self, image, metadata):
        # Image features
        img_features = self.image_branch(image)        # (batch, 128)
        
        # Metadata features
        meta_features = self.metadata_branch(metadata) # (batch, 64)
        
        # Fusion
        combined = torch.cat([img_features, meta_features], dim=1)  # (batch, 192)
        output = self.fusion(combined)                 # (batch, 1)
        
        return output.squeeze(1)  # (batch,) for MSE loss compatibility  

#############################
# Classification model
#############################
class POIClassificationModel(nn.Module):
    """
    Hybrid model for POI engagement label classification.
    - Image branch: pretrained ResNet-18 (frozen) + Linear(512 -> 128)
    - Metadata branch: Linear(28 -> 64) -> Linear(64 -> 64)
    - Fusion: concatenate (192) -> Linear(192 -> 64) -> Linear(64 -> 4)
    """
    def __init__(self, n_metadata_features=28, n_classes=4, dropout=0.3):
        super(POIClassificationModel, self).__init__()

        # --- Image branch ---
        resnet = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)
        for param in resnet.parameters():
            param.requires_grad = False
        resnet.fc = nn.Linear(512, 128)
        self.image_branch = resnet

        # --- Metadata branch ---
        self.metadata_branch = nn.Sequential(
            nn.Linear(n_metadata_features, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, 64),
            nn.ReLU(),
            nn.Dropout(dropout)
        )

        # --- Fusion layers ---
        self.fusion = nn.Sequential(
            nn.Linear(128 + 64, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, n_classes)
        )

    def forward(self, image, metadata):
        img_features  = self.image_branch(image)         # (batch, 128)
        meta_features = self.metadata_branch(metadata)   # (batch, 64)
        combined      = torch.cat([img_features, meta_features], dim=1)  # (batch, 192)
        output        = self.fusion(combined)             # (batch, 4)
        return output
    
#############################
# Convolutional Autoencoder class
#############################
class POIAutoencoder(nn.Module):
    """
    Convolutional autoencoder for POI images.
    Input: 3 x 128 x 128 (original image size, no resizing needed)
    Compresses to a 64-dimensional latent vector.
    Only the encoder is used after training to extract image features
    for the GradientBoosting model.
    """
    def __init__(self, latent_dim=64):
        super(POIAutoencoder, self).__init__()

        # --- Encoder ---
        self.encoder = nn.Sequential(
            # 3 x 128 x 128 -> 32 x 64 x 64
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            # 32 x 64 x 64 -> 64 x 32 x 32
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            # 64 x 32 x 32 -> 128 x 16 x 16
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
        )
        self.encoder_fc = nn.Linear(128 * 16 * 16, latent_dim)

        # --- Decoder ---
        self.decoder_fc = nn.Linear(latent_dim, 128 * 16 * 16)
        self.decoder = nn.Sequential(
            # 128 x 16 x 16 -> 64 x 32 x 32
            nn.ConvTranspose2d(128, 64, kernel_size=2, stride=2),
            nn.ReLU(),
            # 64 x 32 x 32 -> 32 x 64 x 64
            nn.ConvTranspose2d(64, 32, kernel_size=2, stride=2),
            nn.ReLU(),
            # 32 x 64 x 64 -> 3 x 128 x 128
            nn.ConvTranspose2d(32, 3, kernel_size=2, stride=2),
            nn.Sigmoid()
        )

    def encode(self, x):
        x = self.encoder(x)
        x = x.view(x.size(0), -1)  # flatten
        x = self.encoder_fc(x)
        return x

    def decode(self, z):
        x = self.decoder_fc(z)
        x = x.view(x.size(0), 128, 16, 16)  # unflatten
        x = self.decoder(x)
        return x

    def forward(self, x):
        z = self.encode(x)
        x_reconstructed = self.decode(z)
        return x_reconstructed, z