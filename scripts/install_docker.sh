#!/bin/bash

# Docker Installation Script for FPGA Design Toolkit
# Supports Ubuntu/Debian and WSL environments

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if user is in docker group
check_docker_group() {
    if groups "$USER" | grep -q '\bdocker\b'; then
        return 0
    else
        return 1
    fi
}

# Function to check sudo access
check_sudo_access() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        print_error "This script requires sudo access to install Docker"
        print_info "Please run 'sudo -v' to authenticate, then run this script again"
        return 1
    fi
}

# Function to install Docker using docker.io (Ubuntu repository)
install_docker_io() {
    print_info "Installing Docker from Ubuntu repository (docker.io)..."

    # Update package list
    print_info "Updating package list..."
    if ! sudo apt-get update; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install Docker
    print_info "Installing docker.io..."
    if ! sudo apt-get install -y docker.io; then
        print_error "Failed to install docker.io"
        return 1
    fi

    # Start and enable Docker service
    print_info "Starting Docker service..."
    if ! sudo systemctl start docker; then
        print_warning "Failed to start Docker service"
        return 1
    fi

    if ! sudo systemctl enable docker; then
        print_warning "Failed to enable Docker service"
        return 1
    fi

    print_success "Docker (docker.io) installed successfully!"
    return 0
}

# Function to install Docker CE (official Docker repository)
install_docker_ce() {
    print_info "Installing Docker CE from official repository..."

    # Update package list
    print_info "Updating package list..."
    if ! sudo apt-get update; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install prerequisites
    print_info "Installing prerequisites..."
    if ! sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release; then
        print_error "Failed to install prerequisites"
        return 1
    fi

    # Add Docker's official GPG key
    print_info "Adding Docker GPG key..."
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
        print_error "Failed to add Docker GPG key"
        return 1
    fi

    # Add Docker repository
    print_info "Adding Docker repository..."
    local arch=$(dpkg --print-architecture)
    local codename=$(lsb_release -cs)
    echo "deb [arch=$arch signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package list with new repository
    print_info "Updating package list with Docker repository..."
    if ! sudo apt-get update; then
        print_error "Failed to update package list with Docker repository"
        return 1
    fi

    # Install Docker CE
    print_info "Installing Docker CE..."
    if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io; then
        print_error "Failed to install Docker CE"
        return 1
    fi

    # Start and enable Docker service
    print_info "Starting Docker service..."
    if ! sudo systemctl start docker; then
        print_warning "Failed to start Docker service"
        return 1
    fi

    if ! sudo systemctl enable docker; then
        print_warning "Failed to enable Docker service"
        return 1
    fi

    print_success "Docker CE installed successfully!"
    return 0
}

# Main Docker installation function with fallback
install_docker() {
    print_info "Installing Docker..."

    # Check sudo access first
    if ! check_sudo_access; then
        return 1
    fi

    # Try Docker CE first (more up-to-date)
    print_info "Attempting to install Docker CE (official repository)..."
    if install_docker_ce; then
        return 0
    fi

    print_warning "Docker CE installation failed, trying docker.io as fallback..."

    # Fallback to docker.io
    if install_docker_io; then
        return 0
    fi

    print_error "Both Docker installation methods failed"
    return 1
}

# Function to configure Docker for user
configure_docker() {
    print_info "Configuring Docker for user $USER..."

    # Add user to docker group
    sudo usermod -aG docker "$USER"

    print_success "User $USER added to docker group"
    print_warning "Please log out and log back in, or restart your terminal for group changes to take effect"
}

# Function to verify Docker installation
verify_docker_installation() {
    print_info "Verifying Docker installation..."

    # Check if Docker command exists
    if ! command_exists docker; then
        print_error "Docker command not found after installation"
        return 1
    fi

    # Check Docker version
    local version=$(docker --version 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_success "Docker version: $version"
    else
        print_error "Failed to get Docker version"
        return 1
    fi

    # Check Docker service status
    if command_exists systemctl; then
        if systemctl is-active --quiet docker; then
            print_success "Docker service is running"
        else
            print_warning "Docker service is not running"
            print_info "Attempting to start Docker service..."
            if sudo systemctl start docker; then
                print_success "Docker service started successfully"
            else
                print_error "Failed to start Docker service"
                return 1
            fi
        fi
    fi

    return 0
}

# Function to test Docker installation
test_docker() {
    print_info "Testing Docker functionality..."

    # First verify basic installation
    if ! verify_docker_installation; then
        return 1
    fi

    # Test Docker with hello-world container
    print_info "Running Docker hello-world test..."
    if timeout 30 docker run --rm hello-world >/dev/null 2>&1; then
        print_success "Docker is working correctly!"
        return 0
    else
        print_warning "Docker hello-world test failed"

        # Check if it's a permission issue
        if docker ps >/dev/null 2>&1; then
            print_info "Docker is accessible but hello-world test failed"
            print_info "This might be a network or image download issue"
        else
            print_info "Docker permission issue detected"
            print_info "You may need to:"
            print_info "1. Log out and log back in (to apply group changes)"
            print_info "2. Restart your terminal"
            print_info "3. Run 'newgrp docker' to refresh group membership"
        fi
        return 1
    fi
}

# Function to check Docker version
check_docker_version() {
    local version=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ ! -z "$version" ]; then
        print_info "Docker version: $version"
        return 0
    else
        return 1
    fi
}

# Function to check system compatibility
check_system_compatibility() {
    print_info "Checking system compatibility..."

    local errors=0

    # Check if we're on a supported Linux distribution
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$ID" in
            ubuntu|debian)
                print_success "Supported OS detected: $PRETTY_NAME"
                ;;
            *)
                if grep -qi microsoft /proc/version; then
                    print_success "WSL environment detected with $PRETTY_NAME"
                else
                    print_warning "Untested OS: $PRETTY_NAME (Ubuntu/Debian recommended)"
                    ((errors++))
                fi
                ;;
        esac
    else
        print_error "Cannot determine OS distribution"
        ((errors++))
    fi

    # Check architecture
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            print_success "Supported architecture: $arch"
            ;;
        aarch64|arm64)
            print_success "Supported architecture: $arch"
            ;;
        *)
            print_warning "Untested architecture: $arch"
            ((errors++))
            ;;
    esac

    # Check for systemd (required for service management)
    if command_exists systemctl; then
        print_success "systemd detected"
    else
        print_warning "systemd not found - service management may not work properly"
        ((errors++))
    fi

    # Check available disk space (minimum 2GB recommended)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local space_gb=$((available_space / 1024 / 1024))
    if [ "$space_gb" -gt 2 ]; then
        print_success "Sufficient disk space available: ${space_gb}GB"
    else
        print_warning "Low disk space: ${space_gb}GB (2GB+ recommended)"
        ((errors++))
    fi

    # Check for required commands
    local required_commands="sudo apt-get curl"
    for cmd in $required_commands; do
        if command_exists "$cmd"; then
            print_success "Required command found: $cmd"
        else
            print_error "Required command missing: $cmd"
            ((errors++))
        fi
    done

    # Check if running as root (should not be)
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        ((errors++))
    else
        print_success "Running as non-root user: $USER"
    fi

    if [ "$errors" -eq 0 ]; then
        print_success "System compatibility check passed!"
        return 0
    else
        print_warning "System compatibility check completed with $errors warnings/errors"
        return 1
    fi
}

# Function to cleanup Docker installation
cleanup_docker() {
    print_info "Starting Docker cleanup..."

    local cleanup_errors=0

    # Stop Docker service
    if command_exists systemctl; then
        print_info "Stopping Docker service..."
        if sudo systemctl stop docker 2>/dev/null; then
            print_success "Docker service stopped"
        else
            print_warning "Failed to stop Docker service (may not be running)"
        fi

        print_info "Disabling Docker service..."
        if sudo systemctl disable docker 2>/dev/null; then
            print_success "Docker service disabled"
        else
            print_warning "Failed to disable Docker service"
        fi
    fi

    # Remove user from docker group
    if check_docker_group; then
        print_info "Removing user $USER from docker group..."
        if sudo gpasswd -d "$USER" docker 2>/dev/null; then
            print_success "User $USER removed from docker group"
        else
            print_warning "Failed to remove user from docker group"
            ((cleanup_errors++))
        fi
    else
        print_info "User $USER not in docker group (nothing to remove)"
    fi

    # Remove Docker packages
    print_info "Removing Docker packages..."
    local docker_packages="docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc docker-ce docker-ce-cli docker-ce-rootless-extras docker-buildx-plugin docker-compose-plugin"

    for package in $docker_packages; do
        if dpkg -l | grep -q "^ii.*$package "; then
            print_info "Removing package: $package"
            if sudo apt-get remove --purge -y "$package" 2>/dev/null; then
                print_success "Removed package: $package"
            else
                print_warning "Failed to remove package: $package"
                ((cleanup_errors++))
            fi
        fi
    done

    # Remove Docker directories and files
    print_info "Removing Docker directories and files..."
    local docker_dirs="/var/lib/docker /var/lib/containerd /etc/docker /var/run/docker.sock"

    for dir in $docker_dirs; do
        if [ -e "$dir" ]; then
            print_info "Removing: $dir"
            if sudo rm -rf "$dir" 2>/dev/null; then
                print_success "Removed: $dir"
            else
                print_warning "Failed to remove: $dir"
                ((cleanup_errors++))
            fi
        fi
    done

    # Remove Docker repository files and GPG keys
    print_info "Removing Docker repository configuration..."
    local repo_files="/etc/apt/sources.list.d/docker.list /usr/share/keyrings/docker-archive-keyring.gpg /etc/apt/keyrings/docker.asc"

    for file in $repo_files; do
        if [ -e "$file" ]; then
            print_info "Removing: $file"
            if sudo rm -f "$file" 2>/dev/null; then
                print_success "Removed: $file"
            else
                print_warning "Failed to remove: $file"
                ((cleanup_errors++))
            fi
        fi
    done

    # Remove systemd service files if they exist
    print_info "Removing Docker systemd service files..."
    local systemd_files="/etc/systemd/system/docker.service /etc/systemd/system/docker.socket /lib/systemd/system/docker.service /lib/systemd/system/docker.socket"

    for file in $systemd_files; do
        if [ -e "$file" ]; then
            print_info "Removing: $file"
            if sudo rm -f "$file" 2>/dev/null; then
                print_success "Removed: $file"
            else
                print_warning "Failed to remove: $file"
                ((cleanup_errors++))
            fi
        fi
    done

    # Reload systemd after removing service files
    if command_exists systemctl; then
        print_info "Reloading systemd daemon..."
        sudo systemctl daemon-reload 2>/dev/null || true
    fi

    # Remove user-specific Docker directories
    print_info "Removing user Docker directories..."
    local user_docker_dirs="$HOME/.docker"

    for dir in $user_docker_dirs; do
        if [ -e "$dir" ]; then
            print_info "Removing: $dir"
            if rm -rf "$dir" 2>/dev/null; then
                print_success "Removed: $dir"
            else
                print_warning "Failed to remove: $dir"
                ((cleanup_errors++))
            fi
        fi
    done

    # Clean up apt cache
    print_info "Cleaning apt cache..."
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo apt-get autoclean 2>/dev/null || true

    # Check if Docker is completely removed
    if command_exists docker; then
        print_warning "Docker command still exists after cleanup"
        ((cleanup_errors++))
    else
        print_success "Docker command removed successfully"
    fi

    if [ "$cleanup_errors" -eq 0 ]; then
        print_success "Docker cleanup completed successfully!"
        print_info "You may need to log out and log back in for group changes to take effect"
        return 0
    else
        print_warning "Docker cleanup completed with $cleanup_errors errors"
        print_info "Some components may require manual removal"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Docker Installation Script for FPGA Design Toolkit"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --cleanup    Remove Docker completely from the system"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "Default behavior (no options): Install and configure Docker"
    echo ""
    echo "INSTALLATION PROCESS:"
    echo "  1. System compatibility check"
    echo "  2. Try Docker CE (official repository) - latest version"
    echo "  3. Fallback to docker.io (Ubuntu repository) if CE fails"
    echo "  4. Configure user permissions (add to docker group)"
    echo "  5. Verify installation and test functionality"
    echo ""
    echo "Examples:"
    echo "  $0           Install Docker with system check and verification"
    echo "  $0 --cleanup Remove Docker completely from system"
    echo ""
    echo "REQUIREMENTS:"
    echo "  - Ubuntu/Debian or WSL environment"
    echo "  - sudo access"
    echo "  - Internet connection for package downloads"
    echo "  - Minimum 2GB free disk space"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cleanup)
                CLEANUP_MODE=true
                shift
                ;;
            --help|-h)
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
}

# Function to show Docker introduction for new users
show_docker_introduction() {
    echo ""
    echo "========================================"
    echo "Docker & Containerization Introduction"
    echo "========================================"

    print_info "New to Docker? Here's what you need to know:"
    echo ""

    echo "🐳 WHAT IS DOCKER?"
    echo "   Docker is a containerization platform that packages applications"
    echo "   and their dependencies into lightweight, portable containers."
    echo ""

    echo "📦 WHAT ARE CONTAINERS?"
    echo "   Think of containers as lightweight virtual machines that:"
    echo "   • Run applications in isolated environments"
    echo "   • Share the host OS kernel (more efficient than VMs)"
    echo "   • Include everything needed to run: code, libraries, dependencies"
    echo "   • Are portable across different systems"
    echo ""

    echo "🚀 WHY USE DOCKER FOR FPGA DEVELOPMENT?"
    echo "   • Consistent development environment across different machines"
    echo "   • No conflicts between different tool versions"
    echo "   • Easy sharing of complete development setups"
    echo "   • Simplified installation and setup process"
    echo ""

    echo "💡 ESSENTIAL DOCKER COMMANDS TO GET STARTED:"
    echo ""
    echo "   # List running containers"
    echo "   docker ps"
    echo ""
    echo "   # List all containers (including stopped)"
    echo "   docker ps -a"
    echo ""
    echo "   # List available images"
    echo "   docker images"
    echo ""
    echo "   # Run a container interactively"
    echo "   docker run -it ubuntu:latest /bin/bash"
    echo ""
    echo "   # Stop a running container"
    echo "   docker stop <container_id>"
    echo ""
    echo "   # Remove a container"
    echo "   docker rm <container_id>"
    echo ""
    echo "   # Remove an image"
    echo "   docker rmi <image_name>"
    echo ""
    echo "   # View container logs"
    echo "   docker logs <container_id>"
    echo ""
    echo "   # Execute command in running container"
    echo "   docker exec -it <container_id> /bin/bash"
    echo ""

    echo "📚 LEARN MORE:"
    echo "   • Official Docker Tutorial: https://docs.docker.com/get-started/"
    echo "   • Docker for Beginners: https://docker-curriculum.com/"
    echo "   • Interactive Tutorial: https://www.katacoda.com/courses/docker"
    echo ""

    echo "🔧 NEXT STEPS FOR FPGA DEVELOPMENT:"
    echo "   After restarting your terminal, you can:"
    echo "   1. Test Docker: docker run hello-world"
    echo "   2. Use ./install_quartus_docker.sh for Quartus in Docker"
    echo "   3. Run FPGA tools in isolated, reproducible environments"
    echo ""

    print_info "Remember: After installation, restart your terminal for Docker to work properly!"
}

# Main installation logic
main() {
    echo "========================================"
    echo "Docker Installation for FPGA Toolkit"
    echo "========================================"

    # Check system compatibility first
    if ! check_system_compatibility; then
        print_warning "System compatibility issues detected. Proceeding anyway..."
        echo ""
    fi

    # Handle cleanup mode
    if [ "$CLEANUP_MODE" = true ]; then
        echo ""
        print_info "Running in cleanup mode..."
        cleanup_docker
        exit $?
    fi

    # Check if Docker is already installed
    if command_exists docker; then
        print_info "Docker is already installed"
        check_docker_version

        # Check if user is in docker group
        if check_docker_group; then
            print_success "User $USER is already in docker group"

            # Test Docker functionality
            if test_docker; then
                print_success "Docker is fully configured and working!"
                exit 0
            else
                print_warning "Docker is installed but not working properly"
                print_info "This might be because you need to restart your terminal"
                exit 1
            fi
        else
            print_warning "User $USER is not in docker group"
            configure_docker
            print_info "Please restart your terminal and run this script again to test Docker"
            exit 0
        fi
    else
        print_info "Docker not found. Installing Docker..."

        # Check if we're on a supported system
        if ! command_exists apt-get; then
            print_error "This script requires apt-get (Ubuntu/Debian/WSL)"
            exit 1
        fi

        # Install Docker
        install_docker

        # Configure user permissions
        configure_docker

        print_success "Docker installation completed!"
        print_info "Please restart your terminal and run this script again to test Docker"

        # Show Docker introduction for new users
        show_docker_introduction
    fi
}

# Initialize variables
CLEANUP_MODE=false

# Parse arguments and run main function
parse_arguments "$@"
main