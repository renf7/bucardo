#!/bin/bash
set -e
# Function to initialize database
init_db_against_bucardo_json() {
    # Convert the comma-separated hostnames and other host information into an array
    IFS=',' read -r -a temp <<< "$(hostname),$(hostname -i),$(getent hosts host.docker.internal | awk '{print $2}'),$(getent hosts host.docker.internal | awk '{print $1}'),${OPTIONAL_HOSTNAMES}"

    # Declare an associative array available from Bash version 4
    declare -A all_hostnames

    # Populate the associative array with the hostnames
    for i in "${temp[@]}"; do
        all_hostnames["$i"]=1
    done

    # Initialize JSON file
    json_file="/media/bucardo.json"

    # Create users and databases
    if [[ -f "$json_file" ]]; then
        jq -c '.databases[]' "${json_file}" | while read -r db; do
            id=$(echo "${db}" | jq -r '.id')
            dbname=$(echo "${db}" | jq -r '.dbname')
            host=$(echo "${db}" | jq -r '.host')
            user=$(echo "${db}" | jq -r '.user')
            pass=$(echo "${db}" | jq -r '.pass')

            # Check if $host is in the array of all_hostnames
            if [[ ${all_hostnames["$host"]} ]]; then
                if [[ "$(psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${user}'")" != "1" ]]; then
                    echo psql -U postgres -c "CREATE USER ${user} WITH PASSWORD '${pass}';"
                    psql -U postgres -c "CREATE USER ${user} WITH PASSWORD '${pass}';"
                    psql -h localhost -U postgres -c "SELECT 1 FROM pg_roles WHERE rolname='${user}'"
                fi

                if [[ "$(psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${dbname}'")" != "1" ]]; then
                    echo psql -U postgres -c "CREATE DATABASE ${dbname} OWNER ${user};"
                    psql -U postgres -c "CREATE DATABASE ${dbname} OWNER ${user};"
                    psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${dbname} TO ${user};"
                    psql -h localhost -U postgres -c "SELECT 1 FROM pg_database WHERE datname='${dbname}'"
                fi
            fi
        done
    fi
}

# The JSON reading section
json_reading_section() {
  json_file="/media/bucardo.json"
  if [ -f "$json_file" ]; then

      # Read databases from the JSON file and add each to Bucardo
      jq -c '.databases[]' "${json_file}" | while read -r db; do
          id=$(echo "${db}" | jq -r '.id')
          dbname=$(echo "${db}" | jq -r '.dbname')
          host=$(echo "${db}" | jq -r '.host')
          user=$(echo "${db}" | jq -r '.user')
          pass=$(echo "${db}" | jq -r '.pass')
          port=$(echo "${db}" | jq -r '.port')

          # Assign default values if variables are null
          [ "${host}" == "null" ] && host="localhost"
          [ "${user}" == "null" ] && user="postgres"
          [ "${pass}" == "null" ] && pass="postgres"
          [ "${dbname}" == "null" ] && dbname="postgres"
          [ "${port}" == "null" ] && port="5432"

          # Check if we can connect to host:port
          for attempt in {1..10}; do
              nc -zv "${host}" "${port}" >/dev/null 2>&1 && break || sleep 1
          done

          if [ $attempt -lt 10 ]; then
              args=( "dbname=${dbname}" "host=${host}" "user=${user}" "pass=${pass}" "port=${port}" )
              echo bucardo add db "${id}" "${args[@]}"
              bucardo add db "${id}" "${args[@]}"
          else
              echo "Warning: Cannot connect to ${host}:${port} after 10 attempts. Skipping database ${id}."
          fi
      done

      # Initialize index
      i=1

      # Read syncs from the JSON file and add each to Bucardo
      jq -c '.syncs[]' "${json_file}" | while read -r sync; do
          sources=$(echo "${sync}" | jq -r '.sources[]')
          targets=$(echo "${sync}" | jq -r '.targets[]')
          tables=$(echo "${sync}" | jq -r '.tables')

          # Create array of servers (sources and targets), remove duplicates
          servers=$(echo "${sources},${targets}" | tr ',' '\n' | sort -u)
          for server in $servers; do
              # Check if database was added before trying to add tables or sync
              if bucardo list db "${server}" | grep -q "Status: active"; then
                echo bucardo add all tables --herd=relGroup$i$server db=$server
                  bucardo add all tables --herd=relGroup$i$server db=$server
              else
                  echo "Warning: Database ${server} was not added. Skipping adding tables and sync."
              fi
          done

          # Add sync for each source
          for source in $sources; do
              # Check if database was added before trying to add sync
              if bucardo list db "${source}" | grep -q "Status: active"; then
                echo bucardo add sync sync$i$source relgroup=relGroup$i$source dbs="$source,$targets"
                  bucardo add sync sync$i$source relgroup=relGroup$i$source dbs="$source,$targets"
              else
                  echo "Warning: Database ${source} was not added. Skipping adding sync."
              fi
          done

          # Increment index
          ((i++))
      done

      # List all syncs
      echo "Bucardo syncs:"
      bucardo list sync

      # Restart all syncs
      echo "Restarting all Bucardo syncs:"
      bucardo restart sync

      # Show Bucardo status
      echo "Bucardo status:"
      bucardo status

  fi
}

# File to store the last modification time
last_modification_file="/tmp/last_modification_time"

# Check if the json file exists
json_file="/media/bucardo.json"
if [ ! -f "$json_file" ]; then
    echo "JSON file does not exist: $json_file"
    exit 0
fi

# Get the current modification time
current_modification_time=$(stat -c %Y "$json_file")

# Get the last modification time
if [ -f /tmp/last_modification_time ]; then
  last_modification_time=$(cat $last_modification_file)
else
  last_modification_time=
fi

# If the modification time has changed, run the JSON reading section
if [ "$last_modification_time" != "$current_modification_time" ]; then
    echo $current_modification_time > $last_modification_file
    init_db_against_bucardo_json
    json_reading_section
fi