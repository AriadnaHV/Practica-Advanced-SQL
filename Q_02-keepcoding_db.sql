CREATE TABLE staff (
   staff_id SERIAL PRIMARY KEY,
   name VARCHAR(255),
   email VARCHAR(255) UNIQUE NOT NULL,
   address VARCHAR(255),
   incorporation_date DATE,
   salary_scale INT,
   job_title VARCHAR(255),
   module_id INT,
   FOREIGN KEY (module_id) REFERENCES modules(module_id)
);

CREATE TABLE students (
   student_id SERIAL PRIMARY KEY,
   name VARCHAR(255),
   email VARCHAR(255) UNIQUE NOT NULL,
   address VARCHAR(255),
   payment DECIMAL(10, 2),  -- Increased precision for monetary values
   bootcamp_id INT,
   standalone_module_id INT,
   grade_id INT,
   FOREIGN KEY (bootcamp_id) REFERENCES bootcamps(bootcamp_id),
   FOREIGN KEY (standalone_module_id) REFERENCES modules(module_id),
   FOREIGN KEY (grade_id) REFERENCES grades(grade_id)
);

CREATE TABLE teachers (
   teacher_id SERIAL PRIMARY KEY,
   name VARCHAR(255),
   email VARCHAR(255) UNIQUE NOT NULL,
   address VARCHAR(255),
   hourly_rate DECIMAL(10, 2),
   module_id INT,
   FOREIGN KEY (module_id) REFERENCES modules(module_id)
);

CREATE TABLE grades (
   grade_id SERIAL PRIMARY KEY,
   student_id INT,
   module_id INT,
   teacher_id INT,
   staff_id INT,
   has_attempted_first BOOLEAN,
   has_attempted_second BOOLEAN,
   has_passed BOOLEAN,
   FOREIGN KEY (student_id) REFERENCES students(student_id),
   FOREIGN KEY (module_id) REFERENCES modules(module_id),
   FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
   FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE TABLE bootcamps (
   bootcamp_id SERIAL PRIMARY KEY,
   bootcamp_name VARCHAR(255),
   bootcamp_edition VARCHAR(10),
   tutor_teacher_id INT,
   price DECIMAL(10, 2),
   module_id INT,
   staff_admin_id INT,
   student_id INT,
   FOREIGN KEY (tutor_teacher_id) REFERENCES teachers(teacher_id),
   FOREIGN KEY (module_id) REFERENCES modules(module_id),
   FOREIGN KEY (staff_admin_id) REFERENCES staff(staff_id),
   FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE modules (
   module_id SERIAL PRIMARY KEY,
   module_name VARCHAR(255),
   module_edition VARCHAR(10),
   teacher_id INT,
   staff_id INT,
   student_id INT,
   bootcamp_id INT,
   standalone_price DECIMAL(10, 2),
   FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
   FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
   FOREIGN KEY (student_id) REFERENCES students(student_id),
   FOREIGN KEY (bootcamp_id) REFERENCES bootcamps(bootcamp_id)
);
