# FPGA Programming

## Open-Source Flow (iCE40/ECP5)

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

## Quartus Flow (Intel/Altera)

### SRAM Programming (Temporary - for testing)
Configuration is volatile and lost on power cycle. Perfect for testing designs.

```bash
# Auto-detects .sof file and programs FPGA
make quartus-prog

# Complete build and program
make quartus-all && make quartus-prog
```

### Flash Programming (Permanent - for deployment)
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

### Device Detection

```bash
# Detect connected FPGA
make quartus-detect

# Expected output:
# manufacturer: altera
# family: MAX 10
# model: 10M08SAU169C8GES
```
