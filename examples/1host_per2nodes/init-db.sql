CREATE USER example WITH SUPERUSER PASSWORD 'example';
CREATE DATABASE example OWNER example;
GRANT ALL PRIVILEGES ON DATABASE example TO example;

-- create table for test purpose
\c example
CREATE TABLE test_bucardo(id DECIMAL PRIMARY KEY, name VARCHAR, status VARCHAR);