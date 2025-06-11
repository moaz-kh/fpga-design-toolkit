# fpga-design-toolkit

A comprehensive, open-source digital design toolkit for FPGA development with complete simulation workflows, project templates, and professional development environment setup.

## 🚀 Features

- **One-Command Project Creation**: Automated FPGA project initialization with proper directory structure
- **Complete Simulation Workflow**: Integrated Icarus Verilog simulation with GTKWave waveform viewing
- **Family-Based FPGA Support**: Extensible Makefile template with iCE40 implementation (ECP5, Xilinx, Intel ready)
- **Standard Modules Library**: Ready-to-use Verilog modules for common FPGA design patterns
- **Example Projects**: Auto-generated examples with comprehensive testbenches

## 📦 What's Included

### Core Components

| Component | Description |
|-----------|-------------|
| **`initiate_proj.sh`** | Project initialization script with interactive setup |
| **`Makefile.template`** | Family-based build system supporting complete FPGA workflows |
| **`STD_MODULES.v`** | Library of standard utility modules (synchronizer, edge detector, LED logic, SPI debounce) |



## 🏁 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/yourusername/fpga-design-toolkit.git
cd fpga-design-toolkit
chmod +x initiate_proj.sh
```

### 2. Create Your First Project
```bash
./initiate_proj.sh
```

The script will:
- ✅ Ask for your project name with validation
- ✅ Create a complete directory structure
- ✅ Generate an enhanced Makefile with FPGA workflow support
- ✅ Copy standard utility modules
- ✅ Optionally create example adder with comprehensive testbench
- ✅ Set up Git integration files (.gitignore, README)

### 3. Test the Example
```bash
cd your_project_name
make quick-test
```

This automatically:
- Updates the file list
- Runs simulation
- Opens GTKWave for waveform viewing

## 🔧 Requirements

### Essential Tools
```bash
# Ubuntu/Debian installation
sudo apt update
sudo apt install -y iverilog gtkwave yosys make git

# For iCE40 FPGA development (optional)
sudo apt install -y nextpnr-ice40 fpga-icestorm
```

### Recommended Setup
- **Linux**: Native Ubuntu 20.04+ or WSL2 with Ubuntu
- **VS Code**: With Remote-WSL extension and HDL language support
- **OSS CAD Suite**: For comprehensive toolchain (alternative to individual packages)

## 📁 Generated Project Structure

When you run `initiate_proj.sh`, you get:

```
your_project/
├── sources/              # Source code
│   ├── rtl/             # RTL source files (.v, .sv)
│   │   ├── STD_MODULES.v    # Standard utility modules
│   │   └── adder.v          # Example 8-bit adder (optional)
│   ├── tb/              # Testbenches
│   │   └── adder_tb.v       # Comprehensive example testbench
│   ├── include/         # Include files
│   ├── constraints/     # Timing/pin constraints
│   │   └── adder.pcf        # iCE40 constraint file (optional)
│   └── rtl_list.f       # File list with absolute paths
├── sim/                 # Simulation workspace
│   ├── waves/           # Waveform dumps (.vcd, .fst)
│   └── logs/            # Simulation logs
├── backend/             # Backend outputs
│   ├── synth/           # Synthesis outputs (.json)
│   ├── pnr/             # Place & route (.asc)
│   ├── bitstream/       # Final bitstreams (.bin)
│   └── reports/         # Timing/utilization reports
├── docs/                # Documentation
├── scripts/             # Build scripts
├── tests/               # Test vectors
├── vendor/              # Third-party IP
├── ip/                  # Custom IP cores
├── Makefile             # Enhanced build system
├── README.md            # Project documentation
└── .gitignore           # Git ignore rules
```

## 🛠️ Standard Modules Library

Every project includes `STD_MODULES.v` with production-ready modules:

### `synchronizer`
- **Purpose**: Multi-bit clock domain crossing
- **Parameters**: `WIDTH` (default: 3 bits)
- **Usage**: Synchronize signals between clock domains

```verilog
synchronizer #(.WIDTH(8)) sync_inst (
    .i_clk(clk),
    .i_rst_n(rst_n),
    .d_in(async_signal),
    .d_out(sync_signal)
);
```

### `edge_detector`
- **Purpose**: Detect positive and negative edges
- **Parameters**: `sync_sig` (0=async input, 1=sync input)
- **Outputs**: `o_pos_edge`, `o_neg_edge`

### `LED_logic`
- **Purpose**: Configurable LED blinker/flasher
- **Parameters**: `time_count`, `toggle_count` (in clock cycles)
- **Usage**: Status indication, error signaling

### `spi_interface_debounce`
- **Purpose**: Debounce SPI signals for reliable operation
- **Features**: 200MHz system clock, 2-cycle debounce
- **Signals**: SPI clock, MOSI, CS_n debouncing

## 🎯 FPGA Workflow Support

The generated Makefile provides complete FPGA development workflows:

### Simulation
```bash
make sim               # Run Icarus Verilog simulation
make waves             # Open GTKWave waveform viewer
make sim-waves         # Run simulation and open waveforms
```

### iCE40 FPGA Development
```bash
make synth-ice40       # Synthesize for iCE40
make pnr-ice40         # Place and route
make timing-ice40      # Timing analysis
make bitstream-ice40   # Generate bitstream
make prog-ice40        # Program device
make ice40             # Complete flow (synth+pnr+timing+bitstream)
```

### Generic Targets (delegate to current family)
```bash
make synth             # Synthesize for current family
make pnr               # Place and route
make bitstream         # Generate bitstream
make prog              # Program device
make all               # Complete workflow
```

### Utilities
```bash
make check-tools       # Verify tool installation
make update_list       # Update rtl_list.f file list
make status            # Show project status
make clean             # Clean generated files
make help              # Show all available targets
```



## 🔬 Example Projects

### Auto-Generated Adder
The initialization script can create a complete example project:

- **8-bit Ripple Carry Adder**: Production-ready design with full adder components
- **Comprehensive Testbench**: 600+ test cases including:
  - Basic functionality tests
  - Random testing (100 cases)
  - Exhaustive corner cases (512 cases)
  - Self-checking verification
  - Detailed pass/fail statistics
- **iCE40 Constraints**: Ready for NextPNR with iCEBreaker board pinout
- **Complete Documentation**: README with usage instructions

## 🧪 Testing and Validation

### One-Command Testing
```bash
make quick-test
```
Automatically:
1. Updates file list with current sources
2. Compiles simulation
3. Runs testbench
4. Opens waveform viewer
5. Reports results

### Tool Verification
```bash
make check-tools
```
Verifies installation of:
- Simulation tools (Icarus Verilog, GTKWave)
- Synthesis tools (Yosys)
- Family-specific tools (NextPNR, IceStorm)
- Programming tools (iceprog, openFPGALoader)

## 🏗️ Architecture and Extensibility

### Family-Based Design
The Makefile template uses a family-based architecture:
- **Current**: Full iCE40 implementation
- **Planned**: ECP5, Intel, Xilinx support
- **Extensible**: Easy addition of new FPGA families

### Professional Features
- **File List Management**: Automatic absolute path handling
- **Build Automation**: One-command workflows
- **Tool Detection**: Automatic verification and fallbacks
- **Cross-Platform**: Windows WSL2 and native Linux support

## 📖 Documentation

### Quick References
- Each generated project includes a detailed README
- Makefile help system: `make help`
- Tool verification: `make check-tools`
- Project status: `make status`

## 🤝 Contributing

This toolkit is designed for extensibility:

1. **New FPGA Families**: Add support following the iCE40 implementation pattern
2. **Additional Examples**: Extend the example generation system
3. **Tool Integration**: Add support for new EDA tools
4. **Documentation**: Improve guides and add new platform support

## 📄 License

Open source - see individual file headers for specific licenses.

---

**Ready to start your next FPGA project?** Run `./initiate_proj.sh` and get a complete, professional development environment in minutes!