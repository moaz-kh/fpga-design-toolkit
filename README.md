# FPGA Design Toolkit

**Your friendly, complete FPGA development environment with one-command project setup**

🚀 **Get from zero to working FPGA design in under 5 minutes**

Whether you're learning digital design, prototyping a new idea, or building production FPGA projects, this toolkit gets you up and running fast—no license fees, no vendor lock-in, just pure open-source goodness.

## What You Get

✅ **Instant project setup** - Complete FPGA project structure in one command
✅ **Flexible toolchain options** - Choose open-source tools, Intel Quartus in Docker, or both!
✅ **Ready-to-use modules** - Synchronizers, edge detectors, SPI debounce, LED controllers
✅ **Complete simulation workflow** - Icarus Verilog + GTKWave integration
✅ **Full FPGA flow** - Synthesis → Place & Route → Bitstream → Programming
✅ **Working examples** - 8-bit adder with 600+ test cases  

## Quick Start

### 1. Clone and Install
```bash
git clone https://github.com/moaz-kh/fpga-design-toolkit.git
cd fpga-design-toolkit
chmod +x install_fpga_tools.sh
./install_fpga_tools.sh    # Interactive menu lets you choose what to install!
```

**The installer will ask you what you want to install:**
1. **Open-source FPGA tools** (Yosys, NextPNR, Icarus Verilog, GTKWave) - Perfect for iCE40 and open FPGA development
2. **Docker engine** - If you just need Docker
3. **Quartus Prime Lite in Docker** - Intel/Altera FPGA toolchain, free and containerized
4. **Everything** - All tools for maximum flexibility

> 💡 **Tip**: Not sure? Start with option 1 (open-source tools) - it's the fastest way to get started!

### 2. Create Your First Project
```bash
./initiate_fpga_proj.sh
# Give your project a name, and you're ready to go!
```

### 3. Test Everything Works
```bash
cd your_project_name
make quick-test
```

**Done!** You now have a working FPGA project with simulation and synthesis support. Time to make some digital magic! ✨

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
make waves         # View waveforms (auto-loads session if available)
make save-session  # Create GTKWave session template
make synth-ice40   # Synthesize for iCE40
make ice40         # Complete FPGA flow
make prog-ice40    # Program device
```

### 🌊 Enhanced Waveform Viewing
Professional GTKWave integration with session management:
- **Auto-session loading** - Save signal arrangements, colors, and groupings
- **Template generation** - `make save-session` creates initial session file
- **Persistent layouts** - Your waveform setup is restored automatically
- **Quick workflow** - `make sim-waves` for simulation + waveform viewing

### 📚 Standard Modules Library
Ready-to-use Verilog modules included in every project:
- **synchronizer** - Clock domain crossing
- **edge_detector** - Rising/falling edge detection  
- **LED_logic** - Configurable LED controller
- **spi_interface_debounce** - Clean SPI signal handling

### 🎯 FPGA Family Support
- **iCE40** - Full open-source support (Lattice) - synth, P&R, bitstream, programming
- **ECP5** - Open-source ready (Lattice) - framework in place for implementation
- **Intel/Altera** - Via Quartus Docker (Cyclone, MAX 10, etc.) - full vendor toolchain
- **Xilinx** - Framework ready for future integration

### 🧪 Example Projects
Auto-generated 8-bit adder with:
- Complete testbench (600+ test cases)
- iCE40 constraint files
- Self-checking verification
- Ready for hardware implementation

## Supported Tools & Toolchains

The toolkit supports multiple FPGA toolchains - choose the one that fits your needs:

### 🌟 Open-Source Toolchain
**Simulation**: Icarus Verilog, GTKWave, Verilator
**Synthesis**: Yosys
**Place & Route**: NextPNR (iCE40, ECP5)
**Programming**: iceprog, openFPGALoader
**Package Manager**: OSS CAD Suite *(auto-downloaded from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build))*

Perfect for Lattice iCE40, ECP5, and other open FPGA architectures.

### 🐳 Intel Quartus in Docker
**Full Intel Toolchain**: Quartus Prime Lite 21.1 in Docker
**Container**: `raetro/quartus:21.1` *(kudos to [raetro](https://hub.docker.com/u/raetro) for the excellent Quartus Docker images!)*
**No License Required**: Free for Quartus Lite devices
**Isolated Environment**: Runs in Docker, no conflicts with other tools

Perfect for Intel/Altera FPGA development (Cyclone, MAX 10, etc.)

> 💡 **Why Docker for Quartus?** Intel Quartus is large (~20GB installed) and has specific dependencies. Running it in Docker keeps your system clean, makes installation painless, and ensures everything works out of the box!  

## Requirements

- **Linux**: Ubuntu 20.04+ or WSL2  
- **RAM**: 4GB+ (8GB recommended)  
- **Disk**: 10GB+ free space  
- **WSL**: Automatic update check ensures latest version for optimal performance  

## Use Cases

This toolkit is built for real-world FPGA work:

✨ **Learning FPGA design** - Start with working examples and a complete toolchain
✨ **Rapid prototyping** - Go from idea to blinking LED in minutes
✨ **Open-source projects** - No license fees, no vendor lock-in, pure freedom
✨ **Educational settings** - Complete simulation-to-hardware workflow for students
✨ **Commercial development** - Production-ready tools for small to medium designs
✨ **Multi-vendor projects** - Work with both Lattice (open-source) and Intel (Quartus) FPGAs  

## Installation Options

The installer is smart and flexible - you can run it interactively or specify exactly what you want.

### 🎯 Interactive Mode (Recommended)
Just run the installer and pick what you need from the menu:
```bash
./install_fpga_tools.sh
# Choose from: OSS tools, Docker, Quartus, or Everything!
```

### ⚡ Direct Mode (For automation or scripts)
Specify your choice upfront:
```bash
# Install open-source FPGA tools only
./install_fpga_tools.sh --mode=oss

# Install Docker engine only
./install_fpga_tools.sh --mode=docker

# Install Quartus (includes Docker)
./install_fpga_tools.sh --mode=quartus

# Install everything!
./install_fpga_tools.sh --mode=all
```

### 🧹 Cleanup & Reinstall
Keep your system tidy or start fresh:

```bash
# Interactive cleanup menu (choose what to remove)
./install_fpga_tools.sh --cleanup

# Remove specific components
./install_fpga_tools.sh --cleanup-oss       # Remove OSS tools
./install_fpga_tools.sh --cleanup-docker    # Remove Docker
./install_fpga_tools.sh --cleanup-quartus   # Remove Quartus containers

# Clean reinstall (nuke and pave!)
./install_fpga_tools.sh --reinstall --mode=all
```

### 🛡️ What the Installer Does For You
- **WSL Version Check**: Automatically detects and offers to update WSL to latest version (better performance!)
- **Write Protection**: Protects OSS CAD Suite installation from accidental corruption
- **Safe Cleanup**: Complete removal with automatic permission restoration
- **Verification**: Tests all tools after installation to make sure everything works
- **Fallback Options**: If something fails, automatically tries alternative installation methods
- **Smart Dependencies**: Installing Quartus? Docker gets installed automatically first!

### 🔧 Manual Installation (If you prefer DIY)
```bash
# Minimal open-source setup (Ubuntu/Debian)
sudo apt install iverilog gtkwave yosys nextpnr-ice40 fpga-icestorm

# For Docker
sudo apt install docker.io
sudo usermod -aG docker $USER  # Logout and login after this
```

## Documentation & Getting Help

### 📖 Built-in Documentation
- **Quick Start**: Run `./initiate_fpga_proj.sh` and follow the friendly prompts
- **Makefile Help**: `make help` in any project shows all available commands
- **Tool Check**: `make check-tools` verifies your installation is working
- **Project Status**: `make status` shows current build state and file organization
- **Installation Help**: `./install_fpga_tools.sh --help` for all installer options

### 🆘 Need Help?
- **Got questions?** Open an issue on GitHub - we're friendly!
- **Found a bug?** Please report it so we can fix it
- **Something unclear?** Documentation improvements welcome
- **Installation issues?** The installer includes detailed error messages to guide you

### 💡 Pro Tips
- Start with the open-source tools (option 1) - they're fastest to install
- Use `make quick-test` after creating a project to verify everything works
- Save your GTKWave sessions with `Ctrl+S` - they'll auto-load next time
- The installer protects your OSS CAD Suite installation from corruption
- Need Quartus? The Docker version saves you from a 20GB+ installation hassle

## Examples & Tutorials

### Set Up Custom Waveform Layout
```bash
# Run simulation and open waveforms
make sim-waves

# In GTKWave: arrange signals, set colors, create groups
# Save your layout: File -> Write Save File (Ctrl+S)
# Future runs automatically restore your setup!
make waves  # Opens with your saved layout
```

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

Want to make this toolkit even better? We'd love your help! 🤝

Some ideas to get started:
- 🔌 **Add FPGA families** - Extend the Makefile template for more devices
- 📝 **New examples** - Create cool demo projects others can learn from
- 🔧 **Tool integration** - Add support for more EDA tools and simulators
- 📚 **Documentation** - Write tutorials, fix typos, clarify confusing parts
- 🐛 **Bug fixes** - Found something broken? Fix it and send a PR!
- ✨ **New features** - Got an idea? Open an issue and let's discuss!

All contributions welcome - from typo fixes to major features!

## Acknowledgments

This toolkit stands on the shoulders of giants. Huge thanks to:

- **[YosysHQ](https://github.com/YosysHQ)** - For the incredible [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), Yosys, and NextPNR
- **[raetro](https://hub.docker.com/u/raetro)** - For the excellent [Quartus Docker images](https://hub.docker.com/r/raetro/quartus) that make Intel FPGA development painless
- **The entire open-source FPGA community** - For making vendor-neutral FPGA development a reality
- **All contributors** - Everyone who's helped improve this toolkit

## License

MIT License - Use freely for personal and commercial projects. Build something awesome! 🚀

---

**Ready to start designing?**
```bash
git clone https://github.com/moaz-kh/fpga-design-toolkit.git && cd fpga-design-toolkit && ./install_fpga_tools.sh
```

Got questions? Open an issue! Found this useful? Give it a ⭐

**Keywords**: FPGA development, open source EDA tools, Verilog design, digital design toolkit, iCE40 development, FPGA simulation, hardware design automation, RTL design, FPGA synthesis, nextpnr, yosys, Intel Quartus, Docker FPGA, Lattice FPGA
