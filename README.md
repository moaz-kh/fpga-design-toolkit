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
2. **Quartus Prime Lite in Docker** - Intel/Altera FPGA toolchain (includes Docker), free and containerized
3. **Everything** - All tools for maximum flexibility

> 💡 **Tip**: Not sure? Start with option 1 (open-source tools) - it's the fastest way to get started!

### 2. Create Your First Project
```bash
./initiate_proj.sh
# Interactive menu appears - choose your toolchain:
# 1) Open-source tools (iCE40, ECP5)
# 2) Intel Quartus (MAX 10, Cyclone)
```

### 3. Test Everything Works

**For Open-Source Projects:**
```bash
cd your_project_name
make quick-test    # Simulation + waveforms + example adder
```

**For Quartus Projects:**
```bash
cd your_project_name
make quartus-all   # Complete synthesis flow
make quartus-prog  # Program FPGA
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

**Open-Source Toolchain:**
```bash
make sim           # Run simulation
make waves         # View waveforms (auto-loads session if available)
make save-session  # Create GTKWave session template
make synth-ice40   # Synthesize for iCE40
make ice40         # Complete FPGA flow
make prog-ice40    # Program device
```

**Quartus Toolchain:**
```bash
make quartus-all   # Complete flow (map → fit → asm)
make quartus-map   # Analysis & Synthesis
make quartus-fit   # Place & Route
make quartus-sta   # Static Timing Analysis
make quartus-asm   # Generate bitstreams
make quartus-prog  # Program FPGA (auto-detects .sof)
make quartus-prog FLASH=1  # Program Flash memory
make quartus-gui   # Open Quartus GUI
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
- **Intel/Altera** - Via Quartus Docker (Cyclone IV, Cyclone V, MAX 10) - full vendor toolchain with GUI support
- **Xilinx** - Framework ready for future integration

### 📟 Supported Development Boards

**Open-Source Projects:**
- Generic iCE40 boards (UP5K, HX8K, etc.)
- Generic ECP5 boards

**Quartus Projects:**
- **TEI0010** - Intel MAX 10 (10M08SAU169C8GES) - Default board
- **DE10-Lite** - Intel MAX 10 (10M50DAF484C7G)
- **DE2-115** - Cyclone IV E (EP4CE115F29C7N)
- **DE10-Standard** - Cyclone V SX SoC (5CSXFC6D6F31C6N)

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
- **WSL**: WSL2 recommended for Windows users (update via Windows Update if needed)  

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
# Choose from: OSS tools, Quartus (includes Docker), or Everything!
```

### ⚡ Direct Mode (For automation or scripts)
Specify your choice upfront:
```bash
# Install open-source FPGA tools only
./install_fpga_tools.sh --mode=oss

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
- **Environment Detection**: Automatically detects WSL2 or native Linux environments
- **Write Protection**: Protects OSS CAD Suite installation from accidental corruption
- **Safe Cleanup**: Complete removal with automatic permission restoration
- **Verification**: Tests all tools after installation to make sure everything works
- **Fallback Options**: If something fails, automatically tries alternative installation methods
- **Smart Dependencies**: Installing Quartus? Docker gets installed automatically first!
- **Flexible Input**: Accepts yes/no in any format (y, Y, yes, YES, n, N, no, NO, etc.)

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
- **Quick Start**: Run `./initiate_proj.sh` and follow the friendly prompts
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
- For WSL2 users: `make quartus-prog` automatically offers USB setup when needed

## FPGA Programming

### Open-Source Flow (iCE40/ECP5)

```bash
# Complete FPGA flow
make ice40         # Synthesis → P&R → Timing → Bitstream → Program

# Or step by step
make synth-ice40   # Synthesize
make pnr-ice40     # Place & Route
make timing-ice40  # Timing analysis
make bitstream-ice40  # Generate bitstream
make prog-ice40    # Program device
```

### Quartus Flow (Intel/Altera)

#### SRAM Programming (Temporary - for testing)
Configuration is volatile and lost on power cycle. Perfect for testing designs.

```bash
# Auto-detects .sof file and programs FPGA
make quartus-prog

# Complete build and program
make quartus-all && make quartus-prog
```

#### Flash Programming (Permanent - for deployment)
Configuration persists after power cycles. Perfect for deployment.

```bash
# Auto-detects .pof file and programs CFM
make quartus-prog FLASH=1

# Complete build and flash programming
make quartus-all && make quartus-prog FLASH=1
```

**MAX10 Flash Programming:**
- Uses native CFM (Configuration Flash Memory) via JTAG
- No spiOverJtag bridge needed (requires openFPGALoader v1.0.0+)
- Automatically programs UFM0, UFM1, CFM0, CFM1, CFM2 sections

#### Device Detection

```bash
# Detect connected FPGA
make quartus-detect

# Expected output:
# manufacturer: altera
# family: MAX 10
# model: 10M08SAU169C8GES
```

### USB Setup for FPGA Programming (WSL2)

If you're using WSL2, FPGA programming requires USB passthrough. The toolkit makes this easy:

#### Automatic Setup (Recommended)

```bash
# Just run this - it will offer USB setup if needed
make quartus-prog

# Or run the setup script directly
./scripts/setup-usb-fpga.sh
```

When `make quartus-prog` doesn't detect an FPGA, it automatically:
1. Detects WSL2 environment
2. Finds the `setup-usb-fpga.sh` script
3. Prompts you to run USB setup
4. Re-checks device after setup
5. Proceeds with programming if detected

#### Manual Setup (Advanced)

**1. Install usbipd-win (Windows PowerShell as Administrator):**
```powershell
winget install --interactive --exact dorssel.usbipd-win
```

**2. List USB devices (Windows PowerShell):**
```powershell
usbipd list
```

**3. Bind your FPGA device (one-time, Windows PowerShell as Administrator):**
```powershell
# Using Hardware ID (recommended - more portable)
usbipd bind --hardware-id 0403:6010

# OR using BUSID (changes when you plug into different port)
usbipd bind --busid 2-1
```

**4. Attach to WSL2 (Windows PowerShell as Administrator):**
```powershell
# Using Hardware ID (recommended)
usbipd attach --wsl --hardware-id 0403:6010

# OR using BUSID
usbipd attach --wsl --busid 2-1

# Optional: Auto-attach whenever device is plugged in
usbipd attach --wsl --auto-attach --busid 2-1
```

**5. Verify in WSL2:**
```bash
lsusb | grep -i "blaster\|ftdi\|altera"
make quartus-detect
```

**Common Hardware IDs:**
| Device | Hardware ID | VID:PID |
|--------|-------------|---------|
| USB-Blaster (FTDI) | `0403:6010` | Future Technology Devices |
| USB-Blaster II | `09fb:6010` | Altera |
| USB-Blaster II (alt) | `09fb:6810` | Altera |

**Detach Device (Windows PowerShell):**
```powershell
usbipd detach --busid 2-1
```

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

### Complete Quartus Development Example

```bash
# Create Quartus project with specific board
./initiate_proj.sh
# Choose option 2 (Intel Quartus)
# Select board (TEI0010, DE10-Lite, etc.)

cd my_project

# Edit your RTL
vim sources/rtl/my_project.v

# Run complete synthesis flow
make quartus-all

# View reports
make quartus-reports

# Check timing
make quartus-sta

# Program FPGA (SRAM - temporary)
make quartus-prog

# Or program Flash (permanent)
make quartus-prog FLASH=1

# Open Quartus GUI (requires X11 forwarding)
make quartus-gui
```

## Troubleshooting

### No FPGA Device Detected

**For Open-Source Flow:**
```bash
# Check if iceprog/openFPGALoader is in PATH
which iceprog
which openFPGALoader

# Check USB device
lsusb | grep -i "lattice\|ftdi"

# Try programming with verbose output
make prog-ice40 VERBOSE=1
```

**For Quartus Flow:**
```bash
# Let Make help you automatically (WSL2)
make quartus-prog
# Answer 'y' when prompted for USB setup

# Or manually check
lsusb | grep -i "blaster\|ftdi\|altera"

# Run USB setup manually
./scripts/setup-usb-fpga.sh

# Verify detection
make quartus-detect
```

**Common Hardware Issues:**
- FPGA board powered on
- USB cable connected (data cable, not charge-only)
- Correct USB port
- For WSL2: Device attached with usbipd

### Tool Not Found

**Check installation:**
```bash
# For OSS projects
make check-tools

# For Quartus projects
make check-tools
docker images | grep quartus
```

**Add OSS CAD Suite to PATH:**
```bash
# Temporary
export PATH=$HOME/fpga_workspace/oss-cad-suite/bin:$PATH

# Permanent (add to ~/.bashrc)
echo 'export PATH=$HOME/fpga_workspace/oss-cad-suite/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Synthesis/Fit Errors

**For Open-Source Flow:**
```bash
# Check synthesis log
cat backend/synth.log

# Check timing report
cat backend/timing.rpt
```

**For Quartus Flow:**
```bash
# View all reports
make quartus-reports

# Or view specific reports
cat output_files/*.rpt
cat output_files/my_project.map.rpt  # Synthesis
cat output_files/my_project.fit.rpt  # Fitter
cat output_files/my_project.sta.rpt  # Timing
```

**Common Issues:**
- Missing pin assignments → Check constraint files (.pcf, .sdc, .qsf)
- Timing violations → Run timing analysis and review constraints
- Resource overflow → Reduce design or use larger FPGA
- Undefined modules → Check RTL file list is complete

### Simulation Issues

```bash
# Update file list first
make update_list

# Run simulation with verbose output
make sim VERBOSE=1

# Check simulation log
cat sim/logs/sim.log

# Verify testbench
make list-modules
```

### Docker Issues (Quartus)

**Docker not running:**
```bash
sudo systemctl start docker
```

**Permission denied:**
```bash
sudo usermod -aG docker $USER
# Logout and login again
```

**Image not found:**
```bash
docker pull raetro/quartus:21.1
```

### Programming Fails

**Error: "No device detected"**
- For WSL2: Run `make quartus-prog` and accept USB setup offer
- Or manually: `./scripts/setup-usb-fpga.sh`
- Check `lsusb` output

**Error: "Device mismatch"**
- Verify correct FPGA in constraint files
- Check programming file matches hardware

**Error: "Verification failed"**
- Try verbose mode
- Check cable quality
- Verify power supply

### Timing Violations

```bash
# Open-source flow
make timing-ice40

# Quartus flow
make quartus-sta
make quartus-reports REPORT_OPTION=timing
```

**Common Fixes:**
- Add timing constraints (.sdc files)
- Reduce clock frequency
- Pipeline critical paths
- Use faster speed grade

### WSL2 Specific Issues

**WSL version too old:**
- Update WSL via Windows Update or PowerShell: `wsl --update`
- Ensure you're running WSL2: `wsl --set-version Ubuntu-22.04 2`

**USB device not visible after attach:**
- Check in Windows: `usbipd list` (STATE column should show "Attached")
- Try detaching and re-attaching
- Verify usbipd-win version is latest
- Try different USB port

## Contributing

Want to make this toolkit even better? We'd love your help! 🤝

Some ideas to get started:
- 🔌 **Add FPGA families** - Extend Makefiles for more devices
- 📝 **New examples** - Create cool demo projects others can learn from
- 🔧 **Tool integration** - Add support for more EDA tools and simulators
- 📚 **Documentation** - Write tutorials, fix typos, clarify confusing parts
- 🐛 **Bug fixes** - Found something broken? Fix it and send a PR!
- ✨ **New features** - Got an idea? Open an issue and let's discuss!
- 🎯 **Board support** - Add pin constraints and templates for new boards

All contributions welcome - from typo fixes to major features!

## Acknowledgments

This toolkit stands on the shoulders of giants. Huge thanks to:

- **[YosysHQ](https://github.com/YosysHQ)** - For the incredible [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), Yosys, and NextPNR
- **[raetro](https://hub.docker.com/u/raetro)** - For the excellent [Quartus Docker images](https://hub.docker.com/r/raetro/quartus) that make Intel FPGA development painless
- **[trabucayre](https://github.com/trabucayre)** - For [openFPGALoader](https://github.com/trabucayre/openFPGALoader), the universal FPGA programming tool
- **[dorssel](https://github.com/dorssel)** - For [usbipd-win](https://github.com/dorssel/usbipd-win), making USB passthrough to WSL2 possible
- **The entire open-source FPGA community** - For making vendor-neutral FPGA development a reality
- **All contributors** - Everyone who's helped improve this toolkit

## License

MIT License - Use freely for personal and commercial projects. Build something awesome! 🚀

---

**Ready to start designing?**
```bash
git clone https://github.com/moaz-kh/fpga-design-toolkit.git && cd fpga-design-toolkit && ./install_fpga_tools.sh
# Then create your first project with: ./initiate_proj.sh
```

Got questions? Open an issue! Found this useful? Give it a ⭐

**Keywords**: FPGA development, open source EDA tools, Verilog design, digital design toolkit, iCE40 development, FPGA simulation, hardware design automation, RTL design, FPGA synthesis, nextpnr, yosys, Intel Quartus, Docker FPGA, Lattice FPGA
