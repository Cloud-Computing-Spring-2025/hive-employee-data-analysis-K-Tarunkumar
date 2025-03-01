-- Load data into a temporary Hive table
CREATE TABLE employees_temp (
    emp_id STRING,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Load data into departments table
CREATE TABLE departments (
    dept_id STRING,
    department_name STRING,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Load data into the temporary table
LOAD DATA LOCAL INPATH 'employees.csv' INTO TABLE employees_temp;
LOAD DATA LOCAL INPATH 'departments.csv' INTO TABLE departments;

-- Create partitioned table for employees
CREATE TABLE employees (
    emp_id STRING,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
PARTITIONED BY (department STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Move data into partitioned table
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE employees PARTITION(department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department FROM employees_temp;

-- Queries:

-- 1. Retrieve all employees who joined after 2015
SELECT * FROM employees WHERE join_date > '2015-12-31';

-- 2. Find the average salary of employees in each department
SELECT department, AVG(salary) AS avg_salary FROM employees GROUP BY department;

-- 3. Identify employees working on the 'Alpha' project
SELECT * FROM employees WHERE project = 'Alpha';

-- 4. Count the number of employees in each job role
SELECT job_role, COUNT(*) AS employee_count FROM employees GROUP BY job_role;

-- 5. Retrieve employees whose salary is above the average salary of their department
SELECT e.* FROM employees e 
JOIN (SELECT department, AVG(salary) AS avg_salary FROM employees GROUP BY department) d
ON e.department = d.department
WHERE e.salary > d.avg_salary;

-- 6. Find the department with the highest number of employees
SELECT department, COUNT(*) AS emp_count FROM employees GROUP BY department ORDER BY emp_count DESC LIMIT 1;

-- 7. Exclude employees with null values in any column
SELECT * FROM employees WHERE emp_id IS NOT NULL AND name IS NOT NULL AND age IS NOT NULL AND 
job_role IS NOT NULL AND salary IS NOT NULL AND project IS NOT NULL AND join_date IS NOT NULL AND department IS NOT NULL;

-- 8. Join employees and departments tables to display employee details along with department locations
SELECT e.*, d.location FROM employees e
JOIN departments d ON e.department = d.department_name;

-- 9. Rank employees within each department based on salary
SELECT emp_id, name, department, salary, 
RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees;

-- 10. Find the top 3 highest-paid employees in each department
SELECT * FROM (
    SELECT emp_id, name, department, salary, 
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM employees
) ranked_employees WHERE salary_rank <= 3;
