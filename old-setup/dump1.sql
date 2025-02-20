-- dump.sql: A sample dump for testing purposes

-- Create database and switch to it
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

-- Create a table
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    position VARCHAR(50)
);

-- Insert sample data
INSERT INTO employees (name, position) VALUES ('Alice', 'Manager');
INSERT INTO employees (name, position) VALUES ('Bob', 'Developer');
INSERT INTO employees (name, position) VALUES ('Charlie', 'Designer');
