`timescale 1ns / 1ps

// sync moduel to sync a signal with widht WIDTH using a clock CLK
module synchronizer #(parameter WIDTH=3) 
(input i_clk, i_rst_n, input [WIDTH-1:0] d_in, output reg [WIDTH-1:0] d_out);
  reg [WIDTH-1:0] q1;
  always@(posedge i_clk) begin
    if(!i_rst_n) begin
      q1 <= 0;
      d_out <= 0;
    end
    else begin
      q1 <= d_in;
      d_out <= q1;
    end
  end
endmodule
 
// edge detector moduel to detect both positive and negative edges 
module edge_detector #(parameter sync_sig = 0)(
input i_clk, i_rst_n,
input i_sig, 
output o_pos_edge, o_neg_edge);

wire i_sig_sync;
reg sig_sync;

synchronizer #(.WIDTH(1)) i_sig_sync_u
(.i_clk(i_clk), .i_rst_n(i_rst_n), .d_in(i_sig), .d_out(i_sig_sync));

always @* 
begin 
	if(sync_sig == 1)  
		 sig_sync <= i_sig_sync ;
	else  
		 sig_sync <= i_sig ; 
end 
	 
reg sig_dly;
assign o_pos_edge = sig_sync  & ~sig_dly;  
assign o_neg_edge = ~sig_sync & sig_dly;  
always@(posedge i_clk) 
begin 
    if(~i_rst_n)
    begin 
        sig_dly <= 1'b0; 
    end 
    else
    begin  
        sig_dly <= sig_sync;  
    end
end 

endmodule
 
// a led module to make a led blinking by some configuratino using 
// time_count which is the total time of working for the led 
// toggle_count which is the time to be on/off for each cycle of toggeling 
// these two parametes are decided intermes of i_clk cycles 
module LED_logic (
    input i_clk, i_rst_n,  
    input i_sig,
    output reg o_led
    );

parameter sync_sig = 0;
// when we have our clk with freq 50 MHZ 
// 1 sec will take 50*10^6 clk cycles 
parameter time_count   = 50000000;
// 100ms
parameter toggle_count = 5000000;

wire i_sig_sync;
reg sig_sync;

synchronizer #(.WIDTH(1)) i_sig_sync_u
(.i_clk(i_clk), .i_rst_n(i_rst_n), .d_in(i_sig), .d_out(i_sig_sync));

always @* 
begin 
	if(sync_sig == 1)  
		 sig_sync <= i_sig_sync ;
	else  
		 sig_sync <= i_sig ; 
end 
	 
	 
// search for posedge of the sig to start 
wire sig_posedge, sig_negedge;
edge_detector u_fifo_empty_edge (
    .i_clk(i_clk), .i_rst_n(i_rst_n),  
    .i_sig(sig_sync), 
    .o_pos_edge(sig_posedge), .o_neg_edge(sig_negedge)
    );
 
integer count;
integer tog_count;
integer time_out;
reg start_count;  
always@(posedge i_clk)  
begin 
    if(~i_rst_n)
    begin 
        count   <=  0; 
        tog_count   <=  0; 
        start_count   <=  0; 
        o_led   <=  0;  
    end 
    else 
    begin  
    
        if(sig_posedge)   // once posedge we start working 
        begin 
            start_count <= 1; 
        end 
        
        if(start_count)  
        begin
            count       <=  count + 1;
            
            // toggle operation 
            if (tog_count == 2*toggle_count)  tog_count   <=  0;
            else                              tog_count   <=  tog_count + 1; 
            
            if  (tog_count < toggle_count)  o_led   <=  1;  
            else                            o_led   <=  0; 
             
            // termination of led operatino after time_count cycles 
            if(count == time_count)
            begin 
                count         <=  0; 
                tog_count     <=  0; 
                start_count   <=  0;
                o_led         <=  0; 
            end 
        end 
    end  
end     
endmodule

module spi_interface_debounce (
    input         i_clk,           // 200 MHz system clock (5 ns period)
    input         i_rst_n,         // active-low reset
    
    // Raw SPI inputs
    input         spi_clk_raw,   // raw SPI clock (possibly noisy)
    input         spi_mosi_raw,  // raw SPI MOSI (possibly noisy)
    input         spi_cs_n_raw,  // raw SPI CS_n (possibly noisy)
    
    // Debounced SPI outputs
    output reg    spi_clk_db,    // debounced SPI clock output
    output reg    spi_mosi_db,   // debounced SPI MOSI output
    output reg    spi_cs_n_db    // debounced SPI CS_n output
);

    // Synchronize all three asynchronous SPI signals into the 200 MHz domain.
    reg spi_clk_sync0, spi_clk_sync1;
    reg spi_mosi_sync0, spi_mosi_sync1;
    reg spi_cs_n_sync0, spi_cs_n_sync1;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Reset all synchronization registers
            spi_clk_sync0 <= 1'b0;
            spi_clk_sync1 <= 1'b0;
            spi_mosi_sync0 <= 1'b0;
            spi_mosi_sync1 <= 1'b0;
            spi_cs_n_sync0 <= 1'b1; // Active low, default high
            spi_cs_n_sync1 <= 1'b1;
        end else begin
            // Synchronize all signals
            spi_clk_sync0 <= spi_clk_raw;
            spi_clk_sync1 <= spi_clk_sync0;
            spi_mosi_sync0 <= spi_mosi_raw;
            spi_mosi_sync1 <= spi_mosi_sync0;
            spi_cs_n_sync0 <= spi_cs_n_raw;
            spi_cs_n_sync1 <= spi_cs_n_sync0;
        end
    end

    // Debounce logic: require the new state to be stable for DEBOUNCE_COUNT consecutive cycles
    parameter DEBOUNCE_COUNT = 2;
    
    // Separate counters for each signal
    reg [1:0] clk_stable_cnt;
    reg [1:0] mosi_stable_cnt;
    reg [1:0] cs_n_stable_cnt;

    // Debounce logic for SPI clock
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            clk_stable_cnt <= 2'd0;
            spi_clk_db <= spi_clk_sync1; // Initialize debounced output
        end else begin
            if (spi_clk_sync1 == spi_clk_db) begin
                // Input matches current debounced state; reset counter
                clk_stable_cnt <= 2'd0;
            end else begin
                // Input is different; increment counter
                clk_stable_cnt <= clk_stable_cnt + 2'd1;
                // When the new state is stable for DEBOUNCE_COUNT cycles, update the output
                if (clk_stable_cnt >= (DEBOUNCE_COUNT - 1)) begin
                    spi_clk_db <= spi_clk_sync1;
                    clk_stable_cnt <= 2'd0;
                end
            end
        end
    end

    // Debounce logic for SPI MOSI
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            mosi_stable_cnt <= 2'd0;
            spi_mosi_db <= spi_mosi_sync1; // Initialize debounced output
        end else begin
            if (spi_mosi_sync1 == spi_mosi_db) begin
                // Input matches current debounced state; reset counter
                mosi_stable_cnt <= 2'd0;
            end else begin
                // Input is different; increment counter
                mosi_stable_cnt <= mosi_stable_cnt + 2'd1;
                // When the new state is stable for DEBOUNCE_COUNT cycles, update the output
                if (mosi_stable_cnt >= (DEBOUNCE_COUNT - 1)) begin
                    spi_mosi_db <= spi_mosi_sync1;
                    mosi_stable_cnt <= 2'd0;
                end
            end
        end
    end

    // Debounce logic for SPI CS_n
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cs_n_stable_cnt <= 2'd0;
            spi_cs_n_db <= spi_cs_n_sync1; // Initialize debounced output
        end else begin
            if (spi_cs_n_sync1 == spi_cs_n_db) begin
                // Input matches current debounced state; reset counter
                cs_n_stable_cnt <= 2'd0;
            end else begin
                // Input is different; increment counter
                cs_n_stable_cnt <= cs_n_stable_cnt + 2'd1;
                // When the new state is stable for DEBOUNCE_COUNT cycles, update the output
                if (cs_n_stable_cnt >= (DEBOUNCE_COUNT - 1)) begin
                    spi_cs_n_db <= spi_cs_n_sync1;
                    cs_n_stable_cnt <= 2'd0;
                end
            end
        end
    end

endmodule