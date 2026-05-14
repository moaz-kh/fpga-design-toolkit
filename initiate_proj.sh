#!/bin/bash
# FPGA Project Creation Wrapper
# Unified entry point for OSS and Quartus project workflows
# Usage: ./initiate_proj.sh

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "FPGA Project Creation"
echo "========================================"
echo ""
echo "This toolkit supports multiple FPGA tool chains."
echo "Choose the one that matches your target FPGA:"
echo ""
echo "1) Open-source tools (Yosys, NextPNR, Icarus Verilog)"
echo "   → For Lattice iCE40, ECP5, and other open FPGA architectures"
echo "   → No licenses required, completely free"
echo ""
echo "2) Intel Quartus Prime Lite (via Docker)"
echo "   → For Intel/Altera FPGAs (MAX 10, Cyclone IV, etc.)"
echo "   → Free for Quartus Lite devices, runs in Docker"
echo ""

while true; do
    read -p "Select toolchain [1-2]: " choice
    echo ""

    case $choice in
        1)
            echo -e "${GREEN}[INFO]${NC} Selected: Open-source FPGA tools"
            echo -e "${BLUE}[INFO]${NC} Launching create_oss_project.sh..."
            echo ""
            if [ -x "./scripts/create_oss_project.sh" ]; then
                ./scripts/create_oss_project.sh
            else
                echo "ERROR: scripts/create_oss_project.sh not found or not executable"
                exit 1
            fi
            break
            ;;
        2)
            echo -e "${GREEN}[INFO]${NC} Selected: Intel Quartus Prime Lite"
            echo -e "${BLUE}[INFO]${NC} Launching create_quartus_project.sh..."
            echo ""
            if [ -x "./scripts/create_quartus_project.sh" ]; then
                ./scripts/create_quartus_project.sh
            else
                echo "ERROR: scripts/create_quartus_project.sh not found or not executable"
                exit 1
            fi
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done
