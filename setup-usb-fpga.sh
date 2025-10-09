#!/bin/bash
# USB FPGA Passthrough Setup for WSL2
# Helps configure USB-Blaster and other JTAG cables for use in WSL2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running on WSL2
check_wsl2() {
    if grep -qi microsoft /proc/version; then
        return 0  # Is WSL
    else
        return 1  # Not WSL
    fi
}

# Find usbipd executable path
find_usbipd_path() {
    # Check common installation paths
    local paths=(
        "/mnt/c/Program Files/usbipd-win/usbipd.exe"
        "/mnt/c/Program Files (x86)/usbipd-win/usbipd.exe"
        "/mnt/c/ProgramData/chocolatey/bin/usbipd.exe"
    )

    for path in "${paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    # Try to find it
    local found=$(find /mnt/c/Program* -name "usbipd.exe" 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi

    return 1
}

# Check if usbipd is available in Windows
# Uses multiple detection methods for robustness
check_usbipd_windows() {
    # Method 1: Check if we can find the executable
    local usbipd_path=$(find_usbipd_path)
    if [ -n "$usbipd_path" ] && [ -f "$usbipd_path" ]; then
        return 0
    fi

    # Method 2: Try direct execution test
    if usbipd.exe --version &>/dev/null; then
        return 0
    fi

    return 1  # Not found
}

# Get usbipd version (for display)
get_usbipd_version() {
    local version=""
    local usbipd_path=$(find_usbipd_path)

    if [ -n "$usbipd_path" ]; then
        version=$("$usbipd_path" --version 2>/dev/null | tr -d '\r\n' | head -1)
        if [ -n "$version" ]; then
            echo "$version"
            return
        fi
    fi

    # Fallback methods
    version=$(cd /tmp && usbipd.exe --version 2>/dev/null | tr -d '\r\n' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
        return
    fi

    echo "unknown"
}

# Execute usbipd commands
exec_usbipd() {
    local cmd="$1"
    local result=""
    local usbipd_path=$(find_usbipd_path)

    if [ -z "$usbipd_path" ]; then
        # Fallback: try if usbipd is in PATH
        result=$(cd /tmp && usbipd.exe ${cmd#usbipd } 2>/dev/null)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
        return 1
    fi

    # Execute with full path
    result=$("$usbipd_path" ${cmd#usbipd } 2>/dev/null)
    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi

    return 1
}

print_header "USB FPGA Passthrough Setup for WSL2"

# Step 1: Check environment
print_step "Step 1: Checking environment..."
echo ""

if ! check_wsl2; then
    print_error "This script is for WSL2 environments only"
    echo "You appear to be running on native Linux."
    echo "USB devices should be directly accessible without passthrough."
    echo ""
    echo "Try: quartus-prog --detect"
    exit 1
fi

print_success "Running on WSL2"

# Check WSL kernel version
KERNEL_VERSION=$(uname -r)
echo "Kernel: $KERNEL_VERSION"
echo ""

# Step 2: Check usbipd-win installation
print_step "Step 2: Checking usbipd-win installation on Windows..."
echo ""

if check_usbipd_windows; then
    USBIPD_VERSION=$(get_usbipd_version)
    print_success "usbipd-win is installed (version: $USBIPD_VERSION)"
else
    print_warning "usbipd-win is not installed on Windows"
    echo ""
    echo "usbipd-win is required to share USB devices from Windows to WSL2."
    echo ""
    echo "Installation instructions:"
    echo ""
    echo "1. Open PowerShell as Administrator on Windows"
    echo "2. Run one of these commands:"
    echo ""
    echo "   Option A - Using winget (recommended):"
    echo -e "   ${CYAN}winget install --interactive --exact dorssel.usbipd-win${NC}"
    echo ""
    echo "   Option B - Using MSI installer:"
    echo "   Download from: https://github.com/dorssel/usbipd-win/releases"
    echo ""
    echo "3. After installation, run this script again"
    echo ""
    exit 1
fi

echo ""

# Step 3: List USB devices
print_step "Step 3: Detecting USB FPGA devices on Windows..."
echo ""

print_info "Querying Windows USB devices..."
echo ""

# Get USB device list from Windows
USB_LIST=$(exec_usbipd "usbipd list" | tr -d '\r')

if [ $? -ne 0 ] || [ -z "$USB_LIST" ]; then
    print_error "Failed to query USB devices"
    echo ""
    echo "This might be because:"
    echo "  1. usbipd-win is not running properly"
    echo "  2. Permission issues (try running PowerShell as Administrator)"
    echo "  3. usbipd service not started"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Open Windows PowerShell and run: usbipd list"
    echo "  2. If that fails, restart usbipd service (as Administrator):"
    echo "     net stop usbipd"
    echo "     net start usbipd"
    echo ""
    echo "You can still manually set up USB passthrough:"
    echo "  1. In Windows PowerShell (as Administrator):"
    echo "     usbipd list"
    echo "     usbipd bind --busid X-X"
    echo "     usbipd attach --wsl --busid X-X"
    echo ""
    exit 1
fi

# Display USB devices
echo "$USB_LIST"
echo ""

# Look for common FPGA devices
FPGA_DEVICES=$(echo "$USB_LIST" | grep -iE "blaster|jtag|altera|intel|xilinx|ftdi")

if [ -n "$FPGA_DEVICES" ]; then
    print_success "Found potential FPGA device(s):"
    echo ""
    echo "$FPGA_DEVICES"
    echo ""
else
    print_warning "No obvious FPGA devices detected"
    echo ""
    echo "Common FPGA JTAG cables to look for:"
    echo "  - USB-Blaster (Altera/Intel)"
    echo "  - USB-Blaster II (Altera/Intel)"
    echo "  - FTDI-based cables"
    echo ""
    echo "Make sure your FPGA board is:"
    echo "  1. Connected to USB"
    echo "  2. Powered on"
    echo "  3. Using a data cable (not charge-only)"
    echo ""
fi

# Step 4: Guide user through binding
print_step "Step 4: Binding USB device to WSL2..."
echo ""

print_info "To share a USB device with WSL2, you need to:"
echo ""
echo "1. Find your device's BUSID or Hardware ID from the list above"
echo "2. Bind it (one-time setup)"
echo "3. Attach it to WSL2"
echo ""

echo "Example Hardware IDs for common FPGA cables:"
echo "  - USB-Blaster:    0403:6010 (FTDI)"
echo "  - USB-Blaster II: 09fb:6010 or 09fb:6810 (Altera)"
echo ""

read -p "Do you want to bind a device now? [y/N]: " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter the BUSID (e.g., 2-1) OR Hardware ID (e.g., 0403:6010):"
    read -p "Device identifier: " DEVICE_ID

    if [ -z "$DEVICE_ID" ]; then
        print_error "No device identifier provided"
        exit 1
    fi

    # Determine if BUSID or Hardware ID
    if [[ "$DEVICE_ID" =~ ^[0-9]+-[0-9]+$ ]]; then
        # BUSID format
        BIND_CMD="usbipd bind --busid $DEVICE_ID"
        ATTACH_CMD="usbipd attach --wsl --busid $DEVICE_ID"
    else
        # Hardware ID format
        BIND_CMD="usbipd bind --hardware-id $DEVICE_ID"
        ATTACH_CMD="usbipd attach --wsl --hardware-id $DEVICE_ID"
    fi

    echo ""
    print_info "You need to run these commands in PowerShell as Administrator:"
    echo ""
    echo -e "${CYAN}$BIND_CMD${NC}"
    echo -e "${CYAN}$ATTACH_CMD${NC}"
    echo ""

    read -p "Have you run these commands? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Test device visibility
        print_step "Step 5: Testing USB device visibility in WSL2..."
        echo ""

        sleep 2  # Give time for device to attach

        print_info "Running lsusb to check USB devices..."
        echo ""

        if command -v lsusb &> /dev/null; then
            lsusb | grep -iE "blaster|jtag|altera|intel|ftdi|future" || lsusb
        else
            print_warning "lsusb not installed"
            echo "Install with: sudo apt install usbutils"
        fi

        echo ""
        print_step "Step 6: Testing FPGA detection..."
        echo ""

        if command -v openFPGALoader &> /dev/null; then
            print_info "Running openFPGALoader --detect..."
            echo ""
            openFPGALoader --detect 2>&1 || true
            echo ""

            if [ $? -eq 0 ]; then
                print_success "FPGA device detected successfully!"
                echo ""
                echo "You can now program your FPGA with:"
                echo "  quartus-prog <your_file>.sof"
            else
                print_warning "Device attached but not detected by openFPGALoader"
                echo ""
                echo "Possible issues:"
                echo "  1. Wrong cable type specified"
                echo "  2. Driver conflict"
                echo "  3. Try: quartus-prog --scan-usb"
                echo "  4. Try with cable flag: quartus-prog -c usb-blaster --detect"
            fi
        else
            print_warning "openFPGALoader not found in PATH"
            echo ""
            echo "Add it to your PATH:"
            echo "  export PATH=\$HOME/fpga_workspace/oss-cad-suite/bin:\$PATH"
        fi
    fi
else
    echo ""
    print_info "Manual setup instructions:"
    echo ""
    echo "1. Open PowerShell as Administrator"
    echo ""
    echo "2. List devices:"
    echo -e "   ${CYAN}usbipd list${NC}"
    echo ""
    echo "3. Bind your FPGA device (one-time, replace BUSID):"
    echo -e "   ${CYAN}usbipd bind --busid X-X${NC}"
    echo "   or with Hardware ID:"
    echo -e "   ${CYAN}usbipd bind --hardware-id 0403:6010${NC}"
    echo ""
    echo "4. Attach to WSL2:"
    echo -e "   ${CYAN}usbipd attach --wsl --busid X-X${NC}"
    echo "   or with Hardware ID:"
    echo -e "   ${CYAN}usbipd attach --wsl --hardware-id 0403:6010${NC}"
    echo ""
    echo "5. Optional - auto-attach (attaches whenever device is plugged in):"
    echo -e "   ${CYAN}usbipd attach --wsl --auto-attach --busid X-X${NC}"
    echo ""
    echo "6. Verify in WSL2:"
    echo -e "   ${CYAN}lsusb${NC}"
    echo -e "   ${CYAN}quartus-prog --detect${NC}"
    echo ""
fi

echo ""
print_header "Setup Complete"

echo "Quick Reference:"
echo ""
echo "List Windows USB devices:"
echo "  cmd.exe /c 'usbipd list'"
echo ""
echo "Attach device to WSL2 (run in Windows PowerShell as Admin):"
echo "  usbipd attach --wsl --busid X-X"
echo ""
echo "Detach device (run in Windows PowerShell):"
echo "  usbipd detach --busid X-X"
echo ""
echo "Test FPGA detection in WSL2:"
echo "  quartus-prog --detect"
echo "  quartus-prog --scan-usb"
echo ""
echo "For more info: https://github.com/dorssel/usbipd-win"
echo ""
