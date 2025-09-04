-- Department Table
CREATE TABLE department (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE NOT NULL
);

SELECT * FROM public.department;


-- Employee Table
CREATE TABLE employee (
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    dept_id INT REFERENCES department(dept_id),
    hire_date DATE NOT NULL,
    salary NUMERIC(10,2) NOT NULL
);

SELECT * FROM public.employee;


-- Leave Table
CREATE TABLE emp_leave (
    leave_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employee(emp_id),
    leave_date DATE NOT NULL,
    reason VARCHAR(255)
);

INSERT INTO department (dept_name) VALUES ('HR'), ('IT'), ('Finance');


INSERT INTO employee (emp_name, email, dept_id, hire_date, salary) VALUES
('Meenal Sharma', 'meenal@company.com', 2, '2023-06-01', 50000),
('Raj Singh', 'raj@company.com', 1, '2022-02-15', 40000),
('Aditi Rao', 'aditi@company.com', 3, '2021-11-20', 60000);


-- Create roles
CREATE ROLE admin LOGIN PASSWORD 'admin123';
CREATE ROLE manager LOGIN PASSWORD 'manager123';
CREATE ROLE readonly LOGIN PASSWORD 'readonly123';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE payroll_db TO admin;
GRANT SELECT, UPDATE ON employee TO manager;
GRANT SELECT ON employee, department TO readonly;

SELECT d.dept_name, AVG(e.salary)
FROM employee e
JOIN department d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

EXPLAIN ANALYZE
SELECT d.dept_name, AVG(e.salary)
FROM employee e
JOIN department d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

CREATE INDEX idx_dept_id ON employee(dept_id);  -- query optimization

DROP INDEX idx_dept_id;


CREATE TABLE salary_log (
    log_id SERIAL PRIMARY KEY,
    emp_id INT,
    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),
    changed_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT * FROM public.salary_log;


CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO salary_log(emp_id, old_salary, new_salary)
    VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER salary_update_trigger
AFTER UPDATE OF salary ON employee
FOR EACH ROW
EXECUTE FUNCTION log_salary_change();


CREATE OR REPLACE FUNCTION update_salary_with_bonus(bonus_percent NUMERIC)
RETURNS VOID AS $$
BEGIN
    UPDATE employee
    SET salary = salary + (salary * bonus_percent / 100);
END;
$$ LANGUAGE plpgsql;

-- Example: Add 10% bonus to all employees
SELECT update_salary_with_bonus(10);


SELECT emp_id, emp_name, salary FROM employee;


DROP FUNCTION update_salary_with_bonus(NUMERIC);


CREATE OR REPLACE FUNCTION update_salary_with_bonus(bonus_percent NUMERIC)
RETURNS INTEGER AS $$
DECLARE
    rows_updated INTEGER;
BEGIN
    UPDATE employee
    SET salary = salary + (salary * bonus_percent / 100);

    GET DIAGNOSTICS rows_updated = ROW_COUNT; -- captures number of rows affected

    RETURN rows_updated;
END;
$$ LANGUAGE plpgsql;


-- Add column only once
ALTER TABLE employee ADD COLUMN base_salary NUMERIC(10,2);

-- Store original salaries once
UPDATE employee SET base_salary = salary;

-- View for Active Employees
CREATE OR REPLACE VIEW active_employees AS
SELECT emp_id, emp_name, email, dept_id, salary
FROM employee
WHERE salary > 0;

SELECT * FROM active_employees;

--  Updating for checking inactive Employees
UPDATE employee
SET salary = 0
WHERE emp_id = 2;

SELECT * FROM active_employees;

-- Undo 
UPDATE employee
SET salary = base_salary
WHERE emp_id = 2;

