#!/bin/bash

# Quick Entrypoint Script for Brick X Auth Service
# Usage: ./quick.sh [build|start|test|stop|clean|logs|status|all] [version]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

ACTION=${1:-all}
VERSION_ARG=$2

print_header() {
    echo -e "\033[1;34m==== $1 ===="
    echo -e "\033[0m"
}

case $ACTION in
    build)
        print_header "Build"
        "$SCRIPT_DIR/build.sh" $VERSION_ARG
        ;;
    start|run)
        print_header "Start"
        "$SCRIPT_DIR/start.sh" $VERSION_ARG
        ;;
    test)
        print_header "Test"
        "$SCRIPT_DIR/test.sh"
        ;;
    stop)
        print_header "Stop"
        "$SCRIPT_DIR/stop.sh"
        ;;
    clean)
        print_header "Clean"
        "$SCRIPT_DIR/clean.sh" $VERSION_ARG
        ;;
    logs)
        print_header "Logs"
        docker logs -f $CONTAINER_NAME
        ;;
    status)
        print_header "Status"
        docker ps -a --filter name=$CONTAINER_NAME
        ;;
    all|*)
        print_header "Full Cycle: Build → Start → Test"
        "$SCRIPT_DIR/build.sh" $VERSION_ARG
        "$SCRIPT_DIR/start.sh" $VERSION_ARG
        "$SCRIPT_DIR/test.sh"
        print_header "Status"
        docker ps -a --filter name=$CONTAINER_NAME
        ;;
esac 