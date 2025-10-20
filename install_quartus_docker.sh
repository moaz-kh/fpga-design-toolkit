#!/bin/bash

# Quartus Docker Setup Script for FPGA Design Toolkit
# Downloads and configures Intel Quartus Prime Lite containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Quartus Docker image configuration
QUARTUS_IMAGE="raetro/quartus:21.1"
QUARTUS_VERSION="21.1"

# Global flag to track if Docker was just installed in this session
DOCKER_JUST_INSTALLED=false

# Helper function to run docker commands with sudo if needed
docker_cmd() {
    if [ "$DOCKER_JUST_INSTALLED" = true ]; then
        sudo docker "$@"
    else
        docker "$@"
    fi
}

# Function to check if Docker is available
# Updated Oct 2025: Automatically installs Docker if not found and continues script
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed!"

        # Check if install_docker.sh exists
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local docker_installer="$script_dir/install_docker.sh"

        if [ -f "$docker_installer" ]; then
            print_info "Found Docker installation script: install_docker.sh"
            echo ""
            print_info "Running Docker installation automatically..."
            echo ""

            # Run install_docker.sh
            if bash "$docker_installer"; then
                print_success "Docker installation completed!"
                echo ""
                DOCKER_JUST_INSTALLED=true

                print_info "Docker installed successfully - continuing with Quartus installation..."
                print_warning "Note: You may need to restart your terminal for future Docker commands"
                echo ""
            else
                print_error "Docker installation failed"
                print_info "Please try installing Docker manually"
                exit 1
            fi
        else
            print_error "install_docker.sh not found in $script_dir"
            print_info "Please install Docker manually or ensure install_docker.sh is available"
            exit 1
        fi
    fi

    # Test Docker access
    if ! docker info >/dev/null 2>&1; then
        # Docker command exists but info fails - likely permission issue

        if [ "$DOCKER_JUST_INSTALLED" = true ]; then
            # Docker was just installed, group membership not active yet
            print_warning "Docker group membership not active in current session"
            print_info "Will use sudo for Docker commands in this script"
            echo ""

            # Test sudo docker access
            if sudo docker info >/dev/null 2>&1; then
                print_success "Docker is working with sudo"
                return 0
            else
                print_error "Docker is not running properly even with sudo"
                print_info "Please check Docker service: sudo systemctl status docker"
                exit 1
            fi
        else
            # Docker was already installed but not accessible
            print_error "Docker is not running or you don't have permission to use it"
            print_info "Please make sure:"
            print_info "1. Docker service is running: sudo systemctl status docker"
            print_info "2. You are in the docker group: groups $USER"
            print_info "3. You have restarted your terminal after adding to docker group"
            echo ""
            print_info "Quick fix: Try restarting Docker service"
            print_info "  sudo systemctl restart docker"
            exit 1
        fi
    fi

    print_success "Docker is available and working"
}

# Function to check available disk space
check_disk_space() {
    local required_space_gb=3
    local available_space_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')

    if [ "$available_space_gb" -lt "$required_space_gb" ]; then
        print_error "Insufficient disk space!"
        print_info "Required: ${required_space_gb}GB, Available: ${available_space_gb}GB"
        exit 1
    fi

    print_info "Disk space check passed (${available_space_gb}GB available)"
}

# Function to pull Quartus Docker image
pull_quartus_image() {
    print_info "Pulling Quartus $QUARTUS_VERSION Docker image: $QUARTUS_IMAGE"
    print_warning "This may take several minutes (image size ~2GB)..."

    if docker_cmd pull "$QUARTUS_IMAGE"; then
        print_success "Successfully pulled $QUARTUS_IMAGE"
        return 0
    else
        print_error "Failed to pull $QUARTUS_IMAGE"
        return 1
    fi
}

# Function to test Quartus container
test_quartus_container() {
    print_info "Testing Quartus $QUARTUS_VERSION container..."

    # Test basic quartus_sh command
    if docker_cmd run --rm "$QUARTUS_IMAGE" quartus_sh --version >/dev/null 2>&1; then
        print_success "Quartus $QUARTUS_VERSION container is working!"

        # Get and display version info
        local version_info=$(docker_cmd run --rm "$QUARTUS_IMAGE" quartus_sh --version 2>/dev/null | head -1)
        print_info "Version: $version_info"
        return 0
    else
        print_error "Quartus $QUARTUS_VERSION container test failed!"
        return 1
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help       Show this help message"
    echo "  -t, --test       Test existing container"
    echo "  --cleanup        Remove Quartus Docker image and containers"
    echo ""
    echo "This script installs Quartus Prime Lite $QUARTUS_VERSION Docker image (FREE, no license required)"
    echo ""
    echo "Note: This script ONLY installs the Docker image. Wrapper scripts are"
    echo "      maintained separately in quartus_env/ directory."
    echo ""
    echo "Examples:"
    echo "  $0               # Install Quartus $QUARTUS_VERSION Docker image"
    echo "  $0 --test        # Test existing container"
    echo "  $0 --cleanup     # Remove Quartus Docker image"
}

# Function to test installed container
test_installed_container() {
    print_info "Testing installed Quartus container..."

    if docker image ls "$QUARTUS_IMAGE" --format "table" | grep -q "$QUARTUS_IMAGE"; then
        if test_quartus_container; then
            print_success "Quartus $QUARTUS_VERSION container is working correctly!"
            return 0
        else
            print_error "Quartus $QUARTUS_VERSION container test failed!"
            return 1
        fi
    else
        print_warning "Quartus container not found. Run without --test to install."
        return 1
    fi
}

# Function to cleanup Quartus installation
cleanup_quartus() {
    print_info "Starting Quartus cleanup..."

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local cleanup_errors=0

    # Stop and remove any running Quartus containers
    print_info "Stopping and removing Quartus containers..."
    local running_containers=$(docker_cmd ps -q --filter ancestor="$QUARTUS_IMAGE" 2>/dev/null)
    if [ ! -z "$running_containers" ]; then
        print_info "Stopping running Quartus containers..."
        if docker_cmd stop $running_containers 2>/dev/null; then
            print_success "Stopped running containers"
        else
            print_warning "Failed to stop some containers"
            ((cleanup_errors++))
        fi
    fi

    # Remove all containers based on the Quartus image
    local all_containers=$(docker_cmd ps -aq --filter ancestor="$QUARTUS_IMAGE" 2>/dev/null)
    if [ ! -z "$all_containers" ]; then
        print_info "Removing Quartus containers..."
        if docker_cmd rm $all_containers 2>/dev/null; then
            print_success "Removed Quartus containers"
        else
            print_warning "Failed to remove some containers"
            ((cleanup_errors++))
        fi
    fi

    # Remove the Quartus Docker image
    print_info "Removing Quartus Docker image..."
    if docker_cmd image ls "$QUARTUS_IMAGE" --format "table" | grep -q "$QUARTUS_IMAGE"; then
        if docker_cmd rmi "$QUARTUS_IMAGE" 2>/dev/null; then
            print_success "Removed Quartus image: $QUARTUS_IMAGE"
        else
            print_warning "Failed to remove Quartus image: $QUARTUS_IMAGE"
            print_info "This may be because containers are still using the image"
            ((cleanup_errors++))
        fi
    else
        print_info "Quartus image not found (already removed)"
    fi

    # Clean up Docker system (remove dangling images, containers, networks)
    # Note: Custom wrapper scripts in quartus_env/ are not touched by cleanup
    print_info "Cleaning up Docker system..."
    docker_cmd system prune -f >/dev/null 2>&1 || true

    # Final status
    if [ "$cleanup_errors" -eq 0 ]; then
        print_success "Quartus cleanup completed successfully!"
        print_info "Quartus Docker containers and images have been removed"
        print_info "Note: Custom wrapper scripts in quartus_env/ are preserved"
        return 0
    else
        print_warning "Quartus cleanup completed with $cleanup_errors errors"
        print_info "Some components may require manual removal"
        return 1
    fi
}

# Main function
main() {
    local test_only=false
    local cleanup_mode=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -t|--test)
                test_only=true
                shift
                ;;
            --cleanup)
                cleanup_mode=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    echo "================================================"
    echo "Quartus Docker Setup for FPGA Design Toolkit"
    echo "================================================"

    # Handle cleanup mode
    if $cleanup_mode; then
        echo "Running in cleanup mode..."
        echo ""

        # Check Docker availability for cleanup
        if ! command -v docker >/dev/null 2>&1; then
            print_warning "Docker not found, but will continue with script cleanup"
        fi

        cleanup_quartus
        exit $?
    fi

    echo "Installing Quartus Prime Lite $QUARTUS_VERSION (FREE)"

    # Check Docker availability
    check_docker

    # Handle test option
    if $test_only; then
        test_installed_container
        exit $?
    fi

    # Check disk space
    check_disk_space

    # Install Quartus container
    print_info "Installing Quartus $QUARTUS_VERSION..."

    if pull_quartus_image; then
        if test_quartus_container; then
            print_success "Quartus $QUARTUS_VERSION Docker image installed successfully!"
            print_info ""
            print_info "The Quartus Docker image (raetro/quartus:21.1) is now available."
            print_info "Use your custom wrapper scripts in quartus_env/ to run Quartus commands."
            print_info ""
            print_info "Example commands (from quartus_env/):"
            print_info "  ./quartus-synth project    # Synthesize"
            print_info "  ./quartus-fit project      # Place & Route"
            print_info "  ./quartus-asm project      # Generate bitstreams"
            print_info "  ./quartus-prog file.pof    # Program FPGA"
        else
            print_error "Quartus container installation failed"
            exit 1
        fi
    else
        print_error "Failed to download Quartus container"
        exit 1
    fi
}

# Run main function
main "$@"