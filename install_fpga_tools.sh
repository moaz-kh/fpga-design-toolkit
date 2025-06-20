#!/bin/bash
# Simple FPGA Design Tools Installer
# Focus: OSS CAD Suite (comprehensive toolchain)
# Target: WSL2 Ubuntu 22.04+

set -euo pipefail

# Configuration
readonly WORKSPACE_DIR="$HOME/fpga_workspace"
readonly OSS_CAD_VERSION="20231102"
readonly OSS_CAD_FILE="oss-cad-suite-linux-x64-${OSS_CAD_VERSION}.tgz"
readonly OSS_CAD_URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-11-02/${OSS_CAD_FILE}"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "========================================"
echo "Simple FPGA Tools Installer"
echo "OSS CAD Suite + Essential Tools"
echo "========================================"

# Basic checks
check_wsl2() {
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        log_error "This script requires WSL2"
        exit 1
    fi
    log_info "WSL2 environment detected: $WSL_DISTRO_NAME"
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

# Install OSS CAD Suite (manual download approach)
install_oss_cad_suite() {
    log_info "Installing OSS CAD Suite..."
    
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    
    if [ -d "oss-cad-suite" ]; then
        log_warn "OSS CAD Suite already exists, skipping installation"
        return 0
    fi
    
    # Check if user already downloaded the file
    if [ ! -f "$OSS_CAD_FILE" ]; then
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
    
    # Test installation
    export PATH="$WORKSPACE_DIR/oss-cad-suite/bin:$PATH"
    if command -v yosys &> /dev/null; then
        log_info "OSS CAD Suite installed successfully!"
        yosys -V | head -1
        nextpnr-ice40 --version | head -1 2>/dev/null || log_warn "NextPNR test failed"
    else
        log_error "OSS CAD Suite installation failed - tools not found"
        exit 1
    fi
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

# Main function
main() {
    check_wsl2
    check_resources
    
    echo ""
    echo "This will install:"
    echo "- OSS CAD Suite (manual download required)"
    echo "- Icarus Verilog + GTKWave (simulation and waveforms)"
    echo "- Verilator (high-performance simulation)"
    echo "- Python packages (CocoTB, Amaranth, FuseSoC)"
    echo "- Git LFS for large file handling"
    echo ""
    echo "OSS CAD Suite requires manual download (no automatic download)"
    echo "Location: $WORKSPACE_DIR"
    echo ""
    
    read -p "Proceed with installation? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    install_prerequisites
    install_oss_cad_suite
    install_essential_apt_tools
    
    echo ""
    echo "========================================"
    echo "Verifying Installation..."
    echo "========================================"
    
    if ! verify_installation; then
        echo ""
        log_error "Installation failed - some essential tools are missing"
        log_error "Please restart terminal (source ~/.bashrc) and try again"
        log_error "If problems persist, install manually: sudo apt install iverilog gtkwave yosys"
        exit 1
    fi
    
    echo ""
    echo "========================================"
    echo "Installation Complete!"
    echo "========================================"
    echo ""
    echo "Location: $WORKSPACE_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Restart terminal or run: source ~/.bashrc"
    echo "2. All tools needed for initiate_proj.sh are now installed"
    echo "3. Create projects with fpga-design-toolkit:"
    echo "   ./initiate_proj.sh"
    echo "4. Test tools:"
    echo "   yosys -V"
    echo "   iverilog -V"
    echo ""
    echo "Installation method: Manual download + apt packages"
    echo ""
    echo "Create new projects with:"
    echo "- fpga-design-toolkit: ./initiate_proj.sh"
    echo "- Manual project setup using installed tools"
    echo ""
    echo "All tools required by initiate_proj.sh are now installed!"
    echo ""
    echo "Documentation:"
    echo "- OSS CAD Suite: https://github.com/YosysHQ/oss-cad-suite-build"
    echo "- Yosys manual: http://www.clifford.at/yosys/documentation.html"
    echo "- NextPNR docs: https://github.com/YosysHQ/nextpnr"
}

main "$@"