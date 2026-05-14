# Troubleshooting

## No FPGA Device Detected

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

## Tool Not Found

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
export PATH=$HOME/.fpga-tool-kit_OSS_tools/oss-cad-suite/bin:$PATH

# Permanent (add to ~/.bashrc)
echo 'export PATH=$HOME/.fpga-tool-kit_OSS_tools/oss-cad-suite/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Synthesis/Fit Errors

**For Open-Source Flow:**
```bash
# Check synthesis log
cat backend/reports/*_ice40_synth.log

# Check timing report
cat backend/reports/*_ice40_timing.rpt
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

## Simulation Issues

```bash
# Update file list first
make update_list

# Run simulation with verbose output
make sim VERBOSE=1

# Check simulation log
cat sim/logs/simulation.log

# Verify testbench
make list-modules
```

## Docker Issues (Quartus)

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

## Programming Fails

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

## Timing Violations

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

## WSL2 Specific Issues

**WSL version too old:**
- Update WSL via Windows Update or PowerShell: `wsl --update`
- Ensure you're running WSL2: `wsl --set-version Ubuntu-22.04 2`

**USB device not visible after attach:**
- Check in Windows: `usbipd list` (STATE column should show "Attached")
- Try detaching and re-attaching
- Verify usbipd-win version is latest
- Try different USB port
