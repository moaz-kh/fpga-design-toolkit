# FPGA Design Toolkit

**Complete open-source FPGA development environment with one-command project setup**

🚀 **Get from zero to working FPGA design in under 5 minutes**

## What You Get

✅ **Instant project setup** - Complete FPGA project structure in one command  
✅ **Ready-to-use modules** - Synchronizers, edge detectors, SPI debounce, LED controllers  
✅ **Complete simulation workflow** - Icarus Verilog + GTKWave integration  
✅ **Full FPGA flow** - Synthesis → Place & Route → Bitstream → Programming  
✅ **Working examples** - 8-bit adder with 600+ test cases  

## Quick Start

### 1. Install Tools (Ubuntu/WSL2)
```bash
git clone https://github.com/moaz-kh/fpga-design-toolkit.git
cd fpga-design-toolkit
chmod +x install_fpga_tools.sh
./install_fpga_tools.sh    # Includes automatic WSL update check
```

### 2. Create Your First Project
```bash
./initiate_fpga_proj.sh
```

### 3. Test Everything Works
```bash
cd your_project_name
make quick-test
```

**Done!** You now have a working FPGA project with simulation and synthesis support.

## What Gets Created

```
your_project/
├── sources/rtl/        # Your Verilog files + standard modules
├── sources/tb/         # Testbenches  
├── sim/               # Simulation outputs & waveforms
├── backend/           # Synthesis, place & route, bitstreams
├── Makefile           # Complete build system
└── README.md          # Project documentation
```

## Key Features

### 🔧 Professional Build System
```bash
make sim           # Run simulation
make waves         # View waveforms  
make synth-ice40   # Synthesize for iCE40
make ice40         # Complete FPGA flow
make prog-ice40    # Program device
```

### 📚 Standard Modules Library
Ready-to-use Verilog modules included in every project:
- **synchronizer** - Clock domain crossing
- **edge_detector** - Rising/falling edge detection  
- **LED_logic** - Configurable LED controller
- **spi_interface_debounce** - Clean SPI signal handling

### 🎯 FPGA Family Support
- **iCE40** - Full support (Lattice)
- **ECP5** - Ready for implementation  
- **Xilinx/Intel** - Framework ready

### 🧪 Example Projects
Auto-generated 8-bit adder with:
- Complete testbench (600+ test cases)
- iCE40 constraint files
- Self-checking verification
- Ready for hardware implementation

## Supported Tools

**Simulation**: Icarus Verilog, GTKWave, Verilator  
**Synthesis**: Yosys  
**Place & Route**: NextPNR  
**Programming**: iceprog, openFPGALoader  

## Requirements

- **Linux**: Ubuntu 20.04+ or WSL2  
- **RAM**: 4GB+ (8GB recommended)  
- **Disk**: 10GB+ free space  
- **WSL**: Automatic update check ensures latest version for optimal performance  

## Use Cases

✨ **Learning FPGA design** - Get started with working examples  
✨ **Rapid prototyping** - Quick project setup and testing  
✨ **Open-source development** - No license fees or vendor lock-in  
✨ **Educational projects** - Complete workflow from simulation to hardware  
✨ **Commercial projects** - Production-ready for small to medium designs  

## Installation Options

**Option 1: Automatic (Recommended)**
```bash
./install_fpga_tools.sh  # Installs OSS CAD Suite + essentials + WSL updates
```

**Option 2: Manual**
```bash
sudo apt install iverilog gtkwave yosys nextpnr-ice40 fpga-icestorm
```

## Documentation

- **Quick Start**: Run `./initiate_fpga_proj.sh` and follow prompts
- **Makefile Help**: `make help` in any generated project  
- **Tool Check**: `make check-tools` to verify installation
- **Project Status**: `make status` to see build state

## Examples & Tutorials

### Create LED Blinker
```verilog
LED_logic #(.time_count(50000000), .toggle_count(25000000)) 
    led_inst (.i_clk(clk), .i_rst_n(rst_n), .i_sig(button), .o_led(led));
```

### Add Clock Domain Crossing
```verilog
synchronizer #(.WIDTH(8)) sync_inst 
    (.i_clk(clk), .i_rst_n(rst_n), .d_in(async_data), .d_out(sync_data));
```

## Contributing

🤝 **Add FPGA families** - Extend Makefile template  
🤝 **New examples** - Add to initiate_proj.sh  
🤝 **Tool integration** - Support more EDA tools  
🤝 **Documentation** - Improve guides and tutorials  

## License

MIT License - Use freely for personal and commercial projects

---

**Ready to start designing?** 
```bash
git clone https://github.com/moaz-kh/fpga-design-toolkit.git && cd fpga-design-toolkit && ./install_fpga_tools.sh
```

**Keywords**: FPGA development, open source EDA tools, Verilog design, digital design toolkit, iCE40 development, FPGA simulation, hardware design automation, RTL design, FPGA synthesis, nextpnr, yosys
