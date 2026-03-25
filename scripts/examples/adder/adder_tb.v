// Testbench for 8-bit Ripple Carry Adder
`timescale 1ns / 1ps

module adder_tb;

    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] sum;
    wire       cout;

    reg  [8:0] expected;
    integer    fail_count;

    adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    task check;
        input [63:0] test_name;
        begin
            #10;
            expected = a + b + cin;
            if ({cout, sum} !== expected) begin
                $display("FAIL [%s]: a=%02h b=%02h cin=%b => got %02h cout=%b, expected %02h cout=%b",
                    test_name, a, b, cin, sum, cout,
                    expected[7:0], expected[8]);
                fail_count = fail_count + 1;
            end else
                $display("PASS [%s]", test_name);
        end
    endtask

    initial begin
        $dumpfile("sim/waves/adder_tb.vcd");
        $dumpvars(0, adder_tb);

        fail_count = 0;
        $display("=== 8-bit Adder Testbench ===");

        // Zero cases
        a = 8'h00; b = 8'h00; cin = 0; check("zero+zero      ");
        a = 8'h00; b = 8'h00; cin = 1; check("zero+zero+cin  ");

        // Basic addition
        a = 8'h0F; b = 8'h01; cin = 0; check("basic add      ");
        a = 8'h0F; b = 8'h01; cin = 1; check("basic add+cin  ");

        // Carry out
        a = 8'hF0; b = 8'h20; cin = 0; check("carry out      ");

        // Carry propagation (0xFF + 1 ripples through all bits)
        a = 8'hFF; b = 8'h01; cin = 0; check("carry propagate");

        // Max values with carry in
        a = 8'hFF; b = 8'hFF; cin = 1; check("max+max+cin    ");

        // Identity (a + 0 = a)
        a = 8'hA5; b = 8'h00; cin = 0; check("identity       ");

        // Signed overflow boundary (0x7F + 1 = 0x80)
        a = 8'h7F; b = 8'h01; cin = 0; check("signed overflow");

        // MSB carry (0x80 + 0x80)
        a = 8'h80; b = 8'h80; cin = 0; check("msb carry      ");

        $display("=== Done: %0d failure(s) ===", fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
