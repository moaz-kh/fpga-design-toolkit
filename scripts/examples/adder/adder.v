// 8-bit Ripple Carry Adder with Carry Out
// Auto-generated example for digital design project

module adder(
    input  [7:0] a,      // First operand
    input  [7:0] b,      // Second operand
    input        cin,    // Carry input
    output [7:0] sum,    // Sum output
    output       cout    // Carry output
);

    // Internal carry signals
    wire [6:0] carry;

    // Full adder instances
    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(cin),     .sum(sum[0]), .cout(carry[0]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(carry[0]), .sum(sum[1]), .cout(carry[1]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(carry[1]), .sum(sum[2]), .cout(carry[2]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(carry[2]), .sum(sum[3]), .cout(carry[3]));
    full_adder fa4 (.a(a[4]), .b(b[4]), .cin(carry[3]), .sum(sum[4]), .cout(carry[4]));
    full_adder fa5 (.a(a[5]), .b(b[5]), .cin(carry[4]), .sum(sum[5]), .cout(carry[5]));
    full_adder fa6 (.a(a[6]), .b(b[6]), .cin(carry[5]), .sum(sum[6]), .cout(carry[6]));
    full_adder fa7 (.a(a[7]), .b(b[7]), .cin(carry[6]), .sum(sum[7]), .cout(cout));

endmodule

// Full Adder Module
module full_adder(
    input  a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
