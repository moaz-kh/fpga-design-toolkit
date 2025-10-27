#!/bin/bash
# Quartus Native Project Initialization Script
# Creates projects using Quartus Prime's native TCL interface for proper file generation
# Supports multiple board types including TEI0010
# Usage: bash initiate_quartus_native.sh [--board BOARD_TYPE]

set -e  # Exit on any error

# Board configuration presets
declare -A BOARD_CONFIGS
BOARD_CONFIGS["tei0010"]="MAX 10:10M08SAU169C8GES:U169:-8"
BOARD_CONFIGS["de10-lite"]="MAX 10:10M50DAF484C7G:F484:-7"
BOARD_CONFIGS["de2-115"]="Cyclone IV E:EP4CE115F29C7N:F780:-7"
BOARD_CONFIGS["de10-standard"]="Cyclone V:5CSXFC6D6F31C6N:F31:-6"

# Default board
DEFAULT_BOARD="tei0010"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -b, --board BOARD    Board type (default: $DEFAULT_BOARD)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Supported boards:"
    for board in "${!BOARD_CONFIGS[@]}"; do
        IFS=':' read -r family device package speed <<< "${BOARD_CONFIGS[$board]}"
        printf "  %-12s %s %s\n" "$board" "$family" "$device"
    done
    echo ""
    echo "Examples:"
    echo "  $0                       # Create TEI0010 project"
    echo "  $0 --board de10-lite     # Create DE10-Lite project"
}

# Parse command line arguments
BOARD_TYPE="$DEFAULT_BOARD"

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--board)
            BOARD_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate board type
if [[ ! "${BOARD_CONFIGS[$BOARD_TYPE]}" ]]; then
    print_error "Unsupported board type: $BOARD_TYPE"
    echo "Supported boards: ${!BOARD_CONFIGS[*]}"
    exit 1
fi

# Parse board configuration
IFS=':' read -r FPGA_FAMILY FPGA_DEVICE FPGA_PACKAGE SPEED_GRADE <<< "${BOARD_CONFIGS[$BOARD_TYPE]}"

echo "================================================"
echo "Quartus Native Project Initialization"
echo "================================================"
echo "Using Quartus Prime's native project creation"

# Get project name with validation
while true; do
    echo
    echo "Enter your project name:"
    echo "(alphanumeric, underscore, hyphen only)"
    read -p "Project Name: " PROJECT_NAME

    # Check if empty
    if [[ -z "$PROJECT_NAME" ]]; then
        print_error "Project name cannot be empty."
        continue
    fi

    # Check for valid characters
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid project name. Use only letters, numbers, underscore, and hyphen."
        continue
    fi

    # Check if directory already exists
    if [[ -d "$PROJECT_NAME" ]]; then
        print_error "Directory '$PROJECT_NAME' already exists!"
        read -p "Do you want to use a different name? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Exiting..."
            exit 1
        fi
        continue
    fi

    # Valid project name
    print_success "Valid project name: $PROJECT_NAME"
    break
done

# Confirmation
echo
echo "Project Configuration:"
echo "  Name: $PROJECT_NAME"
echo "  Board: $BOARD_TYPE"
echo "  FPGA Family: $FPGA_FAMILY"
echo "  Device: $FPGA_DEVICE"
echo "  Package: $FPGA_PACKAGE"
echo "  Speed Grade: $SPEED_GRADE"
echo
read -p "Proceed with project creation? [Y/n]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Project creation cancelled."
    exit 0
fi

echo
echo "================================================"
echo "Creating Quartus Project Directory"
echo "================================================"

# Create project directory
print_info "Creating project directory: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create subdirectories (unified structure)
mkdir -p sources/rtl sources/constraints sim/waves sim/logs

echo
echo "================================================"
echo "Generating Quartus TCL Script"
echo "================================================"

# Create TCL script for native project creation
print_info "Creating project generation script..."
cat > create_quartus_project.tcl << EOF
#!/usr/bin/tclsh

# Load required packages
load_package flow

# Create new project
project_new "$PROJECT_NAME" -overwrite

# Set device family and part
set_global_assignment -name FAMILY "$FPGA_FAMILY"
set_global_assignment -name DEVICE $FPGA_DEVICE

# Set top-level entity
set_global_assignment -name TOP_LEVEL_ENTITY $PROJECT_NAME

# Basic project settings
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256

# EDA tool settings
set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (Verilog)"
set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_timing
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_symbol
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_signal_integrity
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_boundary_scan

# Partition settings
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top

# Source files (will be created later)
set_global_assignment -name VERILOG_FILE sources/rtl/${PROJECT_NAME}.v

# Board-specific settings
EOF

# Add board-specific settings
if [[ "$BOARD_TYPE" == "tei0010" ]]; then
    cat >> create_quartus_project.tcl << 'EOF'

# TEI0010 specific settings and pin assignments
set_global_assignment -name SDC_FILE sources/constraints/tei0010_timing.sdc

# Clock assignments
set_location_assignment PIN_H6 -to CLK12M
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLK12M

# Reset/User button
set_location_assignment PIN_E6 -to RESET
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RESET

# LEDs
set_location_assignment PIN_D8 -to LED[0]
set_location_assignment PIN_A8 -to LED[1]
set_location_assignment PIN_A9 -to LED[2]
set_location_assignment PIN_C9 -to LED[3]
set_location_assignment PIN_A10 -to LED[4]
set_location_assignment PIN_B10 -to LED[5]
set_location_assignment PIN_A11 -to LED[6]
set_location_assignment PIN_C10 -to LED[7]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[7]

EOF
elif [[ "$BOARD_TYPE" == "de10-lite" ]]; then
    cat >> create_quartus_project.tcl << 'EOF'

# DE10-Lite specific settings
set_global_assignment -name SDC_FILE sources/constraints/de10_lite_timing.sdc

# Clock (50MHz)
set_location_assignment PIN_P11 -to CLK50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLK50

# Reset
set_location_assignment PIN_B8 -to RESET
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RESET

# LEDs
set_location_assignment PIN_A8 -to LED[0]
set_location_assignment PIN_A9 -to LED[1]
set_location_assignment PIN_A10 -to LED[2]
set_location_assignment PIN_B10 -to LED[3]
set_location_assignment PIN_D13 -to LED[4]
set_location_assignment PIN_C13 -to LED[5]
set_location_assignment PIN_E14 -to LED[6]
set_location_assignment PIN_D14 -to LED[7]
set_location_assignment PIN_A11 -to LED[8]
set_location_assignment PIN_B11 -to LED[9]

EOF
elif [[ "$BOARD_TYPE" == "de2-115" ]]; then
    cat >> create_quartus_project.tcl << 'EOF'

# DE2-115 specific settings
# NOTE: Verify pin assignments against DE2-115 User Manual Table 3-5, Table 4-1
set_global_assignment -name SDC_FILE sources/constraints/de2_115_timing.sdc

# Clock (50MHz)
set_location_assignment PIN_Y2 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# Reset (KEY[0] - active low)
set_location_assignment PIN_M23 -to KEY0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY0

# LEDs (LEDR[7:0])
set_location_assignment PIN_G19 -to LEDR[0]
set_location_assignment PIN_F19 -to LEDR[1]
set_location_assignment PIN_E19 -to LEDR[2]
set_location_assignment PIN_F21 -to LEDR[3]
set_location_assignment PIN_F18 -to LEDR[4]
set_location_assignment PIN_E18 -to LEDR[5]
set_location_assignment PIN_J19 -to LEDR[6]
set_location_assignment PIN_H19 -to LEDR[7]

set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[3]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[4]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[5]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[6]
set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[7]

EOF
elif [[ "$BOARD_TYPE" == "de10-standard" ]]; then
    cat >> create_quartus_project.tcl << 'EOF'

# DE10-Standard specific settings
# NOTE: Verify pin assignments against DE10-Standard User Manual Table 3-5
set_global_assignment -name SDC_FILE sources/constraints/de10_standard_timing.sdc

# Clock (50MHz - FPGA_CLK1_50)
set_location_assignment PIN_AF14 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# Reset (KEY[0] - active low)
set_location_assignment PIN_AA14 -to KEY0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY0

# LEDs (LEDR[7:0])
set_location_assignment PIN_W20 -to LEDR[0]
set_location_assignment PIN_Y19 -to LEDR[1]
set_location_assignment PIN_W19 -to LEDR[2]
set_location_assignment PIN_W17 -to LEDR[3]
set_location_assignment PIN_V18 -to LEDR[4]
set_location_assignment PIN_V17 -to LEDR[5]
set_location_assignment PIN_W16 -to LEDR[6]
set_location_assignment PIN_V16 -to LEDR[7]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[7]

EOF
fi

# Finalize TCL script
cat >> create_quartus_project.tcl << 'EOF'

# Partition assignment
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

# Save and close project
project_close

puts "Quartus project created successfully!"
EOF

echo
echo "================================================"
echo "Running Quartus Native Project Creation"
echo "================================================"

# Docker configuration for Quartus
DOCKER_IMAGE="raetro/quartus:21.1"
WORKDIR="${PWD}"

print_info "Executing Quartus TCL script..."
if docker run --rm \
    -v "$WORKDIR:/build" \
    -w /build \
    --user $(id -u):$(id -g) \
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$HOME/.Xauthority:/home/$(whoami)/.Xauthority:rw" \
    --net=host \
    "$DOCKER_IMAGE" quartus_sh -t create_quartus_project.tcl; then
    print_success "Quartus project files generated successfully!"
else
    print_error "Failed to create Quartus project"
    exit 1
fi

echo
echo "================================================"
echo "Creating Source Files"
echo "================================================"

# Create appropriate RTL template based on board
if [[ "$BOARD_TYPE" == "tei0010" ]]; then
    print_info "Creating TEI0010 RTL template..."
    cat > sources/rtl/${PROJECT_NAME}.v << EOF
module ${PROJECT_NAME} (
    input         CLK12M,           // 12MHz oscillator input
    input         RESET,            // Reset button (active low)
    output [7:0]  LED               // 8 LEDs
);

    // Counter for LED blink control (12MHz clock)
    reg [25:0] counter;
    reg [7:0] led_state;

    // LED output assignment
    assign LED = led_state;
    initial begin 
        counter <= 26'd0;
        led_state <= 8'h01;
    end 
    // LED control logic
    always @(posedge CLK12M) begin
        if (~RESET) begin
            counter <= 26'd0;
            led_state <= 8'h01;
        end else begin
            counter <= counter + 1;

            // Update LEDs every ~5.6 seconds (2^26 / 12MHz)
            if (counter == 26'h3FFFFFF) begin
                led_state <= {led_state[6:0], led_state[7]}; // Rotate left
            end
        end
    end

endmodule
EOF

    # Create timing constraints for TEI0010
    print_info "Creating TEI0010 timing constraints..."
    cat > sources/constraints/tei0010_timing.sdc << 'EOF'
# TEI0010 Timing Constraints
# 12MHz clock constraint (83.33ns period)

create_clock -period 83.33 -name clk_sys [get_ports CLK12M]

# Input delays
set_input_delay -clock { clk_sys } -max 20 [get_ports RESET]
set_input_delay -clock { clk_sys } -min 20 [get_ports RESET]

# Output delays
set_output_delay -clock { clk_sys } -max 20 [get_ports LED[*]]
set_output_delay -clock { clk_sys } -min 20 [get_ports LED[*]]
EOF

elif [[ "$BOARD_TYPE" == "de10-lite" ]]; then
    print_info "Creating DE10-Lite RTL template..."
    cat > sources/rtl/${PROJECT_NAME}.v << EOF
module ${PROJECT_NAME} (
    input         CLK50,            // 50MHz oscillator input
    input         RESET,            // Reset button (active low)
    output [9:0]  LED               // 10 LEDs
);

    // Counter for LED blink control (50MHz clock)
    reg [28:0] counter;
    reg [9:0] led_state;

    // LED output assignment
    assign LED = led_state;

    initial begin 
        counter <= 29'd0;
        led_state <= 10'h001;
    end 
    // LED control logic
    always @(posedge CLK50) begin
        if (~RESET) begin
            counter <= 29'd0;
            led_state <= 10'h001;
        end else begin
            counter <= counter + 1;

            // Update LEDs every ~10.7 seconds (2^29 / 50MHz)
            if (counter == 29'h1FFFFFFF) begin
                led_state <= {led_state[8:0], led_state[9]}; // Rotate left
            end
        end
    end

endmodule
EOF

    # Create timing constraints for DE10-Lite
    print_info "Creating DE10-Lite timing constraints..."
    cat > sources/constraints/de10_lite_timing.sdc << 'EOF'
# DE10-Lite Timing Constraints
# 50MHz clock constraint (20ns period)

create_clock -period 20.000 -name clk_sys [get_ports CLK50]

# Input delays
set_input_delay -clock { clk_sys } -max 5 [get_ports RESET]
set_input_delay -clock { clk_sys } -min 5 [get_ports RESET]

# Output delays
set_output_delay -clock { clk_sys } -max 5 [get_ports LED[*]]
set_output_delay -clock { clk_sys } -min 5 [get_ports LED[*]]
EOF

elif [[ "$BOARD_TYPE" == "de2-115" ]]; then
    print_info "Creating DE2-115 RTL template..."
    cat > sources/rtl/${PROJECT_NAME}.v << EOF
module ${PROJECT_NAME} (
    input         CLOCK_50,        // 50MHz oscillator input
    input         KEY0,             // Reset button (active low)
    output [7:0]  LEDR              // 8 red LEDs
);

    // Counter for LED blink control (50MHz clock)
    reg [28:0] counter;
    reg [7:0] led_state;

    // LED output assignment
    assign LEDR = led_state;

    initial begin
        counter <= 29'd0;
        led_state <= 8'h01;
    end
    // LED control logic
    always @(posedge CLOCK_50) begin
        if (~KEY0) begin
            counter <= 29'd0;
            led_state <= 8'h01;
        end else begin
            counter <= counter + 1;

            // Update LEDs every ~10.7 seconds (2^29 / 50MHz)
            if (counter == 29'h1FFFFFFF) begin
                led_state <= {led_state[6:0], led_state[7]}; // Rotate left
            end
        end
    end

endmodule
EOF

    # Create timing constraints for DE2-115
    print_info "Creating DE2-115 timing constraints..."
    cat > sources/constraints/de2_115_timing.sdc << 'EOF'
# DE2-115 Timing Constraints
# 50MHz clock constraint (20ns period)

create_clock -period 20.000 -name clk_sys [get_ports CLOCK_50]

# Input delays
set_input_delay -clock { clk_sys } -max 5 [get_ports KEY0]
set_input_delay -clock { clk_sys } -min 5 [get_ports KEY0]

# Output delays
set_output_delay -clock { clk_sys } -max 5 [get_ports LEDR[*]]
set_output_delay -clock { clk_sys } -min 5 [get_ports LEDR[*]]
EOF

elif [[ "$BOARD_TYPE" == "de10-standard" ]]; then
    print_info "Creating DE10-Standard RTL template..."
    cat > sources/rtl/${PROJECT_NAME}.v << EOF
module ${PROJECT_NAME} (
    input         CLOCK_50,        // 50MHz oscillator input
    input         KEY0,             // Reset button (active low)
    output [7:0]  LEDR              // 8 red LEDs
);

    // Counter for LED blink control (50MHz clock)
    reg [28:0] counter;
    reg [7:0] led_state;

    // LED output assignment
    assign LEDR = led_state;

    initial begin
        counter <= 29'd0;
        led_state <= 8'h01;
    end
    // LED control logic
    always @(posedge CLOCK_50) begin
        if (~KEY0) begin
            counter <= 29'd0;
            led_state <= 8'h01;
        end else begin
            counter <= counter + 1;

            // Update LEDs every ~10.7 seconds (2^29 / 50MHz)
            if (counter == 29'h1FFFFFFF) begin
                led_state <= {led_state[6:0], led_state[7]}; // Rotate left
            end
        end
    end

endmodule
EOF

    # Create timing constraints for DE10-Standard
    print_info "Creating DE10-Standard timing constraints..."
    cat > sources/constraints/de10_standard_timing.sdc << 'EOF'
# DE10-Standard Timing Constraints
# 50MHz clock constraint (20ns period)

create_clock -period 20.000 -name clk_sys [get_ports CLOCK_50]

# Input delays
set_input_delay -clock { clk_sys } -max 5 [get_ports KEY0]
set_input_delay -clock { clk_sys } -min 5 [get_ports KEY0]

# Output delays
set_output_delay -clock { clk_sys } -max 5 [get_ports LEDR[*]]
set_output_delay -clock { clk_sys } -min 5 [get_ports LEDR[*]]
EOF

else
    print_info "Creating generic RTL template..."
    cat > sources/rtl/${PROJECT_NAME}.v << EOF
module ${PROJECT_NAME} (
    input         clk,              // Clock input
    input         reset,            // Reset (active low)
    output [3:0]  led               // 4 LEDs
);

    // Counter for LED blink control
    reg [25:0] counter;
    reg [3:0] led_state;

    // LED output assignment
    assign led = led_state;

    // LED control logic
    always @(posedge clk) begin
        if (~reset) begin
            counter <= 26'd0;
            led_state <= 4'h1;
        end else begin
            counter <= counter + 1;

            // Update LEDs periodically
            if (counter[25]) begin
                led_state <= {led_state[2:0], led_state[3]}; // Rotate left
                counter <= 26'd0;
            end
        end
    end

endmodule
EOF
fi

# Clean up TCL script
rm create_quartus_project.tcl

echo
echo "================================================"
echo "Copying Build System"
echo "================================================"

# Copy and customize Makefile for this project
if [[ -f "../Makefile.quartus" ]]; then
    print_info "Copying and customizing Makefile for project: $PROJECT_NAME"

    # Copy Makefile
    cp ../Makefile.quartus Makefile.tmp

    # Customize with project-specific settings
    sed -i "s|^# Project name - auto-detect from .qpf file or override with: make target PROJECT=yourproject|# Project name - configured during project creation (can still override with PROJECT=name)|" Makefile.tmp
    sed -i "s|^PROJECT ?= \$(basename \$(notdir \$(wildcard \*.qpf)))|# Project: $PROJECT_NAME (Board: $BOARD_TYPE)\n# FPGA: $FPGA_FAMILY $FPGA_DEVICE ($FPGA_PACKAGE, Speed: $SPEED_GRADE)\nPROJECT ?= $PROJECT_NAME|" Makefile.tmp

    # Move to final location
    mv Makefile.tmp Makefile

    print_success "Makefile configured for project: $PROJECT_NAME"
    print_info "Board: $BOARD_TYPE ($FPGA_DEVICE)"
else
    print_warning "Makefile.quartus not found in parent directory (../Makefile.quartus)"
    print_warning "You may need to manually copy the Makefile.quartus to this project"
fi

echo
echo "================================================"
echo "Project Created Successfully!"
echo "================================================"

print_success "Project: $PROJECT_NAME"
print_info "Location: $(pwd)"
print_info "Board Type: $BOARD_TYPE"

echo
echo "Generated Files:"
echo "  ${PROJECT_NAME}.qpf            - Quartus Project File (native generated)"
echo "  ${PROJECT_NAME}.qsf            - Quartus Settings File (native generated)"
echo "  sources/rtl/${PROJECT_NAME}.v  - RTL source file"
echo "  sources/constraints/           - Timing constraints directory"
echo "  Makefile                       - Build system (auto-detects project)"

echo
echo "Next Steps:"
echo "  1. make help                         # Show all available targets"
echo "  2. make quartus-all                  # Complete build flow"
echo "  3. make quartus-prog                 # Program FPGA (SRAM - temporary)"
echo "  4. make quartus-prog FLASH=1         # Program Flash (permanent)"
echo "  5. make quartus-gui                  # Open Quartus GUI"

echo
echo "The project uses Quartus Prime's native file generation for maximum compatibility!"

echo
echo "================================================"
echo "Native Quartus Project Setup Complete!"
echo "================================================"
