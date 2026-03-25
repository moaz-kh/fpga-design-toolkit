# Makefile Template for Digital Design Projects (VHDL)
# GHDL simulation, ghdl-yosys-plugin synthesis

PROJECT = PROJECT_NAME_PLACEHOLDER
TOP_MODULE ?= adder
TESTBENCH ?= adder_tb

# FPGA family configuration
FPGA_FAMILY ?= ice40

ifeq ($(FPGA_FAMILY),ice40)
    FPGA_DEVICE ?= up5k
    FPGA_PACKAGE ?= sg48
else
    FPGA_DEVICE ?= generic
    FPGA_PACKAGE ?= generic
endif

# Constraint files
PCF_FILE ?= sources/constraints/$(TOP_MODULE).pcf
LPF_FILE ?= sources/constraints/$(TOP_MODULE).lpf
XDC_FILE ?= sources/constraints/$(TOP_MODULE).xdc

# Directories
RTL_DIR ?= sources/rtl
TB_DIR ?= sources/tb
SIM_DIR ?= sim
WAVE_DIR = $(SIM_DIR)/waves
LOG_DIR = $(SIM_DIR)/logs
FILELIST ?= sources/rtl_list.f
GHDL_WORK_DIR = $(SIM_DIR)/ghdl_work

# Backend directories
SYNTH_DIR = backend/synth
PNR_DIR = backend/pnr
BITSTREAM_DIR = backend/bitstream
REPORTS_DIR = backend/reports

# Tools
GHDL          := $(shell command -v ghdl 2> /dev/null)
GTKWAVE       := $(shell command -v gtkwave 2> /dev/null)
YOSYS         := $(shell command -v yosys 2> /dev/null)

NEXTPNR_ICE40 := $(shell command -v nextpnr-ice40 2> /dev/null)
ICEPACK       := $(shell command -v icepack 2> /dev/null)
ICEPROG       := $(shell command -v iceprog 2> /dev/null)
ICETIME       := $(shell command -v icetime 2> /dev/null)

OPENFPGALOADER := $(shell command -v openFPGALoader 2> /dev/null)

# Simulation files
WAVE_FILE    = $(WAVE_DIR)/$(TESTBENCH).vcd
FST_FILE     = $(WAVE_DIR)/$(TESTBENCH).fst
SESSION_FILE = $(WAVE_DIR)/$(TESTBENCH).gtkw

# Family-specific output files
ICE40_JSON = $(SYNTH_DIR)/$(PROJECT)_ice40.json
ICE40_ASC  = $(PNR_DIR)/$(PROJECT)_ice40.asc
ICE40_BIN  = $(BITSTREAM_DIR)/$(PROJECT)_ice40.bin

# Default target
.PHONY: help
help:
	@echo "=== $(PROJECT) Build System (VHDL) ==="
	@echo ""
	@echo "Current Configuration:"
	@echo "  FPGA_FAMILY=$(FPGA_FAMILY)"
	@echo "  FPGA_DEVICE=$(FPGA_DEVICE)"
	@echo "  FPGA_PACKAGE=$(FPGA_PACKAGE)"
	@echo "  Top module: $(TOP_MODULE)"
	@echo "  Testbench:  $(TESTBENCH)"
	@echo ""
	@echo "Basic targets:"
	@echo "  help          - Show this help"
	@echo "  check-tools   - Check available tools"
	@echo "  update_list   - Update rtl_list.f with current source files"
	@echo "  status        - Show project and tool status"
	@echo "  list-modules  - List available VHDL entities and testbenches"
	@echo ""
	@echo "Runtime configuration (override defaults):"
	@echo "  TOP_MODULE=name     - Override top module (default: $(TOP_MODULE))"
	@echo "  TESTBENCH=name      - Override testbench (default: $(TESTBENCH))"
	@echo "  FPGA_FAMILY=family  - Override FPGA family (default: $(FPGA_FAMILY))"
	@echo "  FPGA_DEVICE=device  - Override FPGA device (default: $(FPGA_DEVICE))"
	@echo "  RTL_DIR=path        - Override RTL directory (default: $(RTL_DIR))"
	@echo "  TB_DIR=path         - Override testbench directory (default: $(TB_DIR))"
	@echo ""
	@echo "Examples:"
	@echo "  make sim TOP_MODULE=counter TESTBENCH=counter_tb"
	@echo "  make ice40 FPGA_DEVICE=hx8k FPGA_PACKAGE=ct256"
	@echo ""
	@echo "Simulation targets:"
	@echo "  sim           - Run GHDL simulation"
	@echo "  waves         - View waveforms with GTKWave (loads .gtkw session if available)"
	@echo "  sim-waves     - Run simulation and open waveforms"
	@echo "  save-session  - Create template .gtkw session file for current testbench"
	@echo ""
	@echo "Complete workflow targets:"
	@echo "  all           - Complete flow for current family: synth -> pnr -> bitstream"
	@echo "  quick-test    - Update list and run simulation"
	@echo ""
	@echo "=== FPGA WORKFLOW TARGETS ==="
	@echo ""
	@echo "Generic targets (delegate to family-specific):"
	@echo "  synth         - Synthesize for current FPGA family ($(FPGA_FAMILY))"
	@echo "  pnr           - Place and route for current family"
	@echo "  timing        - Generate timing report for current family"
	@echo "  bitstream     - Generate bitstream for current family"
	@echo "  prog          - Program device with current family bitstream"
	@echo ""
	@echo "Family-specific targets:"
	@echo "  synth-ice40   - Synthesize for Lattice iCE40 (via ghdl-yosys-plugin)"
	@echo "  pnr-ice40     - Place and route for iCE40"
	@echo "  timing-ice40  - iCE40 timing analysis"
	@echo "  bitstream-ice40 - Generate iCE40 bitstream"
	@echo "  prog-ice40    - Program iCE40 device"
	@echo ""
	@echo "Family workflow shortcuts:"
	@echo "  ice40         - Complete iCE40 flow (synth+pnr+timing+bitstream)"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean         - Clean generated files"
	@echo "  clean-all     - Clean everything including logs"
	@echo ""
	@echo "Supported families: ice40"
	@echo "Future families: ecp5, intel, xilinx (to be implemented)"

# === TOOL CHECKING ===

.PHONY: check-tools
check-tools:
	@echo "=== Tool Availability Check ==="
	@echo ""
	@echo "Current family: $(FPGA_FAMILY)"
	@echo ""
	@echo "Simulation Tools:"
ifndef GHDL
	@echo "  ERROR: GHDL not found - required for VHDL simulation and synthesis"
	@echo "         Should be bundled with OSS CAD Suite. Check your PATH."
else
	@echo "  OK: GHDL: $(GHDL)"
endif
ifndef GTKWAVE
	@echo "  ERROR: GTKWave not found - install with: sudo apt install gtkwave"
else
	@echo "  OK: GTKWave: $(GTKWAVE)"
endif
	@echo ""
	@echo "Synthesis Tools:"
ifdef YOSYS
	@echo "  OK: Yosys: $(YOSYS)"
else
	@echo "  ERROR: Yosys not found - install with: sudo apt install yosys"
endif
	@echo ""
	@echo "Family-specific tools:"
	@echo ""
	@echo "iCE40 Tools:"
ifdef NEXTPNR_ICE40
	@echo "  OK: NextPNR-iCE40: $(NEXTPNR_ICE40)"
else
	@echo "  ERROR: NextPNR-iCE40 not found - install with: sudo apt install nextpnr-ice40"
endif
ifdef ICEPACK
	@echo "  OK: icepack: $(ICEPACK)"
else
	@echo "  ERROR: icepack not found - install with: sudo apt install fpga-icestorm"
endif
ifdef ICEPROG
	@echo "  OK: iceprog: $(ICEPROG)"
else
	@echo "  INFO: iceprog not found - install with: sudo apt install fpga-icestorm"
endif
ifdef ICETIME
	@echo "  OK: icetime: $(ICETIME)"
else
	@echo "  ERROR: icetime not found - install with: sudo apt install fpga-icestorm"
endif
	@echo ""
	@echo "Universal Programming Tools:"
ifdef OPENFPGALOADER
	@echo "  OK: openFPGALoader: $(OPENFPGALOADER)"
else
	@echo "  INFO: openFPGALoader not found - universal programmer (optional)"
endif

# === FILE LIST MANAGEMENT ===

.PHONY: update_list
update_list:
	@echo "Updating rtl_list.f with current VHDL source files..."
	@echo "# RTL and Testbench File List" > $(FILELIST)
	@echo "# Generated by 'make update_list'" >> $(FILELIST)
	@echo "# Date: $(shell date)" >> $(FILELIST)
	@echo "# Project: $(PROJECT)" >> $(FILELIST)
	@echo "" >> $(FILELIST)
	@echo "# RTL Source Files" >> $(FILELIST)
	@find $(PWD)/$(RTL_DIR) -name "*.vhd" -o -name "*.vhdl" | sort >> $(FILELIST) 2>/dev/null || true
	@echo "" >> $(FILELIST)
	@echo "# Testbench Files" >> $(FILELIST)
	@find $(PWD)/$(TB_DIR) \( -name "*_tb.vhd" -o -name "*_tb.vhdl" -o -name "tb_*.vhd" -o -name "tb_*.vhdl" \) | sort >> $(FILELIST) 2>/dev/null || true
	@echo "File list updated: $(FILELIST)"
	@echo "Found $(shell grep -c '^/' $(FILELIST) 2>/dev/null || echo 0) files"

.PHONY: list-modules
list-modules:
	@echo "=== Available VHDL Entities ==="
	@if [ -d "$(RTL_DIR)" ]; then \
		find $(RTL_DIR) \( -name "*.vhd" -o -name "*.vhdl" \) | while read file; do \
			entities=$$(grep -i "^entity " "$$file" 2>/dev/null | sed 's/entity //i' | sed 's/ is.*//'); \
			if [ ! -z "$$entities" ]; then \
				echo "$$file:"; \
				echo "$$entities" | sed 's/^/  - /'; \
			fi; \
		done; \
	fi
	@echo ""
	@echo "=== Available Testbenches ==="
	@if [ -d "$(TB_DIR)" ]; then \
		find $(TB_DIR) \( -name "*_tb.vhd" -o -name "*_tb.vhdl" -o -name "tb_*.vhd" -o -name "tb_*.vhdl" \) | while read file; do \
			echo "  $$file"; \
		done; \
	fi

# === SIMULATION TARGETS ===

.PHONY: sim
sim:
	@if [ -z "$(GHDL)" ]; then \
		echo "ERROR: GHDL not found. Should be bundled in OSS CAD Suite."; exit 1; \
	fi
	@if [ ! -s "$(FILELIST)" ] || ! grep -q "^/" "$(FILELIST)"; then \
		echo "ERROR: No source files in $(FILELIST). Run 'make update_list' first."; exit 1; \
	fi
	@mkdir -p $(SIM_DIR) $(WAVE_DIR) $(LOG_DIR) $(GHDL_WORK_DIR)
	@ALL_VHDL=$$(grep '^/' $(FILELIST) | grep '\.\(vhd\|vhdl\)$$'); \
	if [ -z "$$ALL_VHDL" ]; then echo "ERROR: No VHDL files in $(FILELIST)"; exit 1; fi; \
	echo "Analyzing VHDL files..."; \
	$(GHDL) -a --std=08 --workdir=$(GHDL_WORK_DIR) $$ALL_VHDL
	@echo "Elaborating $(TESTBENCH)..."
	@$(GHDL) -e --std=08 --workdir=$(GHDL_WORK_DIR) $(TESTBENCH)
	@echo "Running simulation..."
	@$(GHDL) -r --std=08 --workdir=$(GHDL_WORK_DIR) $(TESTBENCH) \
		--vcd=$(WAVE_FILE) 2>&1 | tee $(LOG_DIR)/simulation.log
	@echo "Simulation complete!"
	@echo "   Log: $(LOG_DIR)/simulation.log"
	@echo "   Waveform: $(WAVE_FILE)"
	@echo "View waves: make waves"
	@echo ""
	@echo "GTKWave Session Tip:"
	@echo "• First time: Arrange signals manually in GTKWave, then Ctrl+S to save session"
	@echo "• Future runs: 'make waves' will automatically restore your signal layout!"
	@echo "• Session file: $(SESSION_FILE)"

.PHONY: waves
waves:
	@if [ -z "$(GTKWAVE)" ]; then \
		echo "ERROR: GTKWave not available. Install with: sudo apt install gtkwave"; \
		exit 1; \
	fi
	@if [ -f "$(WAVE_FILE)" ]; then \
		if [ -f "$(SESSION_FILE)" ]; then \
			echo "Opening waveforms with saved session: $(WAVE_FILE) + $(SESSION_FILE)"; \
			$(GTKWAVE) $(WAVE_FILE) $(SESSION_FILE) & \
		else \
			echo "Opening waveforms: $(WAVE_FILE)"; \
			$(GTKWAVE) $(WAVE_FILE) & \
		fi \
	elif [ -f "$(FST_FILE)" ]; then \
		if [ -f "$(SESSION_FILE)" ]; then \
			echo "Opening waveforms with saved session: $(FST_FILE) + $(SESSION_FILE)"; \
			$(GTKWAVE) $(FST_FILE) $(SESSION_FILE) & \
		else \
			echo "Opening waveforms: $(FST_FILE)"; \
			$(GTKWAVE) $(FST_FILE) & \
		fi \
	else \
		echo "ERROR: No waveform files found"; \
		echo "TIP: Run 'make sim' first to generate waveforms"; \
		exit 1; \
	fi

.PHONY: sim-waves
sim-waves: sim waves

.PHONY: save-session
save-session:
	@echo "Creating GTKWave session template: $(SESSION_FILE)"
	@mkdir -p $(WAVE_DIR)
	@if [ -f "$(WAVE_FILE)" ] || [ -f "$(FST_FILE)" ]; then \
		echo "[*] 1.3.88" > $(SESSION_FILE); \
		echo "[dumpfile] \"$(TESTBENCH).vcd\"" >> $(SESSION_FILE); \
		echo "[dumpfile_mtime] \"$(shell date)\"" >> $(SESSION_FILE); \
		echo "[dumpfile_size] $(shell [ -f "$(WAVE_FILE)" ] && wc -c < "$(WAVE_FILE)" || echo 0)" >> $(SESSION_FILE); \
		echo "[savefile] \"$(TESTBENCH).gtkw\"" >> $(SESSION_FILE); \
		echo "[timestart] 0" >> $(SESSION_FILE); \
		echo "[size] 1920 1080" >> $(SESSION_FILE); \
		echo "[pos] -1 -1" >> $(SESSION_FILE); \
		echo "*-2.000000 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1" >> $(SESSION_FILE); \
		echo "[sst_width] 197" >> $(SESSION_FILE); \
		echo "[signals_width] 230" >> $(SESSION_FILE); \
		echo "[sst_expanded] 1" >> $(SESSION_FILE); \
		echo "[sst_vpaned_height] 540" >> $(SESSION_FILE); \
		echo "Template session file created: $(SESSION_FILE)"; \
		echo ""; \
		echo "Usage:"; \
		echo "1. Run 'make waves' to open GTKWave"; \
		echo "2. Add your signals, set colors, groupings, etc."; \
		echo "3. In GTKWave: File -> Write Save File (Ctrl+S)"; \
		echo "4. Save as $(SESSION_FILE)"; \
		echo "5. Next time 'make waves' will automatically load your setup!"; \
	else \
		echo "ERROR: No waveform files found. Run 'make sim' first."; \
		exit 1; \
	fi

# === GENERIC TARGETS (DELEGATE TO FAMILY-SPECIFIC) ===

.PHONY: synth
synth: synth-$(FPGA_FAMILY)
	@echo "Synthesis complete for $(FPGA_FAMILY) family"

.PHONY: pnr
pnr: pnr-$(FPGA_FAMILY)
	@echo "Place and route complete for $(FPGA_FAMILY) family"

.PHONY: timing
timing: timing-$(FPGA_FAMILY)
	@echo "Timing analysis complete for $(FPGA_FAMILY) family"

.PHONY: bitstream
bitstream: bitstream-$(FPGA_FAMILY)
	@echo "Bitstream generation complete for $(FPGA_FAMILY) family"

.PHONY: prog
prog: prog-$(FPGA_FAMILY)
	@echo "Programming complete for $(FPGA_FAMILY) family"

# === iCE40 FAMILY IMPLEMENTATION ===

.PHONY: synth-ice40
synth-ice40: FPGA_FAMILY=ice40
synth-ice40: FPGA_DEVICE=up5k
synth-ice40: FPGA_PACKAGE=sg48
synth-ice40: ICE40_JSON=$(SYNTH_DIR)/$(PROJECT)_ice40.json
synth-ice40:
ifdef YOSYS
	@echo "Running iCE40 VHDL synthesis for $(FPGA_DEVICE) ($(FPGA_PACKAGE))..."
	@mkdir -p $(SYNTH_DIR) $(REPORTS_DIR)
	@if [ -z "$(GHDL)" ]; then \
		echo "ERROR: GHDL not found - required for VHDL synthesis."; exit 1; \
	fi
	@if [ ! -s "$(FILELIST)" ] || ! grep -q "^/" "$(FILELIST)"; then \
		echo "ERROR: File list is empty. Run 'make update_list' first."; exit 1; \
	fi
	@VHDL_FILES=$$(sed '/# Testbench Files/q' $(FILELIST) | grep '^/' | \
		grep '\.\(vhd\|vhdl\)$$' | tr '\n' ' '); \
	echo "# VHDL synthesis via ghdl-yosys-plugin" > $(SYNTH_DIR)/yosys_script_ice40.ys; \
	echo "ghdl --std=08 --work=work $$VHDL_FILES -e $(TOP_MODULE)" \
		>> $(SYNTH_DIR)/yosys_script_ice40.ys; \
	echo "synth_ice40 -top $(TOP_MODULE) -json $(ICE40_JSON)" \
		>> $(SYNTH_DIR)/yosys_script_ice40.ys; \
	echo "stat -top $(TOP_MODULE)" >> $(SYNTH_DIR)/yosys_script_ice40.ys; \
	echo "write_verilog $(SYNTH_DIR)/$(PROJECT)_ice40_synth.v" \
		>> $(SYNTH_DIR)/yosys_script_ice40.ys
	@$(YOSYS) -m ghdl -q -s $(SYNTH_DIR)/yosys_script_ice40.ys \
		2>&1 | tee $(REPORTS_DIR)/$(PROJECT)_ice40_synth.log
	@echo "iCE40 VHDL synthesis complete!"
	@echo "   Device: $(FPGA_DEVICE) ($(FPGA_PACKAGE))"
	@echo "   JSON: $(ICE40_JSON)"
	@echo "   Log: $(REPORTS_DIR)/$(PROJECT)_ice40_synth.log"
else
	@echo "ERROR: Yosys not available. Install with: sudo apt install yosys"
	@exit 1
endif

.PHONY: pnr-ice40
pnr-ice40: FPGA_FAMILY=ice40
pnr-ice40: FPGA_DEVICE=up5k
pnr-ice40: FPGA_PACKAGE=sg48
pnr-ice40: ICE40_JSON=$(SYNTH_DIR)/$(PROJECT)_ice40.json
pnr-ice40: ICE40_ASC=$(PNR_DIR)/$(PROJECT)_ice40.asc
pnr-ice40: PCF_FILE=sources/constraints/$(TOP_MODULE).pcf
pnr-ice40:
ifdef NEXTPNR_ICE40
	@if [ ! -f "$(ICE40_JSON)" ]; then \
		echo "ERROR: Synthesis output $(ICE40_JSON) not found. Run 'make synth-ice40' first."; \
		exit 1; \
	fi
	@echo "Running iCE40 place and route for $(FPGA_DEVICE) ($(FPGA_PACKAGE))..."
	@mkdir -p $(PNR_DIR) $(REPORTS_DIR)
	@echo ""
	@echo "=== PCF CONSTRAINT CHECK ==="
	@if [ ! -f "$(PCF_FILE)" ]; then \
		echo "WARNING: Constraint file $(PCF_FILE) not found"; \
		echo "Running without constraints (I/O pins will be auto-assigned)"; \
		echo "==========================="; \
		echo ""; \
		$(NEXTPNR_ICE40) --$(FPGA_DEVICE) --package $(FPGA_PACKAGE) \
			--json $(ICE40_JSON) --asc $(ICE40_ASC) \
			--report $(REPORTS_DIR)/$(PROJECT)_ice40_pnr.json 2>&1 | tee $(REPORTS_DIR)/$(PROJECT)_ice40_pnr.log; \
	else \
		echo "Found PCF constraint file: $(PCF_FILE)"; \
		echo "==========================="; \
		echo ""; \
		$(NEXTPNR_ICE40) --$(FPGA_DEVICE) --package $(FPGA_PACKAGE) \
			--json $(ICE40_JSON) --pcf $(PCF_FILE) --asc $(ICE40_ASC) \
			--pcf-allow-unconstrained \
			--report $(REPORTS_DIR)/$(PROJECT)_ice40_pnr.json 2>&1 | tee $(REPORTS_DIR)/$(PROJECT)_ice40_pnr.log; \
	fi
	@echo "iCE40 place and route complete!"
	@echo "   Device: $(FPGA_DEVICE) ($(FPGA_PACKAGE))"
	@echo "   ASC: $(ICE40_ASC)"
	@echo "   Log: $(REPORTS_DIR)/$(PROJECT)_ice40_pnr.log"
else
	@echo "ERROR: NextPNR-iCE40 not available. Install with: sudo apt install nextpnr-ice40"
	@exit 1
endif

.PHONY: timing-ice40
timing-ice40: FPGA_FAMILY=ice40
timing-ice40: FPGA_DEVICE=up5k
timing-ice40: ICE40_ASC=$(PNR_DIR)/$(PROJECT)_ice40.asc
timing-ice40:
ifdef ICETIME
	@if [ ! -f "$(ICE40_ASC)" ]; then \
		echo "ERROR: PnR output $(ICE40_ASC) not found. Run 'make pnr-ice40' first."; \
		exit 1; \
	fi
	@echo "Running iCE40 timing analysis for $(FPGA_DEVICE)..."
	@mkdir -p $(REPORTS_DIR)
	@icetime -d $(FPGA_DEVICE) -mtr $(REPORTS_DIR)/$(PROJECT)_ice40_timing.rpt $(ICE40_ASC) 2>&1 | tee $(REPORTS_DIR)/$(PROJECT)_ice40_timing.log
	@echo "Timing analysis complete!"
	@echo "   Device: $(FPGA_DEVICE)"
	@echo "   Report: $(REPORTS_DIR)/$(PROJECT)_ice40_timing.rpt"
else
	@echo "ERROR: icetime not available. Install with: sudo apt install fpga-icestorm"
	@exit 1
endif

.PHONY: bitstream-ice40
bitstream-ice40: FPGA_FAMILY=ice40
bitstream-ice40: FPGA_DEVICE=up5k
bitstream-ice40: ICE40_ASC=$(PNR_DIR)/$(PROJECT)_ice40.asc
bitstream-ice40: ICE40_BIN=$(BITSTREAM_DIR)/$(PROJECT)_ice40.bin
bitstream-ice40:
ifdef ICEPACK
	@if [ ! -f "$(ICE40_ASC)" ]; then \
		echo "ERROR: PnR output $(ICE40_ASC) not found. Run 'make pnr-ice40' first."; \
		exit 1; \
	fi
	@echo "Generating iCE40 bitstream for $(FPGA_DEVICE)..."
	@mkdir -p $(BITSTREAM_DIR)
	@icepack $(ICE40_ASC) $(ICE40_BIN)
	@echo "iCE40 bitstream generation complete!"
	@echo "   Device: $(FPGA_DEVICE)"
	@echo "   Bitstream: $(ICE40_BIN)"
else
	@echo "ERROR: icepack not available. Install with: sudo apt install fpga-icestorm"
	@exit 1
endif

.PHONY: prog-ice40
prog-ice40: FPGA_FAMILY=ice40
prog-ice40: FPGA_DEVICE=up5k
prog-ice40: ICE40_BIN=$(BITSTREAM_DIR)/$(PROJECT)_ice40.bin
prog-ice40:
	@if [ ! -f "$(ICE40_BIN)" ]; then \
		echo "ERROR: Bitstream $(ICE40_BIN) not found. Run 'make bitstream-ice40' first."; \
		exit 1; \
	fi
	@echo "Programming iCE40 device ($(FPGA_DEVICE))..."
	@echo "Bitstream: $(ICE40_BIN)"
ifdef ICEPROG
	@iceprog $(ICE40_BIN)
	@echo "Programming complete!"
else
	@echo "WARNING: iceprog not available. Trying openFPGALoader..."
ifdef OPENFPGALOADER
	@openFPGALoader -b ice40_generic $(ICE40_BIN)
	@echo "Programming complete!"
else
	@echo "ERROR: No programming tool available"
	@echo "Install with: sudo apt install fpga-icestorm"
	@exit 1
endif
endif

# === FAMILY WORKFLOW SHORTCUTS ===

.PHONY: ice40
ice40: synth-ice40 pnr-ice40 timing-ice40 bitstream-ice40
	@echo "Complete iCE40 workflow finished!"
	@echo "Device: up5k (sg48)"
	@echo "Ready to program with: make prog-ice40"

# === STATUS AND UTILITIES ===

.PHONY: status
status:
	@echo "=== $(PROJECT) Status (VHDL) ==="
	@echo "Project: $(PROJECT)"
	@echo "Top module: $(TOP_MODULE)"
	@echo "Testbench: $(TESTBENCH)"
	@echo "FPGA Family: $(FPGA_FAMILY)"
	@echo "FPGA Device: $(FPGA_DEVICE)"
	@echo "FPGA Package: $(FPGA_PACKAGE)"
	@echo ""
	@echo "Source files:"
	@find $(RTL_DIR) -name "*.vhd" -o -name "*.vhdl" 2>/dev/null | wc -l | awk '{print "  VHDL files: " $$1}'
	@find $(TB_DIR) -name "*_tb.vhd" -o -name "*_tb.vhdl" 2>/dev/null | wc -l | awk '{print "  Testbenches: " $$1}'
	@echo ""
	@echo "Build status ($(FPGA_FAMILY)):"
ifeq ($(FPGA_FAMILY),ice40)
	@if [ -f "$(ICE40_JSON)" ]; then \
		echo "  OK: Synthesis complete ($(ICE40_JSON))"; \
	else \
		echo "  NO: Synthesis not done"; \
	fi
	@if [ -f "$(ICE40_ASC)" ]; then \
		echo "  OK: Place & Route complete ($(ICE40_ASC))"; \
	else \
		echo "  NO: Place & Route not done"; \
	fi
	@if [ -f "$(ICE40_BIN)" ]; then \
		echo "  OK: Bitstream ready ($(ICE40_BIN))"; \
	else \
		echo "  NO: Bitstream not generated"; \
	fi
else
	@echo "  INFO: $(FPGA_FAMILY) family not implemented yet"
endif
	@echo ""
	@echo "Available constraint files:"
	@if [ -f "$(PCF_FILE)" ]; then echo "  OK: iCE40: $(PCF_FILE)"; else echo "  NO: iCE40: $(PCF_FILE) not found"; fi

# === CLEAN TARGETS ===

.PHONY: clean
clean:
	@echo "Cleaning simulation and build outputs..."
	rm -f $(WAVE_DIR)/*.vcd $(WAVE_DIR)/*.fst $(WAVE_DIR)/*.lxt* $(WAVE_DIR)/*.ghw $(WAVE_DIR)/*.gtkw
	rm -f $(SYNTH_DIR)/*.json $(SYNTH_DIR)/*.ys $(SYNTH_DIR)/*.v
	rm -f $(PNR_DIR)/*.asc $(PNR_DIR)/*.config $(PNR_DIR)/*.json
	rm -f $(BITSTREAM_DIR)/*.bin $(BITSTREAM_DIR)/*.bit $(BITSTREAM_DIR)/*.fs
	rm -rf $(GHDL_WORK_DIR)
	@echo "Clean complete!"

.PHONY: clean-all
clean-all: clean
	@echo "Cleaning all generated files..."
	rm -f $(LOG_DIR)/*.log
	rm -f $(REPORTS_DIR)/*.log $(REPORTS_DIR)/*.rpt $(REPORTS_DIR)/*.json
	@echo "Deep clean complete!"

# Quick test target
.PHONY: quick-test
quick-test: update_list sim-waves
	@echo "Quick test complete! Simulation finished."

.PHONY: all
all: synth pnr timing bitstream
	@echo "Complete FPGA workflow finished for $(FPGA_FAMILY)!"
	@echo "Ready to program with: make prog"

# Make all PHONY targets explicit
.PHONY: synth synth-ice40 pnr pnr-ice40 timing timing-ice40
.PHONY: bitstream bitstream-ice40 prog prog-ice40 ice40 all
.PHONY: clean clean-all
