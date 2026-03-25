# USB Setup for FPGA Programming (WSL2)

If you're using WSL2, FPGA programming requires two things:
1. **Programming tools installed inside WSL2** — handled by `./install_fpga_tools.sh`
2. **USB passthrough from Windows to WSL2** — covered below

The toolkit makes the USB passthrough easy.

## Automatic Setup (Recommended)

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

## Manual Setup (Advanced)

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

## Common Hardware IDs

| Device | Hardware ID | VID:PID |
|--------|-------------|---------|
| USB-Blaster (FTDI) | `0403:6010` | Future Technology Devices |
| USB-Blaster II | `09fb:6010` | Altera |
| USB-Blaster II (alt) | `09fb:6810` | Altera |

## Detach Device

```powershell
# Windows PowerShell
usbipd detach --busid 2-1
```
