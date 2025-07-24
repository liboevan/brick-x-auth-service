#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Container and image configuration
CONTAINER_NAME="brick-x-auth"
IMAGE_NAME="brick-x-auth"
DEFAULT_VERSION="latest"

# Function to show help
show_help() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Brick X Auth Service - Clean Script${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e ""
    echo -e "${GREEN}Purpose:${NC}"
    echo -e "  Clean up containers and images for Brick X Auth Service"
    echo -e ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  $0 [options] [version]"
    echo -e ""
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${YELLOW}--container${NC}  - Clean container only"
    echo -e "  ${YELLOW}--image${NC}      - Clean image only"
    echo -e "  ${YELLOW}--all${NC}        - Clean both container and image (default)"
    echo -e "  ${YELLOW}--force${NC}      - Force cleanup without confirmation"
    echo -e "  ${YELLOW}--help${NC}       - Show this help"
    echo -e ""
    echo -e "${GREEN}Parameters:${NC}"
    echo -e "  ${YELLOW}version${NC}      - Image version to clean (default: latest)"
    echo -e ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0                    # Clean container and latest image"
    echo -e "  $0 --container        # Clean container only"
    echo -e "  $0 --image v1.0.0     # Clean specific image version"
    echo -e "  $0 --all --force      # Force clean everything"
    echo -e ""
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Container: $CONTAINER_NAME"
    echo -e "  Image: $IMAGE_NAME"
    echo -e "${BLUE}======================================${NC}"
}

# Function to clean container
clean_container() {
    print_status "Cleaning container: $CONTAINER_NAME"
    
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_status "Stopping running container..."
        docker stop "$CONTAINER_NAME"
    fi
    
    if docker ps -a -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_status "Removing container..."
        docker rm "$CONTAINER_NAME"
        print_status "Container cleaned successfully"
    else
        print_warning "Container $CONTAINER_NAME not found"
    fi
}

# Function to clean image
clean_image() {
    local version="$1"
    local full_image_name="$IMAGE_NAME:$version"
    
    print_status "Cleaning image: $full_image_name"
    
    if docker image inspect "$full_image_name" >/dev/null 2>&1; then
        print_status "Removing image..."
        docker rmi "$full_image_name"
        print_status "Image cleaned successfully"
    else
        print_warning "Image $full_image_name not found"
    fi
}

# Function to clean all images
clean_all_images() {
    print_status "Cleaning all images for: $IMAGE_NAME"
    
    local images=$(docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}")
    if [ -n "$images" ]; then
        echo "$images" | while read -r image; do
            print_status "Removing image: $image"
            docker rmi "$image" 2>/dev/null || print_warning "Failed to remove $image"
        done
        print_status "All images cleaned successfully"
    else
        print_warning "No images found for $IMAGE_NAME"
    fi
}

# Function to confirm cleanup
confirm_cleanup() {
    local action="$1"
    local version="$2"
    
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}Cleanup Confirmation${NC}"
    echo -e "${YELLOW}======================================${NC}"
    echo -e "Action: $action"
    if [ -n "$version" ]; then
        echo -e "Version: $version"
    fi
    echo -e "Container: $CONTAINER_NAME"
    echo -e "Image: $IMAGE_NAME"
    echo -e ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Main cleanup function
main_cleanup() {
    local clean_container_flag=false
    local clean_image_flag=false
    local force_flag=false
    local version="$DEFAULT_VERSION"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --container)
                clean_container_flag=true
                shift
                ;;
            --image)
                clean_image_flag=true
                shift
                ;;
            --all)
                clean_container_flag=true
                clean_image_flag=true
                shift
                ;;
            --force)
                force_flag=true
                shift
                ;;
            --help|-h|-help)
                show_help
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # Assume this is the version parameter
                version="$1"
                shift
                ;;
        esac
    done
    
    # Default to clean all if no specific flags
    if [ "$clean_container_flag" = false ] && [ "$clean_image_flag" = false ]; then
        clean_container_flag=true
        clean_image_flag=true
    fi
    
    # Build action description
    local action=""
    if [ "$clean_container_flag" = true ] && [ "$clean_image_flag" = true ]; then
        action="Clean container and image"
    elif [ "$clean_container_flag" = true ]; then
        action="Clean container only"
    elif [ "$clean_image_flag" = true ]; then
        action="Clean image only"
    fi
    
    # Confirm unless force flag is used
    if [ "$force_flag" = false ]; then
        confirm_cleanup "$action" "$version"
    fi
    
    # Execute cleanup
    if [ "$clean_container_flag" = true ]; then
        clean_container
    fi
    
    if [ "$clean_image_flag" = true ]; then
        if [ "$version" = "all" ]; then
            clean_all_images
        else
            clean_image "$version"
        fi
    fi
    
    print_status "Cleanup completed successfully!"
}

# Main execution
if [[ $# -eq 0 ]]; then
    main_cleanup
else
    main_cleanup "$@"
fi