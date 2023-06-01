# Multimaster Postgresql cluster

This project provides master-master Postgresql cluster with scalable amount of nodes. It can be placed on many hosts as well as on one host in with multiple docker containers. All is up to setup.

## Overview

It is a Docker setup for [Bucardo](https://bucardo.org/Bucardo/), a PostgreSQL replication system allowing for multi-source, multi-target replication.
You may create in easy way cluster depending on bucardo.json configuration

## Project Structure

```
.
├── check_json.sh
├── docker-entrypoint.sh
├── Dockerfile
├── install_modules.sh
└── examples
├── 1host_per2nodes
│   ├── bucardo1.json
│   ├── bucardo2.json
│   ├── docker-compose.yml
│   └── init-db.sql
└── 2host_per1node
├── host1
│   ├── bucardo1.json
│   ├── docker-compose.yml
│   └── init-db.sql
└── host2
├── bucardo1.json
├── docker-compose.yml
└── init-db.sql
```

## Scripts and Files

- `Dockerfile`: Contains the instructions to build the Docker image for Bucardo.
- `docker-entrypoint.sh`: The entrypoint script that runs when the Docker container starts up.
- `check_json.sh`: A script for validating and setting up databases from a JSON configuration file. It is executed every 10 seconds. 
  - The logic of the script is triggered only if one of the bellow is met:
    - container just starts up
    - file `bucardo.json` is changed
  - The script logic will not be fired if:
    - there is no `bucardo.json`
    - all databases contained in `bucardo.json` is able to access
- `install_modules.sh`: A script for installing the necessary Perl modules.
- `examples`: Contains two subdirectories `1host_per2nodes` and `2host_per1node`, demonstrating sample configurations for Bucardo.

## Configuration

The project uses a JSON configuration file (`bucardo.json`) to describe the databases and syncs involved in the replication setup.

Here's an example of the structure of the JSON file:

```json
{
  "databases": [
    {
      "id": "db1",
      "dbname": "database1",
      "host": "localhost",
      "port": "5432",
      "user": "postgres",
      "pass": "password"
    },
    {
      "id": "db2",
      "dbname": "database2",
      "host": "localhost",
      "port": "5432",
      "user": "postgres",
      "pass": "password"
    }
  ],
  "syncs": [
    {
      "sources": [
        "db1"
      ],
      "targets": [
        "db2"
      ]
    }
  ]
}
```

### Database Configuration

The `"databases"` array describes the databases to be used for replication. Each database object should contain:

- `"id"`: A unique identifier for the database.
- `"dbname"`: The name of the database.
- `"host"`: The hostname of the database server.
- `"port"`: The port number to connect to the database server.
- `"user"`: The username for authentication.
- `"pass"`: The password for authentication.

### Sync Configuration

The `"syncs"` array describes the syncs for data replication. Each sync object should contain:

- `"sources"`: An array of database IDs from which data is replicated.
- `"targets"`: An array of database IDs to which data is replicated.

The project uses these configurations to set up and manage the replication process. Adjust the configuration to match your setup. For a complete list of configuration options, refer to the [Bucardo documentation](https://bucardo.org/Bucardo/configuration_variables/).

## Running the Project

1. Build the Docker image using the provided Dockerfile. From the root of the project directory, run:

```bash
docker build -t bucardo .
```

2. Start a container using the built image:

```bash
docker run -d -p 5432:5432 -v "/path/to/your/json:/media/bucardo.json" bucardo
```

Ensure to replace `"/path/to/your/json"` with the actual path to your Bucardo configuration JSON file.

Check the container logs for any errors or information regarding the state of replication setup.
