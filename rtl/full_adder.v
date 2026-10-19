// full_adder.v : adds three bits, produces a sum bit and a carry bit
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    assign sum  = a ^ b ^ cin;                       // 1 when an odd number of inputs are 1
    assign cout = (a & b) | (b & cin) | (a & cin);   // 1 when at least two inputs are 1

endmodule