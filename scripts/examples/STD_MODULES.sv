//-----------------------------------------------------------------------------
// File    : STD_MODULES.sv
// Purpose : Standard utility modules — synchronizer, edge_detector,
//           LED_logic, spi_interface_debounce
// Author  : <author>
// Date    : <date>
//-----------------------------------------------------------------------------
`default_nettype none


//-----------------------------------------------------------------------------
// Module  : synchronizer
// Purpose : Multi-bit two-flop clock-domain crossing synchroniser
//-----------------------------------------------------------------------------
module synchronizer #(
  parameter int unsigned WIDTH = 3
) (
  input  logic               i_clk,
  input  logic               i_rst_n,
  input  logic [WIDTH-1:0]   i_data,
  output logic [WIDTH-1:0]   o_data
);

  logic [WIDTH-1:0] q1;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      q1     <= '0;
      o_data <= '0;
    end else begin
      q1     <= i_data;
      o_data <= q1;
    end
  end

endmodule


//-----------------------------------------------------------------------------
// Module  : edge_detector
// Purpose : Positive- and negative-edge detector; optionally synchronises input
// Params  : SYNC_SIG — 0: use i_sig directly  1: pass through synchronizer first
//-----------------------------------------------------------------------------
module edge_detector #(
  parameter int unsigned SYNC_SIG = 0
) (
  input  logic i_clk,
  input  logic i_rst_n,
  input  logic i_sig,
  output logic o_pos_edge,
  output logic o_neg_edge
);

  logic sig_sync;
  logic sig_dly;

  generate
    if (SYNC_SIG) begin : gen_sync
      logic sig_synced;
      synchronizer #(.WIDTH(1)) u_sync (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_data  (i_sig),
        .o_data  (sig_synced)
      );
      assign sig_sync = sig_synced;
    end else begin : gen_no_sync
      assign sig_sync = i_sig;
    end
  endgenerate

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      sig_dly <= '0;
    end else begin
      sig_dly <= sig_sync;
    end
  end

  assign o_pos_edge = sig_sync & ~sig_dly;
  assign o_neg_edge = ~sig_sync & sig_dly;

endmodule


//-----------------------------------------------------------------------------
// Module  : LED_logic
// Purpose : LED blinker — activates on i_sig rising edge, toggles for
//           TIME_COUNT cycles at TOGGLE_COUNT on/off half-period
// Params  : SYNC_SIG     — 0: use i_sig directly  1: synchronise first
//           TIME_COUNT   — total active duration in i_clk cycles
//                          default = 1 s at 50 MHz
//           TOGGLE_COUNT — LED on/off half-period in i_clk cycles
//                          default = 100 ms at 50 MHz
//-----------------------------------------------------------------------------
module LED_logic #(
  parameter int unsigned SYNC_SIG     = 0,
  parameter int unsigned TIME_COUNT   = 50_000_000,
  parameter int unsigned TOGGLE_COUNT =  5_000_000
) (
  input  logic i_clk,
  input  logic i_rst_n,
  input  logic i_sig,
  output logic o_led
);

  logic sig_sync;
  logic sig_posedge;

  generate
    if (SYNC_SIG) begin : gen_sync
      logic sig_synced;
      synchronizer #(.WIDTH(1)) u_sync (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_data  (i_sig),
        .o_data  (sig_synced)
      );
      assign sig_sync = sig_synced;
    end else begin : gen_no_sync
      assign sig_sync = i_sig;
    end
  endgenerate

  edge_detector #(.SYNC_SIG(0)) u_edge (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),
    .i_sig      (sig_sync),
    .o_pos_edge (sig_posedge),
    .o_neg_edge ()
  );

  logic [31:0] count_r;
  logic [31:0] tog_count_r;
  logic        start_r;

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      count_r     <= '0;
      tog_count_r <= '0;
      start_r     <= '0;
      o_led       <= '0;
    end else begin
      if (sig_posedge) begin
        start_r <= 1'b1;
      end

      if (start_r) begin
        count_r <= count_r + 1;

        if (tog_count_r == 2 * TOGGLE_COUNT) begin
          tog_count_r <= '0;
        end else begin
          tog_count_r <= tog_count_r + 1;
        end

        o_led <= (tog_count_r < TOGGLE_COUNT) ? 1'b1 : 1'b0;

        if (count_r == TIME_COUNT) begin
          count_r     <= '0;
          tog_count_r <= '0;
          start_r     <= '0;
          o_led       <= '0;
        end
      end
    end
  end

endmodule


//-----------------------------------------------------------------------------
// Module  : spi_interface_debounce
// Purpose : Two-flop synchroniser + counter debounce for SPI clk, MOSI, CS_n
// Params  : DEBOUNCE_COUNT — stable-cycle threshold before output updates
//-----------------------------------------------------------------------------
module spi_interface_debounce #(
  parameter int unsigned DEBOUNCE_COUNT = 2
) (
  input  logic i_clk,
  input  logic i_rst_n,

  // Raw SPI inputs
  input  logic spi_clk_raw,
  input  logic spi_mosi_raw,
  input  logic spi_cs_n_raw,

  // Debounced SPI outputs
  output logic spi_clk_db,
  output logic spi_mosi_db,
  output logic spi_cs_n_db
);

  localparam int unsigned CNT_W         = $clog2(DEBOUNCE_COUNT + 1);
  localparam int unsigned STABLE_THRESH = DEBOUNCE_COUNT - 1;

  logic [2:0] spi_sync;

  synchronizer #(.WIDTH(3)) u_spi_sync (
    .i_clk   (i_clk),
    .i_rst_n (i_rst_n),
    .i_data  ({spi_cs_n_raw, spi_mosi_raw, spi_clk_raw}),
    .o_data  (spi_sync)
  );

  logic [2:0]          spi_db_r;
  logic [CNT_W-1:0]    stable_cnt [2:0];

  generate
    for (genvar ii = 0; ii < 3; ii++) begin : gen_debounce
      always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          stable_cnt[ii] <= '0;
          spi_db_r[ii]   <= '0;
        end else begin
          if (spi_sync[ii] == spi_db_r[ii]) begin
            stable_cnt[ii] <= '0;
          end else begin
            stable_cnt[ii] <= stable_cnt[ii] + 1'b1;
            if (stable_cnt[ii] >= STABLE_THRESH) begin
              spi_db_r[ii]   <= spi_sync[ii];
              stable_cnt[ii] <= '0;
            end
          end
        end
      end
    end
  endgenerate

  assign {spi_cs_n_db, spi_mosi_db, spi_clk_db} = spi_db_r;

endmodule


`default_nettype wire
