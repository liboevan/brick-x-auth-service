#!/bin/bash

# Shared Configuration for Brick X Auth Service Scripts
# This file contains common variables and utility functions

# Project Configuration
PROJECT_NAME="brick-x-auth-service"
IMAGE_NAME="brick-x-auth"
CONTAINER_NAME="brick-x-auth"
API_PORT="17101"
NETWORK_NAME="brick-x-network"
DEFAULT_VERSION="0.1.0-dev"  # Default version for build
RUN_VERSION="0.1.0-dev"      # Version for start/stop operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions for colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}======================================"
    echo -e "Brick X Auth Service - $1"
    echo -e "======================================${NC}"
} 