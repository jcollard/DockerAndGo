#!/bin/bash

# Store the directory this script exists in which I find is often useful
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create default environment variables
D_TAG="golangapp:dev"
D_PORT=8080

# Create documentation for this script to display when an invalid command is written
read -r -d '' DOCUMENTATION <<EOF
Tool for building and deploying the docker application
Usage:
  build - builds the container
  run - launches the container as a local detached service
  debug - runs the container and connects to it via /bin/sh
  listen - listen to the running service
  kill - kill the running service
Environment Variables:
  TAG - The docker container tag to use (default: $D_TAG)
  PORT - The port the container should use (default $D_PORT)
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

# Specify what to do when we build
function build {
    docker build  -t "$TAG" .
}

# Run the service
function run {
  build
  docker run --rm -d -p "$PORT":8080 "$TAG"
}

# Debug the service
function debug {
  build
  docker run --rm -it -p "$PORT":8080 --entrypoint "/bin/sh" "$TAG"
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


# Specify what to do based on the users argument
ACTION=$1
case "$ACTION" in
    build) build;;
    run) run;;
    debug) debug;;
    listen) listen;;
    kill) kill;;
    *)
    echo "Cannot find action: '$ACTION'"
    echo "$DOCUMENTATION"
    exit 1
esac