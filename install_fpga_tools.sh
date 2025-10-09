#!/bin/bash
# Simple FPGA Design Tools Installer
# Focus: OSS CAD Suite (comprehensive toolchain)
# Target: WSL2 Ubuntu 22.04+
# Updated Oct 2025: Auto-fetch and auto-download latest OSS CAD Suite version
# Updated Oct 2025: Unified installer with Docker and Quartus support
# Usage: ./install_fpga_tools.sh [--mode MODE] [--cleanup] [--reinstall] [--version YYYY-MM-DD]

set -euo pipefail

# Configuration
readonly WORKSPACE_DIR="$HOME/fpga_workspace"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OSS CAD Suite version configuration
# Updated Oct 2025: Auto-fetch latest version from GitHub instead of hardcoded date
# User can override with --version flag (e.g., --version 2023-11-02)
OSS_CAD_VERSION=""  # Will be auto-detected or set by user
OSS_CAD_FILE=""
OSS_CAD_URL=""

# Installation mode
# oss: Open-source FPGA tools only (default)
# docker: Docker engine only
# quartus: Docker + Quartus container
# all: Everything (OSS + Docker + Quartus)
INSTALL_MODE=""

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --mode <mode>      Installation mode (if not provided, interactive menu shown)"
    echo "                     oss      - Open-source FPGA tools only (OSS CAD Suite, Icarus, GTKWave)"
    echo "                     docker   - Docker engine only"
    echo "                     quartus  - Docker + Quartus Prime container"
    echo "                     all      - Everything (OSS tools + Docker + Quartus)"
    echo "  --cleanup          Remove installed components (interactive menu if not specified)"
    echo "  --cleanup-oss      Remove only OSS CAD Suite and related tools"
    echo "  --cleanup-docker   Remove only Docker engine"
    echo "  --cleanup-quartus  Remove only Quartus Docker containers"
    echo "  --reinstall        Clean up and reinstall (respects --mode)"
    echo "  --version <date>   Install specific OSS CAD Suite version (format: YYYY-MM-DD)"
    echo "                     Example: --version 2023-11-02"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Interactive menu to choose installation mode"
    echo "  $0 --mode=oss               # Install open-source FPGA tools only"
    echo "  $0 --mode=quartus           # Install Docker + Quartus (for Intel FPGA)"
    echo "  $0 --mode=all               # Install everything"
    echo "  $0 --cleanup                # Interactive cleanup menu"
    echo "  $0 --cleanup-docker         # Remove Docker only"
}

# Parse command line arguments
CLEANUP_MODE=false
CLEANUP_OSS=false
CLEANUP_DOCKER=false
CLEANUP_QUARTUS=false
REINSTALL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode=*)
            INSTALL_MODE="${1#*=}"
            shift
            ;;
        --mode)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                log_error "Option --mode requires an argument (oss|docker|quartus|all)"
                show_usage
                exit 1
            fi
            INSTALL_MODE="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP_MODE=true
            shift
            ;;
        --cleanup-oss)
            CLEANUP_MODE=true
            CLEANUP_OSS=true
            shift
            ;;
        --cleanup-docker)
            CLEANUP_MODE=true
            CLEANUP_DOCKER=true
            shift
            ;;
        --cleanup-quartus)
            CLEANUP_MODE=true
            CLEANUP_QUARTUS=true
            shift
            ;;
        --reinstall)
            REINSTALL_MODE=true
            shift
            ;;
        --version)
            # User-specified OSS CAD Suite version (format: YYYY-MM-DD)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                log_error "Option --version requires a date argument (format: YYYY-MM-DD)"
                show_usage
                exit 1
            fi
            OSS_CAD_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate INSTALL_MODE if provided
if [[ -n "$INSTALL_MODE" ]]; then
    case "$INSTALL_MODE" in
        oss|docker|quartus|all)
            # Valid mode
            ;;
        *)
            log_error "Invalid mode: $INSTALL_MODE"
            log_error "Valid modes: oss, docker, quartus, all"
            show_usage
            exit 1
            ;;
    esac
fi

if [ "$CLEANUP_MODE" = true ]; then
    echo "FPGA Tools Cleanup"
    echo "========================================"
elif [ "$REINSTALL_MODE" = true ]; then
    echo "FPGA Tools Reinstaller"
    echo "========================================"
else
    echo "FPGA Tools Installer"
    echo "========================================"
fi

# Fetch latest OSS CAD Suite version from GitHub
# Updated Oct 2025: Automatically detect latest release instead of hardcoded version
# Returns: Latest release tag (format: YYYY-MM-DD) or exits on error
# Note: Log messages go to stderr to avoid polluting function return value
fetch_latest_oss_cad_version() {
    log_info "Fetching latest OSS CAD Suite version from GitHub..." >&2

    # Query GitHub API for latest release
    local api_url="https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest"
    local latest_tag=""

    # Try using curl first (most common)
    if command -v curl &> /dev/null; then
        latest_tag=$(curl -s "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    elif command -v wget &> /dev/null; then
        latest_tag=$(wget -qO- "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    else
        log_error "Neither curl nor wget found - cannot fetch latest version" >&2
        log_error "Please install curl or wget, or specify version manually with --version" >&2
        exit 1
    fi

    # Validate we got a version (format: YYYY-MM-DD)
    if [[ -z "$latest_tag" ]]; then
        log_error "Failed to fetch latest OSS CAD Suite version from GitHub" >&2
        log_error "Please check your internet connection or specify version manually with --version" >&2
        exit 1
    fi

    # Validate format (YYYY-MM-DD)
    if [[ ! "$latest_tag" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "Invalid version format from GitHub: $latest_tag" >&2
        log_error "Expected format: YYYY-MM-DD" >&2
        exit 1
    fi

    log_info "Latest OSS CAD Suite version: $latest_tag" >&2
    echo "$latest_tag"
}

# Set OSS CAD Suite version and construct download URLs
# Updated Oct 2025: Dynamic version resolution
# If user didn't specify --version, auto-fetch latest from GitHub
setup_oss_cad_version() {
    # If version not set by user, fetch latest from GitHub
    if [[ -z "$OSS_CAD_VERSION" ]]; then
        OSS_CAD_VERSION=$(fetch_latest_oss_cad_version)
    else
        log_info "Using user-specified OSS CAD Suite version: $OSS_CAD_VERSION"
    fi

    # Convert YYYY-MM-DD to YYYYMMDD for filename
    local version_compact="${OSS_CAD_VERSION//-/}"

    # Construct filename and download URL
    OSS_CAD_FILE="oss-cad-suite-linux-x64-${version_compact}.tgz"
    OSS_CAD_URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_CAD_VERSION}/${OSS_CAD_FILE}"

    log_info "Download URL: $OSS_CAD_URL"
}

# Basic checks
check_wsl2() {
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        log_error "This script requires WSL2"
        exit 1
    fi
    log_info "WSL2 environment detected: $WSL_DISTRO_NAME"
}

# Check WSL version and offer update if needed
check_and_update_wsl() {
    log_info "Checking WSL version..."
    
    # Get current WSL version from Windows host
    local wsl_version=""
    if command -v wsl.exe &> /dev/null; then
        wsl_version=$(wsl.exe --version 2>/dev/null | grep -E "WSL version:" | cut -d: -f2 | tr -d ' ' || echo "")
    fi
    
    if [[ -z "$wsl_version" ]]; then
        log_warn "Could not determine WSL version - continuing with installation"
        return 0
    fi
    
    log_info "Current WSL version: $wsl_version"
    
    # Check if WSL update is available (this is a simplified check)
    # In practice, WSL updates are managed by Windows Update
    local update_available=false
    
    # Check if wsl --update command is available (indicates newer WSL)
    if wsl.exe --help 2>/dev/null | grep -q "\--update"; then
        log_info "WSL update command available - checking for updates..."
        
        echo ""
        echo "========================================"
        echo "WSL Update Check"
        echo "========================================"
        echo ""
        echo "WSL can be updated to the latest version for better performance"
        echo "and compatibility with FPGA development tools."
        echo ""
        echo "This will:"
        echo "- Update WSL to the latest version"
        echo "- Not affect your current Linux distribution"
        echo "- Not affect your files or installed programs"
        echo "- Improve overall WSL performance and stability"
        echo ""
        
        read -p "Would you like to update WSL to the latest version? [y/N]: " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_wsl_safely
        else
            log_info "Skipping WSL update - continuing with FPGA tools installation"
        fi
    else
        log_warn "WSL update command not available - you may have an older WSL version"
        log_warn "Consider updating WSL manually via Windows Store or Windows Update"
    fi
}

# Safely update WSL
update_wsl_safely() {
    log_info "Updating WSL..."
    
    # Create a backup note about current state
    echo "WSL update initiated at $(date)" >> "$HOME/.wsl_update_log" 2>/dev/null || true
    
    # Try to update WSL from Windows side
    if wsl.exe --update 2>/dev/null; then
        log_info "WSL updated successfully!"
        log_info "The update will take effect after restarting WSL"
        
        echo ""
        echo "========================================"
        echo "WSL Update Complete"
        echo "========================================"
        echo ""
        echo "WSL has been updated. The changes will take effect after"
        echo "restarting your WSL session."
        echo ""
        echo "You can:"
        echo "1. Continue with FPGA tools installation (recommended)"
        echo "2. Restart WSL now and re-run this script"
        echo ""
        
        read -p "Continue with installation? [Y/n]: " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Installation paused. Please restart WSL and re-run this script."
            echo ""
            echo "To restart WSL:"
            echo "1. Close all WSL terminals"
            echo "2. From Windows Command Prompt or PowerShell, run:"
            echo "   wsl --shutdown"
            echo "3. Re-open your WSL terminal"
            echo "4. Re-run this script: ./install_fpga_tools.sh"
            exit 0
        fi
    else
        log_warn "WSL update failed or no update available"
        log_warn "Continuing with current WSL version"
        
        # Check if we need to recommend manual update
        if [[ "$wsl_version" < "1.0" ]]; then
            log_warn "Your WSL version may be quite old"
            log_warn "Consider updating via Windows Store or Windows Update"
        fi
    fi
}

check_resources() {
    local ram_gb disk_gb
    ram_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    disk_gb=$(df -BG . | awk 'NR==2 {print int($4)}')
    
    if [ "$ram_gb" -lt 4 ]; then
        log_warn "Low RAM: ${ram_gb}GB (8GB+ recommended for large designs)"
    fi
    
    if [ "$disk_gb" -lt 10 ]; then
        log_error "Need at least 10GB disk space (you have ${disk_gb}GB)"
        exit 1
    fi
    
    log_info "Resources: ${ram_gb}GB RAM, ${disk_gb}GB disk"
}

# Install basic packages
install_prerequisites() {
    log_info "Installing prerequisites..."
    
    sudo apt update
    sudo apt install -y \
        wget curl git make \
        build-essential \
        python3 python3-pip \
        libffi-dev libssl-dev \
        pkg-config \
        git-lfs
    
    # Initialize git-lfs
    git lfs install --system 2>/dev/null || true
    
    log_info "Prerequisites installed"
}

# Install OSS CAD Suite (automatic download with manual fallback)
# Updated Oct 2025: Added automatic download using wget/curl
install_oss_cad_suite() {
    log_info "Installing OSS CAD Suite..."

    # Setup version and URLs (auto-fetch latest or use user-specified)
    setup_oss_cad_version

    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"

    if [ -d "oss-cad-suite" ]; then
        log_warn "OSS CAD Suite already exists, skipping installation"
        return 0
    fi

    # Check if file already exists (from previous download attempt)
    if [ ! -f "$OSS_CAD_FILE" ]; then
        log_info "Downloading OSS CAD Suite $OSS_CAD_VERSION (this may take 5-15 minutes)..."
        log_info "File size: ~1.5GB"

        # Try automatic download with wget or curl
        local download_success=false

        if command -v wget &> /dev/null; then
            log_info "Downloading with wget..."
            if wget --show-progress -O "$OSS_CAD_FILE" "$OSS_CAD_URL" 2>&1; then
                download_success=true
            else
                log_warn "wget download failed"
                rm -f "$OSS_CAD_FILE"  # Remove partial download
            fi
        elif command -v curl &> /dev/null; then
            log_info "Downloading with curl..."
            if curl -L --progress-bar -o "$OSS_CAD_FILE" "$OSS_CAD_URL"; then
                download_success=true
            else
                log_warn "curl download failed"
                rm -f "$OSS_CAD_FILE"  # Remove partial download
            fi
        fi

        # Fallback to manual download if automatic failed
        if [ "$download_success" = false ]; then
            log_warn "Automatic download failed, falling back to manual download"
            echo ""
            echo "========================================"
            echo "Manual Download Required"
            echo "========================================"
            echo ""
            echo "Please download OSS CAD Suite manually:"
            echo ""
            echo "1. Open this link in your browser:"
            echo "   $OSS_CAD_URL"
            echo ""
            echo "2. Save the file to this directory:"
            echo "   $WORKSPACE_DIR"
            echo ""
            echo "3. The file should be named:"
            echo "   $OSS_CAD_FILE"
            echo ""
            echo "4. Come back here and confirm when download is complete"
            echo ""

            read -p "Have you downloaded the file? [y/N]: " -n 1 -r
            echo

            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Download cancelled. Please download manually and re-run this script."
                exit 0
            fi

            # Check again if file exists
            if [ ! -f "$OSS_CAD_FILE" ]; then
                log_error "File $OSS_CAD_FILE not found in $WORKSPACE_DIR"
                log_error "Please ensure you downloaded the correct file to the correct location"
                exit 1
            fi
        fi
    else
        log_info "Found existing OSS CAD Suite file, using it"
    fi
    
    # Verify file exists and has content
    if [ ! -s "$OSS_CAD_FILE" ]; then
        log_error "File $OSS_CAD_FILE is empty or corrupted"
        exit 1
    fi
    
    local file_size=$(du -h "$OSS_CAD_FILE" | cut -f1)
    log_info "Found OSS CAD Suite file: ${file_size}"
    log_info "Extracting... (this will take 2-5 minutes)"
    
    # Extract
    if ! tar -xzf "$OSS_CAD_FILE"; then
        log_error "Extraction failed. File may be corrupted."
        exit 1
    fi
    
    log_info "Extraction complete!"
    
    # Verify extraction worked
    if [ ! -d "oss-cad-suite" ] || [ ! -d "oss-cad-suite/bin" ]; then
        log_error "OSS CAD Suite extraction failed - directory structure missing"
        exit 1
    fi
    
    # Add to PATH
    local bashrc_line='export PATH="$HOME/fpga_workspace/oss-cad-suite/bin:$PATH"'
    if ! grep -q "oss-cad-suite" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# OSS CAD Suite for FPGA development" >> ~/.bashrc
        echo "$bashrc_line" >> ~/.bashrc
        log_info "Added OSS CAD Suite to PATH in ~/.bashrc"
    fi
    
    # Create compatibility symlink for VPI modules (OSS CAD Suite hardcoded path issue)
    if [ ! -L "$HOME/oss-cad-suite" ] && [ ! -d "$HOME/oss-cad-suite" ]; then
        ln -s "$WORKSPACE_DIR/oss-cad-suite" "$HOME/oss-cad-suite"
        log_info "Created compatibility symlink for VPI modules"
    fi
    
    # Test installation
    export PATH="$WORKSPACE_DIR/oss-cad-suite/bin:$PATH"
    if command -v yosys &> /dev/null; then
        log_info "OSS CAD Suite installed successfully!"
        yosys -V | head -1
        nextpnr-ice40 --version | head -1 2>/dev/null || log_warn "NextPNR test failed"
        
        # Protect the installation
        protect_installation
    else
        log_error "OSS CAD Suite installation failed - tools not found"
        exit 1
    fi
}

# Protect OSS CAD Suite installation from accidental modification
protect_installation() {
    log_info "Write-protecting OSS CAD Suite installation..."
    
    # Make the entire oss-cad-suite directory and contents read-only
    chmod -R a-w "$WORKSPACE_DIR/oss-cad-suite"
    
    # Make the parent directory (fpga_workspace) read-only to prevent renaming/removal
    chmod a-w "$WORKSPACE_DIR"
    
    # Optional: Make symlink immutable (if chattr is available)
    if command -v chattr &> /dev/null && [ -L "$HOME/oss-cad-suite" ]; then
        chattr +i "$HOME/oss-cad-suite" 2>/dev/null || log_warn "Could not make symlink immutable"
    fi
    
    log_info "Installation write-protected"
    log_info "Use cleanup mode (--cleanup) to restore write permissions for removal"
}

# Fallback installation using individual packages
install_fallback_tools() {
    log_info "Installing FPGA tools via apt packages..."
    
    # Install individual packages as fallback
    sudo apt install -y \
        yosys \
        nextpnr-ice40 \
        fpga-icestorm \
        arachne-pnr
    
    log_info "Fallback installation complete"
    log_info "Note: Using apt packages instead of OSS CAD Suite"
}

# Install additional essential tools via apt (lighter approach)
install_essential_apt_tools() {
    log_info "Installing additional tools via apt..."
    
    sudo apt install -y \
        iverilog \
        gtkwave \
        verilator \
        openocd
    
    # Python packages for FPGA development
    pip3 install --user \
        cocotb \
        cocotb-test \
        amaranth \
        fusesoc
    
    log_info "Essential tools installed"
}



# Verification function
verify_installation() {
    log_info "Verifying installation..."
    
    export PATH="$WORKSPACE_DIR/oss-cad-suite/bin:$PATH"
    
    # Essential tools (required for basic functionality)
    local essential_tools=("iverilog" "vvp" "gtkwave" "yosys" "nextpnr-ice40" "icepack")
    # Optional tools (nice to have)
    local optional_tools=("verilator" "iceprog" "icetime" "openFPGALoader")
    
    local missing_essential=()
    local missing_optional=()
    
    log_info "Checking essential tools:"
    for tool in "${essential_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info " $tool found"
        else
            missing_essential+=("$tool")
            log_error "✗ $tool not found"
        fi
    done
    
    log_info "Checking optional tools:"
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info " $tool found"
        else
            missing_optional+=("$tool")
            log_warn "- $tool not found (optional)"
        fi
    done
    
    # Check Python packages
    log_info "Checking Python packages:"
    local python_packages=("cocotb" "amaranth" "fusesoc")
    for package in "${python_packages[@]}"; do
        if python3 -c "import $package" &> /dev/null; then
            log_info " $package found"
        else
            log_warn "- $package not found"
        fi
    done
    
    if [ ${#missing_essential[@]} -eq 0 ]; then
        log_info "All essential tools verified!"
        if [ ${#missing_optional[@]} -gt 0 ]; then
            log_warn "Missing optional tools: ${missing_optional[*]}"
        fi
        return 0
    else
        log_error "Missing essential tools: ${missing_essential[*]}"
        return 1
    fi
}

# Restore write permissions before cleanup
restore_write_permissions() {
    log_info "Restoring write permissions for cleanup..."
    
    # Remove immutable flag from symlink if it exists
    if command -v chattr &> /dev/null && [ -L "$HOME/oss-cad-suite" ]; then
        chattr -i "$HOME/oss-cad-suite" 2>/dev/null || true
    fi
    
    # Restore workspace directory permissions
    if [ -d "$WORKSPACE_DIR" ]; then
        chmod u+w "$WORKSPACE_DIR" 2>/dev/null || true
    fi
    
    # Restore OSS CAD Suite permissions recursively
    if [ -d "$WORKSPACE_DIR/oss-cad-suite" ]; then
        chmod -R u+w "$WORKSPACE_DIR/oss-cad-suite" 2>/dev/null || true
    fi
    
    log_info "Write permissions restored for cleanup"
}

# Cleanup functions
cleanup_oss_cad_suite() {
    log_info "Removing OSS CAD Suite..."
    
    # Restore write permissions first
    restore_write_permissions
    
    if [ -d "$WORKSPACE_DIR/oss-cad-suite" ]; then
        rm -rf "$WORKSPACE_DIR/oss-cad-suite"
        log_info "OSS CAD Suite removed"
    else
        log_warn "OSS CAD Suite directory not found"
    fi 
    
    # Remove compatibility symlink
    if [ -L "$HOME/oss-cad-suite" ]; then
        rm -f "$HOME/oss-cad-suite"
        log_info "Compatibility symlink removed"
    fi
    
}

cleanup_apt_packages() {
    log_info "Removing apt packages installed by this script..."
    
    # Remove FPGA-specific packages
    sudo apt remove -y \
        yosys \
        nextpnr-ice40 \
        fpga-icestorm \
        arachne-pnr \
        iverilog \
        gtkwave \
        verilator \
        openocd 2>/dev/null || log_warn "Some apt packages may not have been installed"
    
    # Clean up unused dependencies
    sudo apt autoremove -y
    
    log_info "Apt packages removed"
}

cleanup_python_packages() {
    log_info "Removing Python packages..."
    
    # Remove user-installed packages
    pip3 uninstall -y \
        cocotb \
        cocotb-test \
        amaranth \
        fusesoc 2>/dev/null || log_warn "Some Python packages may not have been installed"
    
    log_info "Python packages removed"
}

cleanup_bashrc() {
    log_info "Removing PATH entries from ~/.bashrc..."

    # Create a backup
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

    # Remove OSS CAD Suite entries
    grep -v "oss-cad-suite" ~/.bashrc > ~/.bashrc.tmp
    grep -v "OSS CAD Suite for FPGA development" ~/.bashrc.tmp > ~/.bashrc.new
    mv ~/.bashrc.new ~/.bashrc
    rm -f ~/.bashrc.tmp

    log_info "PATH entries removed from ~/.bashrc"
    log_info "Backup created at ~/.bashrc.backup.*"
}

# Install Docker by calling install_docker.sh
install_docker_engine() {
    log_info "Installing Docker engine..."

    if [ ! -f "$SCRIPT_DIR/install_docker.sh" ]; then
        log_error "install_docker.sh not found in $SCRIPT_DIR"
        log_error "Cannot install Docker without the installation script"
        exit 1
    fi

    log_info "Running: $SCRIPT_DIR/install_docker.sh"
    echo ""

    if bash "$SCRIPT_DIR/install_docker.sh"; then
        log_info "Docker installation completed successfully"
        return 0
    else
        log_error "Docker installation failed"
        return 1
    fi
}

# Install Quartus Docker by calling install_quartus_docker.sh
install_quartus_docker() {
    log_info "Installing Quartus Prime Lite Docker..."

    if [ ! -f "$SCRIPT_DIR/install_quartus_docker.sh" ]; then
        log_error "install_quartus_docker.sh not found in $SCRIPT_DIR"
        log_error "Cannot install Quartus Docker without the installation script"
        exit 1
    fi

    log_info "Running: $SCRIPT_DIR/install_quartus_docker.sh"
    echo ""

    if bash "$SCRIPT_DIR/install_quartus_docker.sh"; then
        log_info "Quartus Docker installation completed successfully"
        return 0
    else
        log_error "Quartus Docker installation failed"
        return 1
    fi
}

# Cleanup Quartus Docker by calling install_quartus_docker.sh
cleanup_quartus_docker() {
    log_info "Cleaning up Quartus Docker..."

    if [ -f "$SCRIPT_DIR/install_quartus_docker.sh" ]; then
        log_info "Running: $SCRIPT_DIR/install_quartus_docker.sh --cleanup"
        bash "$SCRIPT_DIR/install_quartus_docker.sh" --cleanup
    else
        log_warn "install_quartus_docker.sh not found, skipping Quartus cleanup"
    fi
}

# Cleanup Docker engine by calling install_docker.sh
cleanup_docker_engine() {
    log_info "Cleaning up Docker engine..."

    if [ -f "$SCRIPT_DIR/install_docker.sh" ]; then
        log_info "Running: $SCRIPT_DIR/install_docker.sh --cleanup"
        bash "$SCRIPT_DIR/install_docker.sh" --cleanup
    else
        log_warn "install_docker.sh not found, skipping Docker cleanup"
    fi
}

# Interactive mode selection menu
show_installation_menu() {
    echo ""
    echo "========================================"
    echo "FPGA Tools Installation Menu"
    echo "========================================"
    echo ""
    echo "What would you like to install?"
    echo ""
    echo "1) Open-source FPGA tools (OSS CAD Suite, Icarus Verilog, GTKWave)"
    echo "   - Complete open-source toolchain for iCE40 and other FPGAs"
    echo "   - No license required, ~1.5GB download"
    echo ""
    echo "2) Docker engine only"
    echo "   - Container platform for isolated development environments"
    echo "   - Required for Quartus Docker option"
    echo ""
    echo "3) Quartus Prime Lite Docker (includes Docker)"
    echo "   - Intel Quartus in Docker container"
    echo "   - For Intel/Altera FPGA development"
    echo "   - Free, no license required, ~2GB download"
    echo ""
    echo "4) Everything (OSS tools + Docker + Quartus)"
    echo "   - Complete FPGA development environment"
    echo "   - Both open-source and Intel toolchains"
    echo ""
    echo "5) Exit"
    echo ""

    while true; do
        read -p "Enter your choice [1-5]: " choice
        case $choice in
            1)
                INSTALL_MODE="oss"
                log_info "Selected: Open-source FPGA tools"
                break
                ;;
            2)
                INSTALL_MODE="docker"
                log_info "Selected: Docker engine"
                break
                ;;
            3)
                INSTALL_MODE="quartus"
                log_info "Selected: Quartus Prime Lite Docker"
                break
                ;;
            4)
                INSTALL_MODE="all"
                log_info "Selected: Everything"
                break
                ;;
            5)
                log_info "Installation cancelled"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1-5."
                ;;
        esac
    done
    echo ""
}

# Interactive cleanup menu
show_cleanup_menu() {
    echo ""
    echo "========================================"
    echo "FPGA Tools Cleanup Menu"
    echo "========================================"
    echo ""
    echo "What would you like to remove?"
    echo ""
    echo "1) OSS CAD Suite and related tools"
    echo "2) Docker engine"
    echo "3) Quartus Docker containers and images"
    echo "4) Everything (all components)"
    echo "5) Cancel"
    echo ""

    while true; do
        read -p "Enter your choice [1-5]: " choice
        case $choice in
            1)
                CLEANUP_OSS=true
                log_info "Selected: Remove OSS CAD Suite"
                break
                ;;
            2)
                CLEANUP_DOCKER=true
                log_info "Selected: Remove Docker"
                break
                ;;
            3)
                CLEANUP_QUARTUS=true
                log_info "Selected: Remove Quartus Docker"
                break
                ;;
            4)
                CLEANUP_OSS=true
                CLEANUP_DOCKER=true
                CLEANUP_QUARTUS=true
                log_info "Selected: Remove everything"
                break
                ;;
            5)
                log_info "Cleanup cancelled"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1-5."
                ;;
        esac
    done
    echo ""
}

perform_cleanup() {
    log_info "Starting cleanup..."

    # Show what will be removed
    echo ""
    echo "This will remove:"
    if [ "$CLEANUP_OSS" = true ]; then
        echo "- OSS CAD Suite installation"
        echo "- Apt packages (iverilog, gtkwave, verilator, etc.)"
        echo "- Python packages (cocotb, amaranth, fusesoc)"
        echo "- PATH entries from ~/.bashrc"
    fi
    if [ "$CLEANUP_DOCKER" = true ]; then
        echo "- Docker engine and all containers"
        echo "- Docker configuration files"
    fi
    if [ "$CLEANUP_QUARTUS" = true ]; then
        echo "- Quartus Docker containers and images"
    fi
    echo ""

    read -p "Are you sure you want to proceed? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi

    # Perform cleanup based on selected components
    if [ "$CLEANUP_OSS" = true ]; then
        cleanup_oss_cad_suite
        cleanup_apt_packages
        cleanup_python_packages
        cleanup_bashrc
    fi

    if [ "$CLEANUP_QUARTUS" = true ]; then
        cleanup_quartus_docker
    fi

    if [ "$CLEANUP_DOCKER" = true ]; then
        cleanup_docker_engine
    fi

    echo ""
    echo "========================================"
    echo "Cleanup Complete!"
    echo "========================================"
    echo ""
    echo "Selected components have been removed."
    echo "Please restart your terminal or run: source ~/.bashrc"
    echo ""
}

# Install OSS CAD Suite and related tools
install_oss_tools() {
    log_info "Installing open-source FPGA tools..."

    echo ""
    echo "This will install:"
    echo "- OSS CAD Suite (latest version - auto-downloaded)"
    echo "- Icarus Verilog + GTKWave (simulation and waveforms)"
    echo "- Verilator (high-performance simulation)"
    echo "- Python packages (CocoTB, Amaranth, FuseSoC)"
    echo "- Git LFS for large file handling"
    echo ""
    echo "OSS CAD Suite will be automatically downloaded (~1.5GB)"
    echo "Installation location: $WORKSPACE_DIR"
    echo ""

    read -p "Proceed with OSS tools installation? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "OSS tools installation cancelled"
        return 1
    fi

    install_prerequisites
    install_oss_cad_suite
    install_essential_apt_tools

    echo ""
    echo "========================================"
    echo "Verifying OSS Tools Installation..."
    echo "========================================"

    if ! verify_installation; then
        echo ""
        log_error "Installation failed - some essential tools are missing"
        log_error "Please restart terminal (source ~/.bashrc) and try again"
        return 1
    fi

    echo ""
    log_info "OSS CAD Suite installation completed successfully!"
    return 0
}

# Main function
main() {
    # Handle cleanup mode
    if [ "$CLEANUP_MODE" = true ]; then
        # If no specific cleanup flags set, show interactive menu
        if [ "$CLEANUP_OSS" = false ] && [ "$CLEANUP_DOCKER" = false ] && [ "$CLEANUP_QUARTUS" = false ]; then
            show_cleanup_menu
        fi
        perform_cleanup
        exit 0
    fi

    # Handle reinstall mode
    if [ "$REINSTALL_MODE" = true ]; then
        log_info "Reinstall mode: cleaning up first..."

        # For reinstall, set cleanup flags based on install mode
        if [ -z "$INSTALL_MODE" ]; then
            show_installation_menu
        fi

        case "$INSTALL_MODE" in
            oss)
                CLEANUP_OSS=true
                ;;
            docker)
                CLEANUP_DOCKER=true
                ;;
            quartus)
                CLEANUP_DOCKER=true
                CLEANUP_QUARTUS=true
                ;;
            all)
                CLEANUP_OSS=true
                CLEANUP_DOCKER=true
                CLEANUP_QUARTUS=true
                ;;
        esac

        perform_cleanup
        log_info "Proceeding with fresh installation..."
        echo ""
    fi

    # If mode not specified, show interactive menu
    if [ -z "$INSTALL_MODE" ]; then
        show_installation_menu
    fi

    # Basic checks
    check_wsl2
    check_and_update_wsl
    check_resources

    # Execute installation based on mode
    case "$INSTALL_MODE" in
        oss)
            log_info "Installing open-source FPGA tools..."
            if install_oss_tools; then
                echo ""
                echo "========================================"
                echo "Installation Complete!"
                echo "========================================"
                echo ""
                echo "Next steps:"
                echo "1. Restart terminal or run: source ~/.bashrc"
                echo "2. Create projects: ./initiate_proj.sh"
                echo "3. Test tools: yosys -V, iverilog -V"
            fi
            ;;

        docker)
            log_info "Installing Docker engine..."
            if install_docker_engine; then
                echo ""
                echo "========================================"
                echo "Installation Complete!"
                echo "========================================"
                echo ""
                echo "Next steps:"
                echo "1. Restart terminal to apply Docker group membership"
                echo "2. Test Docker: docker run hello-world"
                echo "3. Install Quartus: ./install_fpga_tools.sh --mode=quartus"
            fi
            ;;

        quartus)
            log_info "Installing Quartus Prime Lite Docker..."
            log_info "This will install Docker first (if needed), then Quartus container"
            echo ""

            # Install Docker first
            if ! install_docker_engine; then
                log_error "Docker installation failed, cannot proceed with Quartus"
                exit 1
            fi

            echo ""
            log_info "Docker installed, proceeding with Quartus..."
            echo ""

            # Install Quartus
            if install_quartus_docker; then
                echo ""
                echo "========================================"
                echo "Installation Complete!"
                echo "========================================"
                echo ""
                echo "Next steps:"
                echo "1. Restart terminal to apply Docker group membership"
                echo "2. Create Quartus projects: ./initiate_proj.sh (choose option 2)"
            fi
            ;;

        all)
            log_info "Installing everything (OSS tools + Docker + Quartus)..."
            echo ""

            # Install OSS tools
            log_info "Step 1/3: Installing open-source FPGA tools..."
            if ! install_oss_tools; then
                log_error "OSS tools installation failed"
                exit 1
            fi

            echo ""
            log_info "Step 2/3: Installing Docker engine..."
            if ! install_docker_engine; then
                log_error "Docker installation failed"
                exit 1
            fi

            echo ""
            log_info "Step 3/3: Installing Quartus Prime Lite Docker..."
            if ! install_quartus_docker; then
                log_error "Quartus installation failed"
                exit 1
            fi

            echo ""
            echo "========================================"
            echo "Complete Installation Finished!"
            echo "========================================"
            echo ""
            echo "All components installed successfully:"
            echo "✓ OSS CAD Suite (Yosys, NextPNR, Icarus, GTKWave)"
            echo "✓ Docker engine"
            echo "✓ Quartus Prime Lite Docker"
            echo ""
            echo "Next steps:"
            echo "1. Restart terminal or run: source ~/.bashrc"
            echo "2. Create projects: ./initiate_proj.sh (choose OSS or Quartus)"
            echo "3. Test tools: yosys -V, docker --version"
            ;;

        *)
            log_error "Invalid installation mode: $INSTALL_MODE"
            exit 1
            ;;
    esac
}

main "$@"
