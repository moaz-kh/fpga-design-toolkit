#!/bin/bash
# Digital Design Project Initialization Script
# Enhanced with simulation capabilities and auto-example generation
# Usage: bash initiate_proj_script.sh

set -e  # Exit on any error

echo "================================================"
echo "Digital Design Project Initialization"
echo "================================================"
echo "Welcome to the enhanced FPGA project setup wizard!"

# Check if Makefile.template exists
if [[ ! -f "Makefile.template" ]]; then
    echo "ERROR: Makefile.template not found in current directory!"
    echo "Please ensure Makefile.template is in the same directory as this script."
    exit 1
fi

# Get project name with validation
while true; do
    echo
    echo "Enter your project name:"
    echo "(alphanumeric, underscore, hyphen only)"
    read -p "Project Name: " PROJECT_NAME
    
    # Check if empty
    if [[ -z "$PROJECT_NAME" ]]; then
        echo "ERROR: Project name cannot be empty."
        continue
    fi
    
    # Check for valid characters
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid project name. Use only letters, numbers, underscore, and hyphen."
        continue
    fi
    
    # Check if directory already exists
    if [[ -d "$PROJECT_NAME" ]]; then
        echo "ERROR: Directory '$PROJECT_NAME' already exists!"
        read -p "Do you want to use a different name? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Exiting..."
            exit 1
        fi
        continue
    fi
    
    # Valid project name
    echo "Valid project name: $PROJECT_NAME"
    break
done

# Confirmation
echo
echo "Project Configuration:"
echo "  Name: $PROJECT_NAME"
echo "  Enhanced Features: [OK] Simulation, [OK] Waveforms, [OK] Auto-examples"
echo
read -p "Proceed with project creation? [Y/n]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Project creation cancelled."
    exit 0
fi

echo
echo "================================================"
echo "Creating Project Directory Structure"
echo "================================================"

# Create main project directory
echo "Creating main project directory: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"

# Create core source directories
echo "Creating source directories..."
mkdir -p "$PROJECT_NAME/sources/rtl"
echo "  -> sources/rtl (RTL source files)"

mkdir -p "$PROJECT_NAME/sources/tb" 
echo "  -> sources/tb (Testbench files)"

mkdir -p "$PROJECT_NAME/sources/include"
echo "  -> sources/include (Header files and includes)"

mkdir -p "$PROJECT_NAME/sources/constraints"
echo "  -> sources/constraints (Timing and pin constraints)"

# Create simulation directories
echo "Creating simulation directories..."
mkdir -p "$PROJECT_NAME/sim"
echo "  -> sim (Simulation workspace)"

mkdir -p "$PROJECT_NAME/sim/waves"
echo "  -> sim/waves (Waveform dumps VCD/FST)"

mkdir -p "$PROJECT_NAME/sim/logs"
echo "  -> sim/logs (Simulation log files)"

# Create backend directories
echo "Creating backend directories..."
mkdir -p "$PROJECT_NAME/backend/synth"
echo "  -> backend/synth (Synthesis outputs)"

mkdir -p "$PROJECT_NAME/backend/pnr"
echo "  -> backend/pnr (Place and route outputs)"

mkdir -p "$PROJECT_NAME/backend/bitstream"
echo "  -> backend/bitstream (Final bitstreams)"

mkdir -p "$PROJECT_NAME/backend/reports"
echo "  -> backend/reports (Timing and utilization reports)"

# Create documentation and tool directories
echo "Creating documentation and tool directories..."
mkdir -p "$PROJECT_NAME/docs"
echo "  -> docs (Project documentation)"

mkdir -p "$PROJECT_NAME/scripts"
echo "  -> scripts (Build and automation scripts)"

mkdir -p "$PROJECT_NAME/tests"
echo "  -> tests (Test vectors and verification)"

# Create vendor and IP directories
echo "Creating vendor and IP directories..."
mkdir -p "$PROJECT_NAME/vendor"
echo "  -> vendor (Third-party IP cores)"

mkdir -p "$PROJECT_NAME/ip"
echo "  -> ip (Custom IP cores)"

echo
echo "================================================"
echo "Creating Template Files"
echo "================================================"

# Create enhanced Makefile from template
echo "Creating enhanced Makefile from template..."
if [[ -f "Makefile.template" ]]; then
    # Copy template and replace placeholder
    sed "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" Makefile.template > "$PROJECT_NAME/Makefile"
    echo "Makefile created successfully"
else
    echo "ERROR: Makefile.template not found!"
    exit 1
fi

# Create .gitignore
echo "Creating .gitignore..."
cat > "$PROJECT_NAME/.gitignore" << 'EOF'
# Simulation outputs
*.vvp
*.vcd
*.fst
*.lxt
*.lxt2
*.ghw

# Synthesis outputs
*.json
*.asc
*.bin
*.rpt

# Log files
*.log
*.tmp

# OS specific
.DS_Store
Thumbs.db

# Editor specific
*.swp
*.swo
*~
.vscode/
.idea/

# Build outputs
build/
dist/

# Vendor specific
vendor/*/
!vendor/.gitkeep
EOF

# Create README.md
echo "Creating README.md..."
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

## Project Overview
Enhanced FPGA project with comprehensive simulation and verification capabilities.

## Features
- [OK] **Complete simulation workflow** with Icarus Verilog
- [OK] **Waveform viewing** with GTKWave  
- [OK] **File list management** using rtl_list.f
- [OK] **Auto-example generation** with 8-bit adder
- [OK] **Comprehensive testbenches** with self-checking
- [OK] **Tool detection and verification**
- [OK] **One-command testing** with \`make quick-test\`

## Directory Structure
\`\`\`
$PROJECT_NAME/
├── sources/           # Source code
│   ├── rtl/          # RTL source files (.v, .sv)
│   ├── tb/           # Testbenches  
│   ├── include/      # Include files
│   ├── constraints/  # Timing/pin constraints (.pcf, .xdc)
│   └── rtl_list.f    # File list with absolute paths
├── sim/              # Simulation workspace
│   ├── waves/        # Waveform dumps (.vcd, .fst)
│   └── logs/         # Log files
├── backend/          # Backend outputs
│   ├── synth/        # Synthesis outputs (.json)
│   ├── pnr/          # Place & route (.asc)
│   ├── bitstream/    # Final bitstreams (.bin)
│   └── reports/      # Timing/utilization reports
├── docs/             # Documentation
├── scripts/          # Build scripts
├── tests/            # Test vectors
├── vendor/           # Third-party IP
└── ip/               # Custom IP cores
\`\`\`

## Quick Start Guide

### 1. Check tool availability
\`\`\`bash
make check-tools
\`\`\`

### 2. Create and test example adder
\`\`\`bash
make quick-test
\`\`\`
This will:
- Create example adder RTL (\`sources/rtl/adder.v\`)
- Create comprehensive testbench (\`sources/tb/adder_tb.v\`)
- Update file list
- Run simulation
- Open waveforms in GTKWave

### 3. Simulation workflow
\`\`\`bash
# Update file list after adding new files
make update_list

# Run simulation only
make sim

# Run simulation and view waveforms
make sim-waves

# View existing waveforms
make waves
\`\`\`

### 4. Project status
\`\`\`bash
make status          # Show project status
make help            # Show all available targets
\`\`\`

## Development Workflow

### Adding New RTL Modules
1. Add Verilog files to \`sources/rtl/\`
2. Add testbenches to \`sources/tb/\` (named \`*_tb.v\`)
3. Run \`make update_list\` to refresh file list
4. Test with \`make sim-waves\`

### Synthesis Workflow
\`\`\`bash
# Basic synthesis with Yosys
make synth

# For FPGA-specific synthesis, customize the synth target in Makefile
\`\`\`

## Example Adder Features
The auto-generated adder example includes:
- **8-bit ripple carry adder** with carry input/output
- **Modular design** using full adder components
- **Comprehensive testbench** with 600+ test cases:
  - Basic functionality tests
  - Random testing (100 cases)
  - Exhaustive corner cases (512 cases)
  - Self-checking verification
  - Detailed pass/fail statistics

## Available Make Targets

### Simulation
- \`make sim\` - Compile and run simulation
- \`make waves\` - Open waveform viewer
- \`make sim-waves\` - Run simulation and open waveforms

### Examples
- \`make create-example\` - Create adder example files
- \`make quick-test\` - Full automated test

### Utilities
- \`make update_list\` - Update rtl_list.f file list
- \`make check-tools\` - Verify tool installation
- \`make status\` - Show project status
- \`make clean\` - Clean generated files
- \`make help\` - Show all targets

## Tools Required
- **Icarus Verilog** (simulation): \`sudo apt install iverilog\`
- **GTKWave** (waveform viewer): \`sudo apt install gtkwave\`
- **Yosys** (synthesis): \`sudo apt install yosys\`
- **Make** (build automation): Usually pre-installed

## File Management
- \`rtl_list.f\` contains absolute paths to all source files
- Run \`make update_list\` after adding/removing files
- Many EDA tools support file lists with \`-f\` option

## Troubleshooting
- Run \`make check-tools\` to verify tool installation
- Check \`sim/logs/simulation.log\` for simulation output
- Ensure files are added to correct directories before \`make update_list\`

Generated with enhanced initiate_proj_script.sh
EOF

# Create initial rtl_list.f
echo "Creating initial rtl_list.f..."
cat > "$PROJECT_NAME/sources/rtl_list.f" << EOF
# RTL and Testbench File List
# Generated by initiate_proj_script.sh
# Date: $(date)
# Project: $PROJECT_NAME

# RTL Source Files
# (Run 'make update_list' to populate with actual files)

# Testbench Files
# (Run 'make update_list' to populate with actual files)

# Usage:
# Many tools support file lists with the -f option:
# iverilog -f sources/rtl_list.f -o simulation.vvp
# yosys -f sources/rtl_list.f
EOF

# Create .gitkeep files for empty directories
echo "Creating .gitkeep files for empty directories..."
touch "$PROJECT_NAME/sources/include/.gitkeep"
touch "$PROJECT_NAME/sources/constraints/.gitkeep"
touch "$PROJECT_NAME/vendor/.gitkeep"
touch "$PROJECT_NAME/ip/.gitkeep"

echo
echo "================================================"
echo "Auto-Example Generation"
echo "================================================"

# Ask user if they want example files
echo "Do you want to create example adder RTL and testbench files?"
echo "This will create:"
echo "  • sources/rtl/adder.v        (8-bit ripple carry adder)"
echo "  • sources/tb/adder_tb.v      (comprehensive testbench)"
echo
read -p "Create example files? [Y/n]: " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo
    echo "Creating example adder files..."
    
    # Create the adder RTL file
    echo "Creating adder.v..."
    cat > "$PROJECT_NAME/sources/rtl/adder.v" << 'EOF'
// 8-bit Ripple Carry Adder with Carry Out
// Auto-generated example for digital design project

module adder(
    input  [7:0] a,      // First operand
    input  [7:0] b,      // Second operand
    input        cin,    // Carry input
    output [7:0] sum,    // Sum output
    output       cout    // Carry output
);

    // Internal carry signals
    wire [6:0] carry;

    // Full adder instances
    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(cin),     .sum(sum[0]), .cout(carry[0]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(carry[0]), .sum(sum[1]), .cout(carry[1]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(carry[1]), .sum(sum[2]), .cout(carry[2]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(carry[2]), .sum(sum[3]), .cout(carry[3]));
    full_adder fa4 (.a(a[4]), .b(b[4]), .cin(carry[3]), .sum(sum[4]), .cout(carry[4]));
    full_adder fa5 (.a(a[5]), .b(b[5]), .cin(carry[4]), .sum(sum[5]), .cout(carry[5]));
    full_adder fa6 (.a(a[6]), .b(b[6]), .cin(carry[5]), .sum(sum[6]), .cout(carry[6]));
    full_adder fa7 (.a(a[7]), .b(b[7]), .cin(carry[6]), .sum(sum[7]), .cout(cout));

endmodule

// Full Adder Module
module full_adder(
    input  a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
EOF

    # Create the testbench file
    echo "Creating adder_tb.v..."
    cat > "$PROJECT_NAME/sources/tb/adder_tb.v" << 'EOF'
// Testbench for 8-bit Adder
// Auto-generated comprehensive test suite

module adder_tb;

    // Testbench signals
    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] sum;
    wire       cout;

    // Expected results for verification
    reg  [8:0] expected;
    integer i, j, k;
    integer pass_count, fail_count;

    // Instantiate the adder
    adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("sim/waves/adder_waves.vcd");
        $dumpvars(0, adder_tb);

        // Initialize variables
        a = 0;
        b = 0;
        cin = 0;
        pass_count = 0;
        fail_count = 0;

        $display("=== Adder Testbench Started ===");
        $display("Time\t\ta\tb\tcin\tsum\tcout\texpected\tstatus");
        $display("------------------------------------------------------------");

        // Test 1: Basic addition without carry
        #10;
        a = 8'h0F; b = 8'h10; cin = 0;
        #10 check_result("Basic Add");

        // Test 2: Addition with carry input
        a = 8'h0F; b = 8'h10; cin = 1;
        #10 check_result("Add with Cin");

        // Test 3: Maximum values
        a = 8'hFF; b = 8'hFF; cin = 1;
        #10 check_result("Max Values");

        // Test 4: Zero addition
        a = 8'h00; b = 8'h00; cin = 0;
        #10 check_result("Zero Add");

        // Test 5: Overflow condition
        a = 8'h80; b = 8'h80; cin = 0;
        #10 check_result("Overflow");

        // Test 6: Random comprehensive testing
        $display("--- Starting random tests ---");
        for (i = 0; i < 100; i = i + 1) begin
            a = $random;
            b = $random;
            cin = $random & 1;
            #10 check_result("Random");
        end

        // Test 7: Exhaustive corner cases
        $display("--- Testing corner cases ---");
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = j;
                b = (i == 0) ? 8'h00 : 8'hFF;
                cin = i;
                #1 check_result("Corner");
            end
        end

        // Display final results
        $display("=== Test Summary ===");
        $display("Total Passed: %0d", pass_count);
        $display("Total Failed: %0d", fail_count);
        $display("Success Rate: %0.1f%%", (pass_count * 100.0) / (pass_count + fail_count));

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end

        $display("=== Testbench Complete ===");
        $finish;
    end

    // Task to check results
    task check_result;
        input [80*8-1:0] test_name;
        begin
            expected = a + b + cin;
            if ({cout, sum} == expected) begin
                $display("%0t\t%h\t%h\t%b\t%h\t%b\t%h\t\tPASS - %s", 
                    $time, a, b, cin, sum, cout, expected, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("%0t\t%h\t%h\t%b\t%h\t%b\t%h\t\tFAIL - %s", 
                    $time, a, b, cin, sum, cout, expected, test_name);
                $display("ERROR: Expected {cout,sum} = %h, Got {cout,sum} = %h", 
                    expected, {cout, sum});
                fail_count = fail_count + 1;
            end
        end
    endtask

endmodule
EOF

    echo "Example files created successfully!"
    echo "Created: sources/rtl/adder.v"
    echo "Created: sources/tb/adder_tb.v"
    
    # Auto-update the file list
    echo "Updating file list..."
    cd "$PROJECT_NAME"
    make update_list > /dev/null 2>&1
    cd ..
    
    echo
    echo "Ready to test! Try these commands:"
    echo "  cd $PROJECT_NAME"
    echo "  make sim-waves      # Run simulation and view waveforms"
    echo "  make quick-test     # Full automated test"
    
    EXAMPLE_CREATED=true
else
    echo "Skipping example file creation."
    EXAMPLE_CREATED=false
fi

echo
echo "================================================"
echo "Project Created Successfully!"
echo "================================================"

echo "Project: $PROJECT_NAME"
echo "Location: $(pwd)/$PROJECT_NAME"

echo
echo "Next Steps:"
if [[ "$EXAMPLE_CREATED" == "true" ]]; then
    echo "  1. cd $PROJECT_NAME"
    echo "  2. make sim-waves        # Test the example adder"
    echo "  3. make status           # Check project status"
    echo "  4. View waveforms in GTKWave"
    echo "  5. Modify adder.v and adder_tb.v as needed"
else
    echo "  1. cd $PROJECT_NAME"
    echo "  2. Create your RTL files in sources/rtl/"
    echo "  3. Create your testbenches in sources/tb/"
    echo "  4. make update_list      # Update file list"
    echo "  5. make sim-waves        # Run simulation"
fi

echo
echo "Available Make Targets:"
echo "  make help           # Show all available targets"
echo "  make check-tools    # Verify tool installation"
echo "  make create-example # Create adder example (if not done)"
echo "  make quick-test     # Full automated test"
echo "  make status         # Project status"

echo
echo "Documentation:"
echo "  README.md contains detailed workflow instructions"
echo "  Makefile has comprehensive help: make help"

echo
echo "Project setup complete!"
