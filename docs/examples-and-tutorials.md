# Examples & Tutorials

## Set Up Custom Waveform Layout
```bash
# Run simulation and open waveforms
make sim-waves

# In GTKWave: arrange signals, set colors, create groups
# Save your layout: File -> Write Save File (Ctrl+S)
# Future runs automatically restore your setup!
make waves  # Opens with your saved layout
```

## Create LED Blinker
```verilog
LED_logic #(.time_count(50000000), .toggle_count(25000000))
    led_inst (.i_clk(clk), .i_rst_n(rst_n), .i_sig(button), .o_led(led));
```

## Add Clock Domain Crossing
```verilog
synchronizer #(.WIDTH(8)) sync_inst
    (.i_clk(clk), .i_rst_n(rst_n), .d_in(async_data), .d_out(sync_data));
```

## Complete Quartus Development Example

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
