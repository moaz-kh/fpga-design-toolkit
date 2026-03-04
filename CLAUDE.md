# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For user-facing documentation, see `README.md` and `docs/`.

## Project Overview

FPGA Design Toolkit — one-command open-source FPGA development environment. Supports open-source tools (Yosys, NextPNR, Icarus Verilog) and Intel Quartus via Docker. Entry points: `install_fpga_tools.sh` (tool installation) and `initiate_proj.sh` (project creation).

## Repository Structure

```
fpga-design-toolkit/
├── initiate_proj.sh          # User entry point - project creation
├── install_fpga_tools.sh     # User entry point - tool installation
├── README.md
├── CLAUDE.md
├── docs/                     # Detailed documentation
│   ├── fpga-programming.md
│   ├── wsl2-usb-setup.md
│   ├── examples-and-tutorials.md
│   └── troubleshooting.md
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

## Core Components

1. **initiate_proj.sh** - Main entry point wrapper script:
   - Interactive menu to choose toolchain (OSS or Quartus)
   - Calls appropriate project creation script from `scripts/` directory

2. **scripts/create_oss_project.sh** - Open-source project creation:
   - Creates directory structure, copies STD_MODULES.v, generates example adder + testbench
   - Sets up iCE40 constraint files, uses scripts/Makefile.oss template

3. **scripts/create_quartus_project.sh** - Quartus project creation:
   - Supports boards: TEI0010, DE10-Lite, DE2-115, DE10-Standard
   - Generates .qpf, .qsf with pin assignments and timing constraints
   - Creates customized Makefile from scripts/Makefile.quartus template

4. **scripts/Makefile.oss** - OSS toolchain Makefile template:
   - Family-based FPGA architecture (iCE40, ECP5)
   - Runtime parameter overrides via `?=` (TOP_MODULE, TESTBENCH, FPGA_FAMILY, FPGA_DEVICE, FPGA_PACKAGE, RTL_DIR, TB_DIR, SIM_DIR, FILELIST)
   - Auto-detection of available EDA tools

5. **scripts/Makefile.quartus** - Quartus toolchain Makefile template:
   - Docker-based Quartus Prime Lite workflow (raetro/quartus:21.1)
   - Auto-detection of project and programming files
   - Automatic USB setup prompts for WSL2

6. **scripts/setup-usb-fpga.sh** - WSL2 USB passthrough automation:
   - Interactive USB device detection, usbipd-win verification, hardware ID-based attachment

7. **scripts/STD_MODULES.v** - Standard Verilog modules:
   - `synchronizer` (CDC), `edge_detector`, `LED_logic`, `spi_interface_debounce`

8. **install_fpga_tools.sh** - Tool installation and management:
   - Modes: `--mode=oss`, `--mode=quartus`, `--mode=all`
   - Cleanup: `--cleanup`, `--cleanup-oss`, `--cleanup-docker`, `--cleanup-quartus`
   - Reinstall: `--reinstall`
   - Environment detection (WSL2 vs native Linux)
   - Write-protects OSS CAD Suite, creates VPI symlinks, verification + fallback

## Conventions

- Yes/no prompts accept flexible input (y/Y/yes/YES/n/N/no/NO) with `[yes/no]` format
- OSS tools install to `$HOME/.fpga-tool-kit_OSS_tools/`
- Generated projects use `sources/rtl/`, `sources/tb/`, `sim/`, `backend/` (OSS) or `output_files/` (Quartus)
- Default config: iCE40, UP5K, SG48, top module `adder`, testbench `adder_tb`
