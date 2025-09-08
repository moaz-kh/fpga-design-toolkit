# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an FPGA Design Toolkit that provides a complete open-source FPGA development environment with one-command project setup. The toolkit focuses on rapid prototyping and educational FPGA development with comprehensive simulation and synthesis workflows.

## Project Setup Commands

### Initial Setup
```bash
# Install all FPGA tools (run once) - includes WSL update check
./install_fpga_tools.sh

# Clean reinstall if needed (complete cleanup + fresh install)
./install_fpga_tools.sh --reinstall

# Remove all installed tools (complete cleanup)
./install_fpga_tools.sh --cleanup

# Create a new FPGA project
./initiate_fpga_proj.sh
```

Note: The main script is `initiate_fpga_proj.sh` not `initiate_proj.sh` as mentioned in the README.

### Advanced Installation Features
The installation script now includes comprehensive management capabilities:

**WSL Version Management:**
- Automatically detects current WSL version
- Offers to update to latest WSL version for better performance
- Safe update process that doesn't affect your Linux distribution
- User confirmation required before any updates
- Graceful fallback if update fails or isn't needed

**Installation Protection:**
- Write-protects OSS CAD Suite installation to prevent accidental modification
- Creates compatibility symlinks for VPI modules
- Comprehensive verification of all installed tools
- Automatic fallback to apt packages if manual download fails

**Cleanup and Reinstall:**
- `--cleanup` option removes all installed tools completely
- `--reinstall` option performs cleanup followed by fresh installation
- Safely restores write permissions before removal
- Removes PATH entries from ~/.bashrc with backup
- Cleans up apt packages, Python packages, and symlinks

### Generated Project Structure
When a new project is created, it follows this structure:
```
your_project/
├── sources/rtl/        # Verilog RTL files + standard modules
├── sources/tb/         # Testbenches
├── sources/constraints/# Pin/timing constraints (.pcf, .lpf, .xdc)
├── sim/               # Simulation outputs & waveforms
├── backend/           # Synthesis, place & route, bitstreams
└── Makefile           # Complete build system
```

## Development Commands

All commands below should be run within a generated project directory.

### Basic Development Workflow
```bash
# Update file list and run simulation with waveforms
make quick-test

# Update RTL file list
make update_list

# Run simulation only
make sim

# View waveforms (after simulation)
make waves

# Run simulation and open waveforms
make sim-waves
```

### FPGA Development Workflow
```bash
# Complete FPGA flow for current family (default: ice40)
make all                # synth -> pnr -> timing -> bitstream

# Individual steps
make synth             # Synthesize for current FPGA family
make pnr               # Place and route
make timing            # Generate timing report
make bitstream         # Generate bitstream
make prog              # Program device

# Family-specific commands (iCE40)
make synth-ice40       # Synthesize for iCE40
make pnr-ice40         # Place and route for iCE40
make timing-ice40      # iCE40 timing analysis
make bitstream-ice40   # Generate iCE40 bitstream
make prog-ice40        # Program iCE40 device
make ice40             # Complete iCE40 flow
```

### Utility Commands
```bash
# Check project and tool status
make status

# Check if all tools are installed
make check-tools

# Show all available targets
make help

# List available RTL modules and testbenches
make list-modules

# Clean generated files
make clean         # Clean build outputs
make clean-all     # Clean everything including logs
```

## Runtime Configuration

The Makefile template supports runtime parameter overrides, allowing flexible configuration without modifying files:

### Configurable Parameters
- `TOP_MODULE` - Override top module (default: adder)
- `TESTBENCH` - Override testbench module (default: adder_tb)
- `FPGA_FAMILY` - Override FPGA family (default: ice40)
- `FPGA_DEVICE` - Override FPGA device (default: up5k)
- `FPGA_PACKAGE` - Override FPGA package (default: sg48)
- `RTL_DIR` - Override RTL source directory (default: sources/rtl)
- `TB_DIR` - Override testbench directory (default: sources/tb)
- `SIM_DIR` - Override simulation directory (default: sim)
- `FILELIST` - Override file list location (default: sources/rtl_list.f)

### Usage Examples
```bash
# Use different top module and testbench
make sim TOP_MODULE=counter TESTBENCH=counter_tb

# Use different FPGA device and package
make ice40 FPGA_DEVICE=hx8k FPGA_PACKAGE=ct256

# Use custom directory structure
make sim RTL_DIR=my_rtl TB_DIR=my_testbenches

# Combine multiple overrides
make all TOP_MODULE=processor TESTBENCH=processor_tb FPGA_DEVICE=up5k

# List modules in custom directories
make list-modules RTL_DIR=custom_rtl TB_DIR=custom_tb
```

## Architecture and Code Structure

### Core Components

1. **Makefile.template** - Template for generated project Makefiles with:
   - Family-based FPGA architecture (extensible for iCE40, ECP5, Intel, Xilinx)
   - Auto-detection of available EDA tools
   - Complete simulation to bitstream workflow
   - Runtime parameter override system (conditional assignment with `?=`)
   - Module discovery (`list-modules` target)
   - Project status monitoring and comprehensive error handling

2. **STD_MODULES.v** - Standard Verilog modules library:
   - `synchronizer` - Clock domain crossing with parameterizable width
   - `edge_detector` - Rising/falling edge detection with optional sync
   - `LED_logic` - Configurable LED blinking controller
   - `spi_interface_debounce` - SPI signal debouncing

3. **initiate_fpga_proj.sh** - Project creation script that:
   - Creates complete directory structure
   - Copies standard modules to each project
   - Generates example 8-bit adder with comprehensive testbench
   - Sets up constraint files for iCE40

4. **install_fpga_tools.sh** - Advanced tool installation and management script for:
   - WSL version checking and updating (automatic detection and safe updates)
   - OSS CAD Suite (Yosys, NextPNR, icestorm tools) with write protection
   - Icarus Verilog and GTKWave
   - Python packages (CocoTB, Amaranth, FuseSoC)
   - Complete cleanup and reinstall functionality (`--cleanup`, `--reinstall`)
   - Installation verification and fallback options
   - Comprehensive error handling and user guidance 

### FPGA Family Support

- **Primary**: iCE40 (full synthesis, P&R, timing, programming support)
- **Framework ready**: ECP5, Intel, Xilinx (Makefile structure prepared for extension)

### Default Configuration

- **FPGA Family**: ice40
- **Default Device**: up5k
- **Default Package**: sg48
- **Top Module**: adder (in generated projects)
- **Testbench**: adder_tb

## Standard Modules Usage

The toolkit includes ready-to-use Verilog modules available in every project:

```verilog
// Clock domain crossing
synchronizer #(.WIDTH(8)) sync_inst (
    .i_clk(clk), .i_rst_n(rst_n), 
    .d_in(async_data), .d_out(sync_data)
);

// LED controller
LED_logic #(.time_count(50000000), .toggle_count(25000000)) 
    led_inst (.i_clk(clk), .i_rst_n(rst_n), .i_sig(button), .o_led(led));
```

## Supported Tools

- **Simulation**: Icarus Verilog, GTKWave, Verilator
- **Synthesis**: Yosys
- **Place & Route**: NextPNR (ice40, ecp5 variants)
- **Programming**: iceprog, openFPGALoader
- **Timing**: icetime

The Makefile automatically detects available tools and provides helpful error messages for missing dependencies.

## Workflow Flexibility

The toolkit is designed for maximum flexibility:

### Multi-Module Projects
- Use `make list-modules` to discover available modules and testbenches
- Switch between different top modules and testbenches using runtime parameters
- Support for hierarchical designs with multiple testbench levels

### Custom Directory Structures
- Override default directory paths for non-standard project layouts
- Support for multiple RTL source directories
- Flexible testbench organization

### Multi-Device Support
- Easy switching between FPGA devices and packages
- Family-extensible architecture for adding new FPGA families
- Runtime device selection for the same design

### Development Modes
- Quick testing with `make quick-test`
- Incremental workflow (sim → synth → pnr → timing → bitstream)
- Complete flow automation with `make all` or family-specific shortcuts

This flexibility makes the toolkit suitable for both educational projects and production development workflows.
