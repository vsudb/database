CREATE TABLE subject
(
    subj_id   int NOT NULL,
    subj_name varchar(60),
    HOUR      int,
    semester  int
);


ALTER TABLE subject
    ADD PRIMARY KEY (subj_id);

CREATE TABLE university
(
    univ_id   int NOT NULL,
    univ_name varchar(160),
    rating    int,
    city      varchar(60)
);


ALTER TABLE university
    ADD PRIMARY KEY (univ_id);

CREATE TABLE lecturer
(
    lecturer_id int NOT NULL,
    surname     varchar(60),
    name        varchar(60),
    city        varchar(60),
    univ_id     int
);

ALTER TABLE lecturer
    ADD PRIMARY KEY (lecturer_id);

ALTER TABLE lecturer
    ADD CONSTRAINT univlect_for_key
        FOREIGN KEY (univ_id) REFERENCES university (univ_id);

CREATE TABLE student
(
    student_id int NOT NULL,
    surname    varchar(60),
    name       varchar(60),
    stipend    int,
    kurs       int,
    city       varchar(60),
    birthday   DATE,
    univ_id    int
);

ALTER TABLE student
    ADD PRIMARY KEY (student_id);

ALTER TABLE student
    ADD CONSTRAINT univ_for_key
        FOREIGN KEY (univ_id) REFERENCES university (univ_id);

CREATE TABLE exam_marks
(
    exam_id    int NOT NULL,
    student_id int NOT NULL,
    subj_id    int NOT NULL,
    mark       int,
    exam_date  DATE
);

ALTER TABLE exam_marks
    ADD PRIMARY KEY (exam_id,
                     student_id,
                     subj_id);

ALTER TABLE exam_marks
    ADD CONSTRAINT student_for_key
        FOREIGN KEY (student_id) REFERENCES student (student_id);


ALTER TABLE exam_marks
    ADD CONSTRAINT subject_for_key
        FOREIGN KEY (subj_id) REFERENCES subject (subj_id);


CREATE INDEX student_id_1 ON exam_marks (student_id);

CREATE TABLE subj_lect
(
    lecturer_id int NOT NULL,
    subj_id     int NOT NULL
);

ALTER TABLE subj_lect
    ADD PRIMARY KEY (lecturer_id,
                     subj_id);

ALTER TABLE subj_lect
    ADD CONSTRAINT lect_for_key
        FOREIGN KEY (lecturer_id) REFERENCES lecturer (lecturer_id);

ALTER TABLE subj_lect
    ADD CONSTRAINT subj_for_key
        FOREIGN KEY (subj_id) REFERENCES subject (subj_id);