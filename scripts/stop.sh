#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Function to show help
show_help() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Brick X Auth Service - Stop Script${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e ""
    echo -e "${GREEN}Purpose:${NC}"
    echo -e "  Stop the auth service container"
    echo -e ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  $0 [options]"
    echo -e ""
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${YELLOW}--remove${NC}  - Remove container after stopping"
    echo -e "  ${YELLOW}--help${NC}     - Show this help"
    echo -e ""
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Container: $CONTAINER_NAME"
    echo -e ""
    echo -e "${BLUE}Other Commands:${NC}"
    echo -e "  • Start: ${YELLOW}./scripts/start.sh${NC}"
    echo -e "  • Status: ${YELLOW}docker ps --filter name=$CONTAINER_NAME${NC}"
    echo -e "  • Clean: ${YELLOW}./scripts/clean.sh${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Function to stop the service
stop_service() {
    local remove_container=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --remove)
                remove_container=true
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
    
    print_info "Stopping Brick X Auth Service..."
    
    # Check if container is running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_info "Stopping container..."
        docker stop "$CONTAINER_NAME"
        print_info "Container stopped successfully"
        
        if [ "$remove_container" = true ]; then
            print_info "Removing container..."
            docker rm "$CONTAINER_NAME"
            print_info "Container removed successfully"
        fi
    else
        print_warning "Container $CONTAINER_NAME is not running."
        
        # Check if container exists but stopped
        if docker ps -a -q -f name="$CONTAINER_NAME" | grep -q .; then
            print_info "Container exists but stopped"
            if [ "$remove_container" = true ]; then
                print_info "Removing stopped container..."
                docker rm "$CONTAINER_NAME"
                print_info "Container removed successfully"
            fi
        else
            print_warning "Container $CONTAINER_NAME does not exist."
        fi
    fi
}

# Main execution
if [[ $# -eq 0 ]]; then
    stop_service
else
    stop_service "$@"
fi 