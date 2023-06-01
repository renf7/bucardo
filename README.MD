# Multimaster Postgresql cluster

This project provides master-master Postgresql cluster with scalable amount of nodes. It can be placed on many hosts as well as on one host with multiple docker containers. All is up to setup.

## Overview

It is a Docker setup for [Bucardo](https://bucardo.org/Bucardo/), a PostgreSQL replication system allowing for multi-source, multi-target replication.
You may create in easy way cluster depending on bucardo.json configuration

The project is automatically built in docker hub. You may find it under:
 - Github https://github.com/renf7/bucardo
 - Docker hub https://hub.docker.com/r/renf7/bucardo

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

### JSON config

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

#### Database Configuration

The `"databases"` array describes the databases to be used for replication. Each database object should contain:

- `"id"`: A unique identifier for the database.
- `"dbname"`: The name of the database.
- `"host"`: The hostname of the database server.
- `"port"`: The port number to connect to the database server.
- `"user"`: The username for authentication.
- `"pass"`: The password for authentication.

#### Sync Configuration

The `"syncs"` array describes the syncs for data replication. Each sync object should contain:

- `"sources"`: An array of database IDs from which data is replicated.
- `"targets"`: An array of database IDs to which data is replicated.

The project uses these configurations to set up and manage the replication process. Adjust the configuration to match your setup. For a complete list of configuration options, refer to the [Bucardo documentation](https://bucardo.org/Bucardo/configuration_variables/).

### Set up the container

Before running the container, you need to configure: 
- the environment variable `OPTIONAL_HOSTNAMES` 
- volume mount of `bucardo.json` configuration file. 
- optionaly you may use features of `posrgres:15.3` image such us  `/docker-entrypoint-initdb.d` folder to execute database scripts. Note `renf7/bucardo` docker image bases on `postgres:15.3` docker image that inherits all functionalities on top of that. Please check https://hub.docker.com/_/postgres/ for more details

#### Using Docker Compose

In your \`docker-compose.yml\` file, define the environment variables and volumes for the \`bucardo\` service:

```yaml
services:
  bucardo:
    image: bucardo/bucardo:latest
    environment:
      - OPTIONAL_HOSTNAMES=pg_container,vm_host
    volumes:
      - ./bucardo.json:/media/bucardo.json
```

Make sure to adjust the \`OPTIONAL_HOSTNAMES\` variable and the volume path according to your setup.

To start the container using Docker Compose, run the following command:

```bash
docker-compose up -d
```

#### Using Docker CLI

If you prefer to use the Docker CLI directly, you can run the container with the necessary environment variables and volume mounts:

```bash
docker run -e OPTIONAL_HOSTNAMES="pg_container,vm_host" -v "$(pwd)/bucardo.json:/media/bucardo.json" bucardo/bucardo:latest
```

Adjust the \`OPTIONAL_HOSTNAMES\` variable and the volume mount path according to your setup.

Ensure that you are running the command in the same directory where the \`bucardo.json\` file is located.

By following these steps, you will have the container set up with the required environment variables and the \`bucardo.json\` configuration file mounted. This allows Bucardo to access the necessary database configurations and synchronize data effectively.

## Troubleshooting

In case of issues, here are some steps you might take to diagnose and fix them:

1. **Review the JSON configuration file (`bucardo.json`)**: Make sure the structure of your JSON file is correct and the databases and syncs are properly configured.

2. **Check the Docker logs**: Use the `docker logs <container-id>` command to check the logs of the Docker containers. The logs often contain useful information about the issue.

3. **Check the PostgreSQL logs**: If the issue seems related to the databases, checking the PostgreSQL logs might be helpful. Depending on your PostgreSQL setup, you can typically find these logs in the `pg_log` directory of your PostgreSQL data directory.

4. **Check the Bucardo logs**: Bucardo writes logs to the `bucardo.log` file in the Bucardo home directory (`/var/log/bucardo`). You can use these logs to diagnose issues related to replication.

5. **Review the Bucardo documentation**: The [Bucardo documentation](https://bucardo.org/Bucardo/) can be a good resource for understanding the workings of Bucardo and resolving issues related to it.

Remember, error messages are often descriptive and provide a good starting point for troubleshooting. If you're seeing a specific error message, a quick web search can often lead to a solution.

## Note

Please be aware that this setup is an example of how to use Bucardo for PostgreSQL replication in a Docker environment. Depending on your specific needs and environment, you may need to adjust the provided scripts, JSON files, and Docker configuration.

The Dockerfile, scripts, and JSON files are designed to be simple and understandable to serve as a starting point. For a production environment, you would likely need to add more robust error handling, security measures, and possibly other features.

## Examples

In the \`examples\` directory, you can find examples of how you could use this setup:

1. **1host_per2nodes**: This example shows how to set up Bucardo replication between two PostgreSQL databases on the same host. It includes a Docker Compose file, two Bucardo JSON configuration files (one for each database node), and an SQL script for initializing the databases.

2. **2host_per1node**: This example demonstrates setting up Bucardo replication between two PostgreSQL databases, each on a separate host. It contains two subdirectories (one for each host), each with a Docker Compose file, a Bucardo JSON configuration file, and an SQL script for initializing the database.

You can run these examples by navigating into the respective directories and executing the Docker Compose command:

```bash
docker compose up
```

Remember to adjust the Bucardo JSON configuration files and the SQL scripts according to your needs.