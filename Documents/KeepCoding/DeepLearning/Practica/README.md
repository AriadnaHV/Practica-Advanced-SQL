# POI Engagement Prediction — Deep Learning Project

**KeepCoding Bootcamp XVI — Deep Learning Module**
**Author:** Ariadna Heinz Vallribera

## Overview
This project develops a model to predict the engagement level of tourist Points of Interest (POIs) for the Artgonuts app. The problem is approached both as a regression task (predicting a continuous engagement score) and a classification task (assigning POIs to engagement categories).

## Models
- **Hybrid Deep Learning model**: pretrained ResNet-18 image branch + fully connected metadata branch, fused for joint prediction
- **Convolutional Autoencoder**: trained to extract 64-dimensional image representations for use in the baseline model
- **GradientBoosting baseline**: trained on 92 features combining metadata and autoencoder image representations
