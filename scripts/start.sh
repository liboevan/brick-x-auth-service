#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Function to show help
show_help() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Brick X Auth Service - Start Script${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e ""
    echo -e "${GREEN}Purpose:${NC}"
    echo -e "  Start the auth service container"
    echo -e ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  $0 [options]"
    echo -e ""
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${YELLOW}--force${NC}    - Force restart (stop existing container first)"
    echo -e "  ${YELLOW}--help${NC}     - Show this help"
    echo -e ""
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Container: $CONTAINER_NAME"
    echo -e "  Image: $IMAGE_NAME:$RUN_VERSION"
    echo -e "  Port: $API_PORT"
    echo -e "  Network: $NETWORK_NAME"
    echo -e ""
    echo -e "${BLUE}Other Commands:${NC}"
    echo -e "  • Status: ${YELLOW}docker ps --filter name=$CONTAINER_NAME${NC}"
    echo -e "  • Logs: ${YELLOW}docker logs $CONTAINER_NAME${NC}"
    echo -e "  • Stop: ${YELLOW}docker stop $CONTAINER_NAME${NC}"
    echo -e "  • Clean: ${YELLOW}./scripts/clean.sh${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Function to start the service
start_service() {
    local force_restart=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_restart=true
                shift
                ;;
            --help|-h|-help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_info "Starting Brick X Auth Service..."
    
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME:$RUN_VERSION" >/dev/null 2>&1; then
        print_error "Image $IMAGE_NAME:$RUN_VERSION not found. Please run './scripts/build.sh' first."
        exit 1
    fi
    
    # Create network if it doesn't exist
    if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
        print_info "Creating network $NETWORK_NAME..."
        docker network create "$NETWORK_NAME"
    fi
    
    # Handle existing container
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        if [ "$force_restart" = true ]; then
            print_info "Force restart: stopping existing container..."
            docker stop "$CONTAINER_NAME"
            docker rm "$CONTAINER_NAME"
        else
            print_warning "Container $CONTAINER_NAME is already running."
            print_info "Use --force to restart the container."
            exit 0
        fi
    elif docker ps -a -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_info "Removing stopped container..."
        docker rm "$CONTAINER_NAME"
    fi
    
    # Start container
    print_info "Starting container..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        --network "$NETWORK_NAME" \
        -p "$API_PORT:$API_PORT" \
        -e TZ=UTC \
        --restart unless-stopped \
        --health-cmd="wget --no-verbose --tries=1 --method=GET http://localhost:$API_PORT/health" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --health-start-period=40s \
        "$IMAGE_NAME:$RUN_VERSION"
    
    print_info "Auth service started successfully!"
    print_info "Container: $CONTAINER_NAME"
    print_info "Port: $API_PORT"
    print_info "Health check: http://localhost:$API_PORT/health"
}

# Main execution
if [[ $# -eq 0 ]]; then
    start_service
else
    start_service "$@"
fi 