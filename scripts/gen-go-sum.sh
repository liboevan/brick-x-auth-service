#!/bin/bash
set -e

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/config.sh"

print_header "Generate go.sum"

# Enter brick-x-auth-service directory
cd "$SCRIPT_DIR/.."

print_info "Using Docker to generate go.sum..."

docker run --rm -v "$PWD":/go/src/app -w /go/src/app golang:1.20-alpine \
    sh -c "go mod tidy && chown $(id -u):$(id -g) go.sum && echo 'Only go.sum updated, no build artifacts generated'"

print_info "go.sum generated (or updated)!" 