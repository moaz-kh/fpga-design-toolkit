# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an FPGA Design Toolkit that provides a complete open-source FPGA development environment with one-command project setup. The toolkit focuses on rapid prototyping and educational FPGA development with comprehensive simulation and synthesis workflows.

## Project Setup Commands

### Initial Setup
```bash
# Install all FPGA tools (run once)
./install_fpga_tools.sh

# Clean reinstall if needed (complete cleanup + fresh install)
./install_fpga_tools.sh --reinstall

# Remove all installed tools (complete cleanup)
./install_fpga_tools.sh --cleanup

# Create a new FPGA project (interactive wrapper)
./initiate_proj.sh
```

Note: `initiate_proj.sh` is the main entry point - it presents an interactive menu to choose between open-source (OSS) or Intel Quartus toolchains.

### Advanced Installation Features
The installation script now includes comprehensive management capabilities:

**Installation Modes:**
- **oss** - Open-source FPGA tools only (OSS CAD Suite, Icarus Verilog, GTKWave)
- **quartus** - Docker + Quartus Prime Lite container (Docker installed automatically)
- **all** - Everything (OSS tools + Docker + Quartus)

**User-Friendly Input:**
- Flexible yes/no input handling (accepts: y, Y, yes, YES, Yes, n, N, no, NO, No, etc.)
- Clear prompts with [yes/no] format instead of [y/N]
- Consistent input validation across all prompts

**Environment Detection:**
- Automatically detects WSL2 or native Linux environments
- Adapts installation process based on environment
- No WSL-specific features on native Linux

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
- Cleans up apt packages and symlinks

### Generated Project Structure

**Open-Source Projects:**
```
your_project/
├── sources/rtl/        # Verilog RTL files + standard modules
├── sources/tb/         # Testbenches
├── sources/include/    # Include files and headers
├── sources/constraints/# Pin/timing constraints (.pcf, .xdc)
├── sim/               # Simulation outputs & waveforms
├── backend/           # Synthesis, place & route, bitstreams
├── Makefile           # Build system (from Makefile.oss)
└── README.md          # Project documentation
```

**Quartus Projects:**
```
your_project/
├── sources/rtl/        # Verilog RTL files
├── sources/constraints/# Timing constraints (.sdc)
├── sim/               # Simulation outputs & waveforms
├── output_files/      # Quartus outputs (.sof, .pof)
├── db/                # Quartus database
├── Makefile           # Build system (from Makefile.quartus)
├── *.qpf              # Quartus project file
└── *.qsf              # Quartus settings file (pin assignments)
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

**Open-Source Flow (iCE40/ECP5):**
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

**Quartus Flow (Intel/Altera):**
```bash
# Complete synthesis flow
make quartus-all       # map -> fit -> asm

# Individual steps
make quartus-map       # Analysis & Synthesis
make quartus-fit       # Place & Route
make quartus-sta       # Static Timing Analysis
make quartus-asm       # Generate bitstreams

# Programming
make quartus-prog              # Program FPGA SRAM (temporary)
make quartus-prog FLASH=1      # Program Flash (permanent)
make quartus-detect            # Detect connected FPGA

# Utilities
make quartus-gui       # Open Quartus GUI
make quartus-reports   # View all reports
make quartus-clean     # Clean build files
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

### Repository Structure

```
fpga-design-toolkit/
├── initiate_proj.sh          # User entry point - project creation
├── install_fpga_tools.sh     # User entry point - tool installation
├── README.md
├── CLAUDE.md
└── scripts/                  # Internal scripts & templates
    ├── create_oss_project.sh
    ├── create_quartus_project.sh
    ├── install_docker.sh
    ├── install_quartus_docker.sh
    ├── setup-usb-fpga.sh
    ├── Makefile.oss
    ├── Makefile.quartus
    └── STD_MODULES.v
```

### Core Components

1. **initiate_proj.sh** - Main entry point wrapper script:
   - Interactive menu to choose toolchain (OSS or Quartus)
   - Calls appropriate project creation script from `scripts/` directory
   - Unified user experience for both toolchains

2. **scripts/create_oss_project.sh** - Open-source project creation script:
   - Creates complete directory structure for OSS flow
   - Copies standard modules (STD_MODULES.v) to each project
   - Generates example 8-bit adder with comprehensive testbench
   - Sets up constraint files for iCE40
   - Uses scripts/Makefile.oss template

3. **scripts/create_quartus_project.sh** - Quartus project creation script:
   - Creates Quartus-specific directory structure
   - Supports multiple boards (TEI0010, DE10-Lite, DE2-115, DE10-Standard)
   - Generates .qpf, .qsf with pin assignments and timing constraints
   - Creates customized Makefile from scripts/Makefile.quartus template
   - RTL template with board-specific LED blinker example

4. **scripts/Makefile.oss** - OSS toolchain Makefile template:
   - Family-based FPGA architecture (iCE40, ECP5)
   - Auto-detection of available EDA tools
   - Complete simulation to bitstream workflow
   - Runtime parameter override system (conditional assignment with `?=`)
   - Module discovery (`list-modules` target)

5. **scripts/Makefile.quartus** - Quartus toolchain Makefile template:
   - Docker-based Quartus Prime Lite workflow
   - Auto-detection of project and programming files
   - Automatic USB setup prompts for WSL2
   - SRAM and Flash programming support
   - GUI support and comprehensive reporting

6. **scripts/setup-usb-fpga.sh** - WSL2 USB passthrough automation:
   - Interactive USB device detection and binding
   - Automatic usbipd-win setup verification
   - Hardware ID-based device attachment
   - FPGA detection verification

7. **scripts/STD_MODULES.v** - Standard Verilog modules library:
   - `synchronizer` - Clock domain crossing with parameterizable width
   - `edge_detector` - Rising/falling edge detection with optional sync
   - `LED_logic` - Configurable LED blinking controller
   - `spi_interface_debounce` - SPI signal debouncing

8. **install_fpga_tools.sh** - Advanced tool installation and management:
   - Interactive mode selection (OSS, Quartus, or All)
   - Three installation modes: oss, quartus (includes Docker), all
   - Environment detection (WSL2 or native Linux)
   - OSS CAD Suite (Yosys, NextPNR, icestorm tools) with write protection
   - Icarus Verilog and GTKWave
   - Docker engine installation (automatic with Quartus)
   - Quartus Prime Lite in Docker (raetro/quartus:21.1)
   - Complete cleanup and reinstall functionality (`--cleanup`, `--reinstall`)
   - Flexible yes/no input handling (y/Y/yes/YES/n/N/no/NO accepted)
   - Installation verification and fallback options 

### FPGA Family Support

**Open-Source Toolchain:**
- **iCE40** - Full synthesis, P&R, timing, programming support (Lattice)
- **ECP5** - Framework ready (Lattice)

**Quartus Toolchain:**
- **Intel MAX 10** - Full support (TEI0010, DE10-Lite boards)
- **Cyclone IV E** - Full support (DE2-115 board)
- **Cyclone V SX SoC** - Full support (DE10-Standard board)
- **Other Intel/Altera** - Framework ready for extension

### Supported Development Boards

**Open-Source:**
- Generic iCE40 boards (UP5K, HX8K, etc.)
- Generic ECP5 boards

**Quartus:**
- **TEI0010** - Intel MAX 10 (10M08SAU169C8GES) - Default
- **DE10-Lite** - Intel MAX 10 (10M50DAF484C7G)
- **DE2-115** - Cyclone IV E (EP4CE115F29C7N)
- **DE10-Standard** - Cyclone V SX SoC (5CSXFC6D6F31C6N)

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
