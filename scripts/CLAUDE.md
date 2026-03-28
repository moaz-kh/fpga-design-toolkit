# CLAUDE.md

This file provides guidance to Claude Code when working inside this FPGA project.

---

## Project Context

| Property     | Value |
|--------------|-------|
| Toolchain    | Open-source (Yosys, NextPNR, Icarus Verilog / GHDL) |
| FPGA target  | Lattice iCE40 UP5K — package SG48 |
| Constraints  | iCE40 PCF format — `sources/constraints/*.pcf` |

**Detect HDL language from file extensions present in `sources/rtl/`:**

| Extension    | Language              | Simulator     | Synthesiser |
|--------------|-----------------------|---------------|-------------|
| `.v` / `.sv` | Verilog / SystemVerilog | Icarus Verilog (`iverilog` / `vvp`) | Yosys |
| `.vhd`       | VHDL (VHDL-2008)      | GHDL (`--std=08`) | `yosys -m ghdl` (ghdl-yosys-plugin) |

---

## Directory Structure

```
<project>/
├── sources/
│   ├── rtl/            # RTL source files (.v / .sv  or  .vhd)
│   │   └── STD_MODULES.*   # Standard utility modules — do not re-implement
│   ├── tb/             # Testbenches  (<module>_tb.v  or  <module>_tb.vhd)
│   ├── include/        # Include / header files
│   ├── constraints/    # Pin constraint files (.pcf)
│   └── rtl_list.f      # File list — must regenerate after adding/removing files
├── sim/
│   ├── waves/          # Waveform dumps (.vcd / .fst / .ghw)
│   └── logs/           # Simulation log files
├── backend/
│   ├── synth/          # Yosys synthesis outputs (.json)
│   ├── pnr/            # NextPNR place-and-route outputs (.asc)
│   ├── bitstream/      # Final bitstreams (.bin)
│   └── reports/        # Timing and utilisation reports
├── Makefile
├── CLAUDE.md
└── README.md
```

---

## Makefile Targets

| Target             | Action |
|--------------------|--------|
| `make sim`         | Compile and run simulation |
| `make waves`       | Open waveform viewer (GTKWave) |
| `make sim-waves`   | Run simulation then open waveforms |
| `make synth`       | Synthesise with Yosys |
| `make update_list` | Rebuild `sources/rtl_list.f` from current files |
| `make check-tools` | Verify all required tools are installed |
| `make status`      | Show project status summary |
| `make clean`       | Remove generated build artefacts |
| `make help`        | List all available targets |

---

## Overriding Make Parameters

Pass overrides directly on the command line.  Run `make update_list` first whenever files have been added or removed.

| Parameter      | Controls                        | Default  |
|----------------|---------------------------------|----------|
| `TOP_MODULE`   | Top-level module / entity name  | adder    |
| `TESTBENCH`    | Testbench module / entity name  | adder_tb |
| `FPGA_FAMILY`  | FPGA architecture               | ice40    |
| `FPGA_DEVICE`  | Device part number              | up5k     |
| `FPGA_PACKAGE` | Device package                  | sg48     |

Example — after adding `uart_tx` RTL and testbench files:

```bash
make update_list
make sim-waves TOP_MODULE=uart_tx TESTBENCH=uart_tx_tb
```

The same override syntax applies to any target that invokes simulation or synthesis (`sim`, `waves`, `sim-waves`, `synth`).

---

## Workflow Rules

- **Always** run `make update_list` after adding or removing any RTL or TB file.
- Testbench files must be named `<module>_tb.v` / `<module>_tb.vhd` and placed in `sources/tb/`.
- One module / entity per file; filename must match the module / entity name exactly.
- RTL files go in `sources/rtl/`; never mix RTL and TB files in the same directory.
- Constraint files use iCE40 PCF format and go in `sources/constraints/`.

---

## Standard Modules Library

These modules are already available in `STD_MODULES.v` / `STD_MODULES.vhd` — do not re-implement them:

| Module                  | Purpose |
|-------------------------|---------|
| `synchronizer`          | Multi-bit clock-domain crossing synchroniser (parameterised WIDTH) |
| `edge_detector`         | Positive- and negative-edge detection (sync or async input) |
| `LED_logic`             | Configurable LED blinker / flasher (`time_count`, `toggle_count` parameters) |
| `spi_interface_debounce`| Debounce SPI clock, MOSI, and CS_n signals |

---

# RTL Coding Guidelines

Follow these guidelines strictly when writing, reviewing, or refactoring any HDL code.
Detect the target language from file extensions (`.v`, `.sv`, `.vhd`), existing code style, or explicit user request.

---

# Part 1 — Shared Conventions (All Languages)

These rules apply to Verilog, SystemVerilog, and VHDL equally.

## Naming Conventions

| Category | Convention | Example |
|---|---|---|
| Input ports | `i_<n>` | `i_data`, `i_valid`, `i_addr` |
| Output ports | `o_<n>` | `o_data`, `o_ready`, `o_error` |
| Clocks | `i_clk` or `i_clk_<domain>` | `i_clk`, `i_clk_sys`, `i_clk_phy` |
| Active-low resets | `i_rst_n` or `i_rst_<domain>_n` | `i_rst_n`, `i_rst_sys_n` |
| Active-high resets | `i_rst` or `i_rst_<domain>` | `i_rst`, `i_rst_sys` |
| Registers (flopped) | `<n>_r` | `data_valid_r`, `count_r` |
| Active-low signals | `<n>_n` | `chip_sel_n`, `wr_en_n` |
| FSM state register | `state_r` | — |
| FSM next state (FSM only) | `state_nxt` | — |
| Generate block labels | `gen_<description>` | `gen_pipeline_stage` |
| Instance names | `u_<descriptive_name>` | `u_axi_fifo`, `u_cdc_sync` |
| CDC signals | `<n>_<src>2<dst>` | `valid_axi2sys`, `req_sys2phy` |
| Module / entity names | `lower_snake_case` | `ble_tx_filter`, `apb_reg_file` |
| Testbench top-level | `tb_<module_name>` | `tb_axi_fifo` |

## Design Philosophy

- **Single-block sequential**: Embed next-state logic directly inside the clocked block. Do not create separate `_nxt` signals for regular registers.
- **Two-block FSM exception**: FSMs use separate sequential and combinational blocks with `state_r` / `state_nxt`. This is the only case where `_nxt` signals are used.
- **Synthesizable by default**: If a construct is simulation-only, mark it explicitly.
- **One module/entity per file**: Filename matches the module/entity name exactly.
- **Port grouping order**: Clocks/resets (`i_clk`, `i_rst_n`) first, then inputs (`i_*`), then outputs (`o_*`).
- **Zero lint warnings**: Target clean SpyGlass / Ascent / Questa Lint runs.
- **File header**: Every file must have a header comment with purpose, author placeholder, date placeholder, and revision notes.
- **No magic numbers**: Parameterize all widths, depths, and thresholds.

## Reset & Clock Rules

- Asynchronous active-low reset (`i_rst_n`) is the default unless the project specifies otherwise.
- Every flop must be in a reset domain. No unresettable flops unless explicitly justified with a comment.
- Do not gate clocks in RTL unless instantiating a specific clock-gating cell (ICG for ASIC, BUFGCE for FPGA).
- One clock per sequential block — never use multiple clocks in a single block/process.
- If the design involves CDC, flag it explicitly and suggest appropriate synchronizer structures — never silently cross clock domains.

## Formatting Rules

- **Indentation**: 2 spaces. No tabs.
- **Line length**: 100 characters max.
- **Blank lines**: One between logical sections, two before a new major section.
- **Alignment**: Align port directions, types, widths, and names vertically.
- **Trailing whitespace**: None.
- **End-of-file**: Single newline.
- **Begin/end / if/end if**: Always use block delimiters, even for single statements.

## When Generating Any RTL Code

- Ask or infer: target language, target platform (ASIC or FPGA), clock/reset convention, bus protocol if applicable.
- Provide header, declarations, and logic in separate clearly-commented sections.
- Include inline comments explaining non-obvious design intent or microarchitecture.
- If the design involves CDC, flag it and suggest synchronizer structures.
- If the design involves an FSM, document the state transition list in comments before the RTL.
- When modifying existing code, preserve the original naming and style conventions already in use.

---

# Part 2 — Verilog / SystemVerilog

Where the two languages differ, differences are marked with **[V]** and **[SV]**.

## Additional Naming (SV Only)

| Category | Convention | Example |
|---|---|---|
| Interfaces | `<protocol>_if` | `axi_if`, `apb_if` |
| Typedef enums | `<n>_e` | `fsm_state_e` |
| Typedef structs | `<n>_t` | `axi_req_t` |
| Packages | `<n>_pkg` | `axi_pkg`, `ucie_pkg` |

## Type Usage

- **[V]** Use `wire` for nets and `reg` for variables assigned in procedural blocks.
- **[SV]** Use `logic` everywhere. Do not use `reg` or `wire`.

```verilog
// [V]
input  wire  [DATA_W-1:0] i_data,
output reg                 o_valid,
reg [7:0] count_r;
```

```systemverilog
// [SV]
input  logic [DATA_W-1:0] i_data,
output logic               o_valid,
logic [7:0] count_r;
```

## Port Declarations

```verilog
// [V] — Verilog-2001 ANSI style. Never use Verilog-95 style.
`default_nettype none

module example_module #(
  parameter DATA_W = 32,
  parameter ADDR_W = 8
) (
  // Clock & Reset
  input  wire                 i_clk,
  input  wire                 i_rst_n,

  // Inputs
  input  wire [DATA_W-1:0]    i_data,
  input  wire                 i_valid,

  // Outputs
  output reg  [DATA_W-1:0]    o_data,
  output reg                  o_ready
);
```

```systemverilog
// [SV]
`default_nettype none

module example_module #(
  parameter int unsigned DATA_W = 32,
  parameter int unsigned ADDR_W = 8
) (
  // Clock & Reset
  input  logic                i_clk,
  input  logic                i_rst_n,

  // Inputs
  input  logic [DATA_W-1:0]   i_data,
  input  logic                i_valid,

  // Outputs
  output logic [DATA_W-1:0]   o_data,
  output logic                o_ready
);
```

### Port Rules

- No trailing comma on the last port.
- Use `default_nettype none` at the top of every file.
- **[V]** Inputs as `wire`. Outputs as `reg` if procedural, `wire` if `assign`.
- **[SV]** All ports as `logic`. Use `int unsigned` for parameter types.

## Sequential Logic

- **[V]** `always @(posedge i_clk or negedge i_rst_n)`
- **[SV]** `always_ff @(posedge i_clk or negedge i_rst_n)` — never use `always @(posedge ...)`.

```verilog
// [V]
always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    count_r <= {DATA_W{1'b0}};
  end else if (i_clear) begin
    count_r <= {DATA_W{1'b0}};
  end else if (i_en) begin
    count_r <= count_r + 1'b1;
  end
end
```

```systemverilog
// [SV]
always_ff @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n) begin
    count_r <= '0;
  end else if (i_clear) begin
    count_r <= '0;
  end else if (i_en) begin
    count_r <= count_r + 1'b1;
  end
end
```

### Rules

- Non-blocking assignments (`<=`) only.
- **[V]** Sized replication for reset: `{WIDTH{1'b0}}`.
- **[SV]** Fill literals: `'0`, `'1`.

## Combinational Logic

For output decode, muxing, and glue logic only — not for register next-state.

- **[V]** `always @(*)`
- **[SV]** `always_comb` — never use `always @(*)`.

```verilog
// [V]
assign o_valid = (state_r == ST_DONE);

always @(*) begin
  o_result = 'd0;
  case (i_sel)
    2'b00:   o_result = i_a + i_b;
    2'b01:   o_result = i_a - i_b;
    default: o_result = 'd0;
  endcase
end
```

```systemverilog
// [SV]
assign o_valid = (state_r == ST_DONE);

always_comb begin
  o_result = '0;
  unique case (i_sel)
    2'b00:   o_result = i_a + i_b;
    2'b01:   o_result = i_a - i_b;
    default: o_result = '0;
  endcase
end
```

### Rules

- Blocking assignments (`=`) only.
- Default assignment for every signal at the top of the block.

## Latch Inference

- Never infer latches unless intentional.
- **[SV]** Use `always_latch` with a `// INTENTIONAL LATCH: <reason>` comment.

## FSM Design

### State Encoding

```verilog
// [V] — localparam with explicit widths
localparam [1:0] ST_IDLE = 2'b00;
localparam [1:0] ST_LOAD = 2'b01;
localparam [1:0] ST_EXEC = 2'b10;
localparam [1:0] ST_DONE = 2'b11;

reg [1:0] state_r;
reg [1:0] state_nxt;
```

```systemverilog
// [SV] — typedef enum with underlying type
typedef enum logic [1:0] {
  ST_IDLE = 2'b00,
  ST_LOAD = 2'b01,
  ST_EXEC = 2'b10,
  ST_DONE = 2'b11
} fsm_state_e;

fsm_state_e state_r;
fsm_state_e state_nxt;
```

### Two-Block FSM Template

```verilog
// [V] Sequential
always @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n)
    state_r <= ST_IDLE;
  else
    state_r <= state_nxt;
end

// [V] Combinational
always @(*) begin
  state_nxt = state_r;
  case (state_r)
    ST_IDLE:  if (i_start) state_nxt = ST_LOAD;
    ST_LOAD:  state_nxt = ST_EXEC;
    ST_EXEC:  if (done) state_nxt = ST_DONE;
    ST_DONE:  state_nxt = ST_IDLE;
    default:  state_nxt = ST_IDLE;
  endcase
end
```

```systemverilog
// [SV] Sequential
always_ff @(posedge i_clk or negedge i_rst_n) begin
  if (!i_rst_n)
    state_r <= ST_IDLE;
  else
    state_r <= state_nxt;
end

// [SV] Combinational
always_comb begin
  state_nxt = state_r;
  unique case (state_r)
    ST_IDLE:  if (i_start) state_nxt = ST_LOAD;
    ST_LOAD:  state_nxt = ST_EXEC;
    ST_EXEC:  if (done) state_nxt = ST_DONE;
    ST_DONE:  state_nxt = ST_IDLE;
    default:  state_nxt = ST_IDLE;
  endcase
end
```

### FSM Rules

- Always include `default` returning to a safe state.
- Document the state diagram in comments above the FSM.
- **[SV]** Use `unique case` instead of bare `case`.

## Case Statements

- Always include a `default` branch.
- Avoid `casex` entirely. Prefer `case`; use `casez` only for don't-care matching.
- **[V]** Bare `case`.
- **[SV]** `unique case` or `priority case`.

## Parameters & Constants

- `parameter` for configurable values. `localparam` for derived/internal constants.
- Avoid `define` — prefer `parameter` / `localparam`.
- **[SV]** Use `int unsigned` for parameter types.

## Sized Literals

- Always use sized and based literals: `4'd10`, `1'b0`, `8'hFF`.
- **[V]** Sized replication: `{WIDTH{1'b0}}`.
- **[SV]** Fill literals: `'0`, `'1`.

## Generate Blocks

```verilog
// [V]
genvar ii;
generate
  for (ii = 0; ii < NUM_STAGES; ii = ii + 1) begin : gen_pipe_stage
    // ...
  end
endgenerate
```

```systemverilog
// [SV]
for (genvar ii = 0; ii < NUM_STAGES; ii++) begin : gen_pipe_stage
  // ...
end
```

## Module Instantiation

Named port connections only. Prefix instances with `u_`. Explicit `#()` for parameters.

```verilog
fifo #(
  .DATA_W (AXI_DATA_W),
  .DEPTH  (16)
) u_tx_fifo (
  .i_clk   (i_clk),
  .i_rst_n (i_rst_n),
  .i_data  (tx_data),
  .o_data  (fifo_out),
  .o_full  (fifo_full)
);
```

## Packages [SV Only]

```systemverilog
package axi_pkg;
  parameter int unsigned AXI_DATA_W = 64;

  typedef enum logic [1:0] {
    AXI_RESP_OKAY   = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi_resp_e;

  typedef struct packed {
    logic [31:0] addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
  } axi_ax_t;
endpackage
```

Import at the module level:

```systemverilog
module axi_slave
  import axi_pkg::*;
#( ... ) ( ... );
```

## Structs [SV Only]

- `typedef struct packed` for synthesizable structs, suffix `_t`.

```systemverilog
typedef struct packed {
  logic        valid;
  logic [31:0] data;
  logic [3:0]  strb;
} axi_w_t;
```

## Interfaces [SV Only]

- Suffix `_if`. Define `modport` for master/slave/monitor.

```systemverilog
interface apb_if #(
  parameter int unsigned ADDR_W = 12,
  parameter int unsigned DATA_W = 32
) (
  input logic i_clk,
  input logic i_rst_n
);
  logic                sel;
  logic                enable;
  logic [ADDR_W-1:0]   addr;
  logic [DATA_W-1:0]   wdata;
  logic [DATA_W-1:0]   rdata;
  logic                ready;

  modport master (output sel, enable, addr, wdata, input rdata, ready);
  modport slave  (input  sel, enable, addr, wdata, output rdata, ready);
endinterface
```

## Assertions [SV Only — Simulation]

Wrap in `ifndef SYNTHESIS` / `endif`. Place at the bottom of the module or in a bind file.

```systemverilog
`ifndef SYNTHESIS
  assert property (@(posedge i_clk) disable iff (!i_rst_n)
    i_valid |-> !$isunknown(i_data)
  ) else $error("Data unknown when valid");
`endif
```

## V/SV Anti-Patterns

1. Inferred latches — defaults at top of combinational blocks.
2. Incomplete `case` — always include `default`.
3. Blocking in sequential — use `<=`.
4. Non-blocking in combinational — use `=`.
5. Multi-driven signals.
6. Magic numbers.
7. Missing `default_nettype none`.
8. Unused signals without justification.
9. Positional port mapping.
10. **[V]** Unsized literals.
11. **[V]** Verilog-95 port style.
12. **[V]** Incomplete sensitivity lists.
13. **[SV]** Using `reg` / `wire`.
14. **[SV]** Using `always @(*)` or `always @(posedge ...)`.
15. **[SV]** Bare `case` for decoders/FSMs.
16. **[SV]** Enum without underlying type.

## V/SV Note

Always end files with `` `default_nettype wire `` to restore the default for downstream modules.

---

# Part 3 — VHDL

## Additional Naming (VHDL Specific)

| Category | Convention | Example |
|---|---|---|
| Constants | `C_UPPER_SNAKE` | `C_DATA_WIDTH`, `C_FIFO_DEPTH` |
| Generics | `G_UPPER_SNAKE` | `G_DATA_W`, `G_ADDR_W` |
| Process labels | `p_<description>` | `p_seq`, `p_comb`, `p_fsm_nxt` |
| Records | `<n>_t` or `<n>_rec` | `axi_req_t`, `ctrl_rec` |
| Packages | `<n>_pkg` | `axi_pkg`, `ucie_pkg` |
| Architecture names | `rtl`, `behavioral`, `structural` | `architecture rtl of axi_fifo` |

## Library & Use Clauses

Always include. Never use `std_logic_arith`, `std_logic_unsigned`, or `std_logic_signed`.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
```

## Type Usage

- `std_logic` / `std_logic_vector` for all ports. Never `bit` / `bit_vector`.
- `unsigned` / `signed` from `numeric_std` for internal arithmetic.
- Convert at boundaries: `std_logic_vector()`, `unsigned()`, `to_unsigned()`, `resize()`.
- Avoid `integer` for hardware signals — use `unsigned` with explicit width.
- `natural` / `positive` for generics and compile-time constants.

## Port Declarations

- Port modes: `in`, `out`, `inout`. Avoid `buffer` — use `out` with an internal signal.
- Named association in all port/generic maps — never positional.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity example_module is
  generic (
    G_DATA_W : natural := 32;
    G_ADDR_W : natural := 8
  );
  port (
    -- Clock & Reset
    i_clk     : in  std_logic;
    i_rst_n   : in  std_logic;

    -- Inputs
    i_data    : in  std_logic_vector(G_DATA_W - 1 downto 0);
    i_valid   : in  std_logic;

    -- Outputs
    o_data    : out std_logic_vector(G_DATA_W - 1 downto 0);
    o_ready   : out std_logic
  );
end entity example_module;
```

## Sequential Logic

Use `rising_edge(i_clk)`. Never use `i_clk'event and i_clk = '1'`. Label every process.

```vhdl
p_count : process(i_clk, i_rst_n)
begin
  if i_rst_n = '0' then
    count_r <= (others => '0');
  elsif rising_edge(i_clk) then
    if i_clear = '1' then
      count_r <= (others => '0');
    elsif i_en = '1' then
      count_r <= count_r + 1;
    end if;
  end if;
end process p_count;
```

### Rules

- Async reset first in sensitivity list and as the first `if` clause.
- Reset values: `(others => '0')`.
- One clock per process.

## Combinational Logic

For output decode, muxing, and glue logic — not for register next-state.

Default to VHDL-2008 `process(all)`. For VHDL-93, enumerate all read signals.

```vhdl
-- Simple — concurrent assignment
o_valid <= '1' when state_r = ST_DONE else '0';

-- Multi-line — combinational process
p_decode : process(all)
begin
  o_result <= (others => '0');
  case i_sel is
    when "00"   => o_result <= std_logic_vector(i_a + i_b);
    when "01"   => o_result <= std_logic_vector(i_a - i_b);
    when others => o_result <= (others => '0');
  end case;
end process p_decode;
```

### Rules

- Default assignment at the top of every combinational process.
- Use concurrent assignments (`when/else`, `with/select`) for one-liners.

## FSM Design

Two-process exception with `state_r` / `state_nxt`.

### State Encoding

```vhdl
type fsm_state_t is (ST_IDLE, ST_LOAD, ST_EXEC, ST_DONE);

signal state_r   : fsm_state_t;
signal state_nxt : fsm_state_t;
```

### Two-Process FSM Template

```vhdl
p_fsm_seq : process(i_clk, i_rst_n)
begin
  if i_rst_n = '0' then
    state_r <= ST_IDLE;
  elsif rising_edge(i_clk) then
    state_r <= state_nxt;
  end if;
end process p_fsm_seq;

p_fsm_nxt : process(all)
begin
  state_nxt <= state_r;
  case state_r is
    when ST_IDLE =>
      if i_start = '1' then
        state_nxt <= ST_LOAD;
      end if;
    when ST_LOAD =>
      state_nxt <= ST_EXEC;
    when ST_EXEC =>
      if done = '1' then
        state_nxt <= ST_DONE;
      end if;
    when ST_DONE =>
      state_nxt <= ST_IDLE;
    when others =>
      state_nxt <= ST_IDLE;
  end case;
end process p_fsm_nxt;
```

### FSM Rules

- Always include `when others` returning to a safe state.
- Document state diagram in comments above the FSM.

## Case Statements

- Always include `when others`.
- Default assignment at top of process for all outputs.

## Generics & Constants

- `G_` prefix for generics, `C_` prefix for constants.
- `natural` / `positive` for generic types.
- For `ceil`/`log2` in constant computation, `use ieee.math_real.all;` is acceptable. Do not use `math_real` for signal-level math.

```vhdl
entity fifo is
  generic (
    G_DATA_W : natural := 32;
    G_DEPTH  : natural := 16
  );
  port ( ... );
end entity fifo;

architecture rtl of fifo is
  constant C_PTR_W : natural := integer(ceil(log2(real(G_DEPTH))));
begin
  ...
end architecture rtl;
```

## Generate Statements

```vhdl
gen_pipe_stage : for ii in 0 to C_NUM_STAGES - 1 generate
begin
  p_pipe : process(i_clk, i_rst_n)
  begin
    if i_rst_n = '0' then
      pipe_r(ii) <= (others => '0');
    elsif rising_edge(i_clk) then
      if ii = 0 then
        pipe_r(ii) <= i_data;
      else
        pipe_r(ii) <= pipe_r(ii - 1);
      end if;
    end if;
  end process p_pipe;
end generate gen_pipe_stage;
```

## Entity Instantiation

Direct entity instantiation — avoid `component` declarations unless required for legacy compatibility.

```vhdl
u_tx_fifo : entity work.fifo
  generic map (
    G_DATA_W => C_AXI_DATA_W,
    G_DEPTH  => 16
  )
  port map (
    i_clk    => i_clk,
    i_rst_n  => i_rst_n,
    i_data   => tx_data,
    o_data   => fifo_out,
    o_full   => fifo_full
  );
```

## Packages

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi_pkg is
  constant C_AXI_DATA_W : natural := 64;
  constant C_AXI_ADDR_W : natural := 32;

  type axi_resp_t is (AXI_RESP_OKAY, AXI_RESP_EXOKAY, AXI_RESP_SLVERR, AXI_RESP_DECERR);

  type axi_ax_t is record
    addr  : std_logic_vector(C_AXI_ADDR_W - 1 downto 0);
    len   : std_logic_vector(7 downto 0);
    size  : std_logic_vector(2 downto 0);
    burst : std_logic_vector(1 downto 0);
  end record axi_ax_t;

  constant C_AXI_AX_INIT : axi_ax_t := (
    addr  => (others => '0'),
    len   => (others => '0'),
    size  => (others => '0'),
    burst => (others => '0')
  );
end package axi_pkg;
```

Import: `use work.axi_pkg.all;`

## Records

- `type <n>_t is record ... end record` for bundling related signals.
- Define a `C_<type>_INIT` reset constant for every record.

```vhdl
type axi_w_t is record
  valid : std_logic;
  data  : std_logic_vector(31 downto 0);
  strb  : std_logic_vector(3 downto 0);
end record axi_w_t;

constant C_AXI_W_INIT : axi_w_t := (
  valid => '0',
  data  => (others => '0'),
  strb  => (others => '0')
);

signal wr_chan_r : axi_w_t;

p_wr : process(i_clk, i_rst_n)
begin
  if i_rst_n = '0' then
    wr_chan_r <= C_AXI_W_INIT;
  elsif rising_edge(i_clk) then
    if i_wr_valid = '1' then
      wr_chan_r.valid <= '1';
      wr_chan_r.data  <= i_wr_data;
      wr_chan_r.strb  <= i_wr_strb;
    end if;
  end if;
end process p_wr;
```

## VHDL Formatting (Additions)

- All keywords lowercase (`entity`, `architecture`, `signal`, `process`, `begin`, `end`).
- Always use explicit end tags: `end entity`, `end architecture rtl`, `end process p_name`, `end generate gen_name`.
- Use `--` for all comments.

## VHDL Anti-Patterns

1. Using `std_logic_arith` / `std_logic_unsigned` — use `numeric_std`.
2. Using `bit` / `bit_vector` — use `std_logic` / `std_logic_vector`.
3. Using `buffer` port mode — use `out` with internal signal.
4. Using `i_clk'event and i_clk = '1'` — use `rising_edge(i_clk)`.
5. `integer` for hardware signals — use `unsigned` / `signed`.
6. Missing process labels — always label with `p_` prefix.
7. Incomplete sensitivity lists (VHDL-93) — list every signal, or use `process(all)`.
8. `component` declarations — use direct entity instantiation.
9. Missing end tags — always write `end entity`, `end architecture rtl`, `end process p_name`.
10. Inferred latches — defaults at top of combinational processes.
11. Incomplete `case` — always include `when others`.
12. Multi-driven signals.
13. Magic numbers — use `G_` generics and `C_` constants.
14. Positional association in port/generic maps.
15. Unused signals without justification.

## VHDL Additional Notes

- Default to VHDL-2008 (`process(all)`) unless the project explicitly targets VHDL-93.
- Write idiomatic VHDL — do not write "Verilog-style" VHDL.

---

# Part 4 — Full Templates

## Verilog

```verilog
//-----------------------------------------------------------------------------
// Module : example_counter
// Purpose: Up-counter with enable and configurable width
// Author : <author>
// Date   : <date>
//-----------------------------------------------------------------------------
`default_nettype none

module example_counter #(
  parameter WIDTH = 8
) (
  // Clock & Reset
  input  wire               i_clk,
  input  wire               i_rst_n,

  // Inputs
  input  wire               i_en,
  input  wire               i_clear,

  // Outputs
  output wire [WIDTH-1:0]   o_count,
  output wire               o_wrap
);

  localparam MAX_VAL = {WIDTH{1'b1}};

  reg [WIDTH-1:0] count_r;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      count_r <= {WIDTH{1'b0}};
    end else if (i_clear) begin
      count_r <= {WIDTH{1'b0}};
    end else if (i_en) begin
      count_r <= count_r + 1'b1;
    end
  end

  assign o_count = count_r;
  assign o_wrap  = i_en & (count_r == MAX_VAL);

endmodule

`default_nettype wire
```

## SystemVerilog

```systemverilog
//-----------------------------------------------------------------------------
// Module : example_counter
// Purpose: Up-counter with enable and configurable width
// Author : <author>
// Date   : <date>
//-----------------------------------------------------------------------------
`default_nettype none

module example_counter #(
  parameter int unsigned WIDTH = 8
) (
  // Clock & Reset
  input  logic               i_clk,
  input  logic               i_rst_n,

  // Inputs
  input  logic               i_en,
  input  logic               i_clear,

  // Outputs
  output logic [WIDTH-1:0]   o_count,
  output logic               o_wrap
);

  localparam logic [WIDTH-1:0] MAX_VAL = {WIDTH{1'b1}};

  logic [WIDTH-1:0] count_r;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      count_r <= '0;
    end else if (i_clear) begin
      count_r <= '0;
    end else if (i_en) begin
      count_r <= count_r + 1'b1;
    end
  end

  assign o_count = count_r;
  assign o_wrap  = i_en & (count_r == MAX_VAL);

endmodule

`default_nettype wire
```

## VHDL

```vhdl
-------------------------------------------------------------------------------
-- Entity  : example_counter
-- Purpose : Up-counter with enable and configurable width
-- Author  : <author>
-- Date    : <date>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity example_counter is
  generic (
    G_WIDTH : natural := 8
  );
  port (
    -- Clock & Reset
    i_clk     : in  std_logic;
    i_rst_n   : in  std_logic;

    -- Inputs
    i_en      : in  std_logic;
    i_clear   : in  std_logic;

    -- Outputs
    o_count   : out std_logic_vector(G_WIDTH - 1 downto 0);
    o_wrap    : out std_logic
  );
end entity example_counter;

architecture rtl of example_counter is

  constant C_MAX_VAL : unsigned(G_WIDTH - 1 downto 0) := (others => '1');

  signal count_r : unsigned(G_WIDTH - 1 downto 0);

begin

  p_count : process(i_clk, i_rst_n)
  begin
    if i_rst_n = '0' then
      count_r <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_clear = '1' then
        count_r <= (others => '0');
      elsif i_en = '1' then
        count_r <= count_r + 1;
      end if;
    end if;
  end process p_count;

  o_count <= std_logic_vector(count_r);
  o_wrap  <= '1' when (i_en = '1') and (count_r = C_MAX_VAL) else '0';

end architecture rtl;
```
