CREATE USER airflow WITH SUPERUSER PASSWORD 'airflow';
CREATE DATABASE airflow OWNER airflow;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;

-- create table for test purpose
\c airflow
CREATE TABLE test_bucardo(id DECIMAL PRIMARY KEY, name VARCHAR, status VARCHAR);