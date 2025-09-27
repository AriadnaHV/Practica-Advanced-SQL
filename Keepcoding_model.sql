
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    name VARCHAR (255),
    email VARCHAR (255),
    address VARCHAR (255),
    incorporation_date DATE,
    salary_scale INT,
    job_title VARCHAR (255),
    module_id INT
);
ALTER TABLE staff
ADD CONSTRAINT staff_unique_email UNIQUE (email);
ALTER TABLE staff
ALTER COLUMN email SET NOT NULL;


CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    name VARCHAR (255),
    email VARCHAR (255),
    address VARCHAR (255),
    payment DECIMAL (8,2),
    bootcamp_id INT,
    standalone_module_id INT,
    grade_id INT
);
ALTER TABLE students
ADD CONSTRAINT students_unique_email UNIQUE (email);
ALTER TABLE students
ALTER COLUMN email SET NOT NULL;


CREATE TABLE teachers (
    teacher_id SERIAL PRIMARY KEY,
    name VARCHAR (255),
    email VARCHAR (255),
    address VARCHAR (255),
    hourly_rate DECIMAL (8,2),
    module_id INT
);
ALTER TABLE teachers
ADD CONSTRAINT teachers_unique_email UNIQUE (email);
ALTER TABLE teachers
ALTER COLUMN email SET NOT NULL;

CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INT,
    module_id INT,
    teacher_id INT,
    staff_id INT,
    has_attempted_first BOOLEAN,
    has_attempted_second BOOLEAN,
    has_passed BOOLEAN
);

CREATE TABLE bootcamps (
    bootcamp_id SERIAL PRIMARY KEY,
    bootcamp_name VARCHAR (255),
    bootcamp_edition VARCHAR (10),
    tutor_teacher_id INT,
    price DECIMAL (8,2),
    module_id INT,
    staff_admin_id INT,
    student_id INT
);

CREATE TABLE modules (
    module_id SERIAL PRIMARY KEY,
    module_name VARCHAR (255),
    module_edition VARCHAR (10),
    teacher_id INT,
    staff_id INT,
    student_id INT,
    bootcamp_id INT,
    standalone_price DECIMAL (8,2)
);

ALTER TABLE staff
ADD CONSTRAINT fk_staff_module_id 
    FOREIGN KEY (module_id) REFERENCES modules(module_id);

ALTER TABLE students
ADD CONSTRAINT fk_students_bootcamp_id
    FOREIGN KEY (bootcamp_id) REFERENCES bootcamps(bootcamp_id),
ADD CONSTRAINT fk_students_standalone_module_id
    FOREIGN KEY (standalone_module_id) REFERENCES modules(module_id),
ADD CONSTRAINT fk_students_grade_id
    FOREIGN KEY (grade_id) REFERENCES grades(grade_id);

ALTER TABLE teachers
ADD CONSTRAINT fk_teachers_module_id
    FOREIGN KEY (module_id) REFERENCES modules(module_id);

ALTER TABLE grades
ADD CONSTRAINT fk_grades_student_id
    FOREIGN KEY (student_id) REFERENCES students(student_id),
ADD CONSTRAINT fk_grades_module_id
    FOREIGN KEY (module_id) REFERENCES modules(module_id),
ADD CONSTRAINT fk_grades_teacher_id
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
ADD CONSTRAINT fk_grades_staff_id
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id);

ALTER TABLE bootcamps
ADD CONSTRAINT fk_bootcamps_tutor_teacher_id
    FOREIGN KEY (tutor_teacher_id) REFERENCES teachers(teacher_id),
ADD CONSTRAINT fk_bootcamps_module_id
    FOREIGN KEY (module_id) REFERENCES modules(module_id),
ADD CONSTRAINT fk_bootcamps_staff_admin_id
    FOREIGN KEY (staff_admin_id) REFERENCES staff(staff_id),
ADD CONSTRAINT fk_bootcamps_student_id
    FOREIGN KEY (student_id) REFERENCES students(student_id);

ALTER TABLE modules
ADD CONSTRAINT fk_modules_teacher_id
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
ADD CONSTRAINT fk_modules_staff_id
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
ADD CONSTRAINT fk_modules_student_id
    FOREIGN KEY (student_id) REFERENCES students(student_id),
ADD CONSTRAINT fk_modules_bootcamp_id
    FOREIGN KEY (bootcamp_id) REFERENCES bootcamps(bootcamp_id);

