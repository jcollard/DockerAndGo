#!/bin/bash

# Store the directory this script exists in which I find is often useful
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create default environment variables
D_TAG="golangapp:dev"
D_PORT=8080
D_NETWORK_ID="golangapp-network"
D_DB_NAME="golangapp-db"
D_SUBNET="172.18.0.0/16"
DB_IP="172.18.0.2"

# Create documentation for this script to display when an invalid command is written
read -r -d '' DOCUMENTATION <<EOF
Tool for building and deploying the docker application
Usage:
  build - builds the container
  run - launches the container as a local detached service
  debug - runs the container and connects to it via /bin/sh
  listen - listen to the running service
  kill - kill the running service
  database - create a postgres-db container killing any previous one if necessary
  network - create a docker network for the app to live on
Environment Variables:
  TAG - The docker container tag to use (default: $D_TAG)
  PORT - The port the container should use (default: $D_PORT)
  NETWORK_ID - The name of the network to use (default: $D_NETWORK_ID)
  DB_NAME  - The name of the database container to use (default: $D_DB_NAME)
EOF

# Given a variable name and a value, checks to see if the variable is assigned.
# If it is not yet assigned, assigns it the specified value.
function WITH_DEFAULT {
    VAR_NAME=$1
    VALUE=$2
    if [[ -z ${!VAR_NAME} ]]; then
        eval "$VAR_NAME='$VALUE'"
    fi
}

# Set the TAG variable and PORT variable if they were not specified
WITH_DEFAULT TAG "$D_TAG"
WITH_DEFAULT PORT "$D_PORT"
WITH_DEFAULT NETWORK_ID "$D_NETWORK_ID"
WITH_DEFAULT DB_NAME "$D_DB_NAME"
WITH_DEFAULT SUBNET "$D_SUBNET"

# Specify what to do when we build
function build {
    docker build  -t "$TAG" .
}

# Run the service
function run {
  network
  build
  docker run --rm --network="$NETWORK_ID" -d -p "$PORT":8080 "$TAG"
}

# Debug the service
function debug {
  network
  build
  docker run --rm -it --network="$NETWORK_ID" -p "$PORT":8080 --entrypoint "sh" "$TAG"
}

# Select the running container based on the tag and follow its output
function listen {
  docker ps | grep "$TAG"
  CONTAINER_ID=$(docker ps | grep "$TAG" | awk '{ print $1 }')
  echo "Following '$CONTAINER_ID'"
  docker logs "$CONTAINER_ID" --follow  
}

# Select the running container based on its tag and kill it
function kill {
  docker ps | grep "$TAG"
  CONTAINER_ID=$(docker ps | grep "$TAG" | awk '{ print $1 }')
  echo "Killing '$CONTAINER_ID'"
  docker kill "$CONTAINER_ID"
}

function database {
  network
  docker kill "$DB_NAME" || true
  docker run --name "$DB_NAME" --network="$NETWORK_ID" --ip="$DB_IP" --rm -e POSTGRES_PASSWORD=password -d postgres:14.4-alpine
  sleep 3
  docker exec "$DB_NAME" psql -U postgres -c 'create database demo';
}

function network {
  NET_ID=$(docker network ls | grep "$NETWORK_ID" | awk '{print $1}')
  if [ -z "$NET_ID" ]; then
    echo "Creating network..."
    docker network create --subnet="$SUBNET" "$NETWORK_ID"
  fi
}

function subnet {
  SUBNET=$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' "$NETWORK_ID")
  if [ $? -ne 0 ]; then
    echo "Could not identify subnet for $NETWORK_ID. Exiting...";
    exit $?;
  fi
  echo "$SUBNET"
}

# Specify what to do based on the users argument
ACTION=$1
case "$ACTION" in
    build) build;;
    run) run;;
    debug) debug;;
    listen) listen;;
    kill) kill;;
    database) database;;
    network) network;;
    subnet) subnet;;
    *)
    echo "Cannot find action: '$ACTION'"
    echo "$DOCUMENTATION"
    exit 1
esac