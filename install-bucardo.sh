#!/bin/bash
set -e


# Function to install and configure Bucardo
install_bucardo() {
    # Check if the bucardo user already exists, if not create it
    if [[ "$(psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='bucardo'")" != "1" ]]; then
        psql -U postgres -c "CREATE ROLE bucardo WITH SUPERUSER LOGIN PASSWORD 'bucardo';"
    fi

    # Check if the bucardo database already exists, if not create it
    if [[ "$(psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='bucardo'")" != "1" ]]; then
        psql -U postgres -c "CREATE DATABASE bucardo OWNER bucardo;"
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE bucardo TO bucardo;"
    fi

    # Initialize Bucardo
    bucardo install --batch
}

# Call the functions
install_bucardo