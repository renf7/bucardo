# Call check bucardo.json in infinity loop in background
while true; do sleep 10; apply-bucardo-config.sh;   done &

# Call entrypoint and cmd of the postgres docker image
# It is blocking command, so it makes container to run permanently
docker-entrypoint.sh postgres