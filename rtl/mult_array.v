// mult_array.v : 4x4 unsigned array multiplier, registered inputs and output
module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    reg  [3:0] a_r, b_r;   // input registers
    wire [7:0] prod;       // result from the array (built in Step 4b)

    // All 16 flip-flops: capture on the rising clock edge, clear on reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r <= 4'b0000;
            b_r <= 4'b0000;
            p   <= 8'b0;
        end else begin
            a_r <= a;
            b_r <= b;
            p   <= prod;
        end
    end

    // ---- Array goes here (Step 4b) ----
    // Partial products: ppi[j] = a_r[j] AND b_r[i]  (16 AND gates)
    wire [3:0] pp0, pp1, pp2, pp3;
    assign pp0 = a_r & {4{b_r[0]}};
    assign pp1 = a_r & {4{b_r[1]}};
    assign pp2 = a_r & {4{b_r[2]}};
    assign pp3 = a_r & {4{b_r[3]}};

    // Row 0: p[0] = pp0[0]; pass down the top 3 bits with a 0 on top
    wire [3:0] r0;
    assign r0 = {1'b0, pp0[3:1]};

    // Row 1: adds pp1 + r0
    wire [3:0] s1;     // 4 sum outputs
    wire [4:0] c1;     // carries: c1[0] is the input carry, c1[4] is the final carry
    assign c1[0] = 1'b0;

    full_adder fa1_0 (.a(pp1[0]), .b(r0[0]), .cin(c1[0]), .sum(s1[0]), .cout(c1[1]));
    full_adder fa1_1 (.a(pp1[1]), .b(r0[1]), .cin(c1[1]), .sum(s1[1]), .cout(c1[2]));
    full_adder fa1_2 (.a(pp1[2]), .b(r0[2]), .cin(c1[2]), .sum(s1[2]), .cout(c1[3]));
    full_adder fa1_3 (.a(pp1[3]), .b(r0[3]), .cin(c1[3]), .sum(s1[3]), .cout(c1[4]));

    wire [3:0] r1;
    assign r1 = {c1[4], s1[3:1]};   // pass down: final carry + top 3 sums (s1[0] becomes p[1])

    // Row 2: adds pp2 + r1
    wire [3:0] s2;     // 4 sum outputs
    wire [4:0] c2;     // carries: c2[0] is the input carry, c2[4] is the final carry
    assign c2[0] = 1'b0;

    full_adder fa2_0 (.a(pp2[0]), .b(r1[0]), .cin(c2[0]), .sum(s2[0]), .cout(c2[1]));
    full_adder fa2_1 (.a(pp2[1]), .b(r1[1]), .cin(c2[1]), .sum(s2[1]), .cout(c2[2]));
    full_adder fa2_2 (.a(pp2[2]), .b(r1[2]), .cin(c2[2]), .sum(s2[2]), .cout(c2[3]));
    full_adder fa2_3 (.a(pp2[3]), .b(r1[3]), .cin(c2[3]), .sum(s2[3]), .cout(c2[4]));

    wire [3:0] r2;
    assign r2 = {c2[4], s2[3:1]};   // pass down: final carry + top 3 sums (s2[0] becomes p[2])

    // Row 3: adds pp3 + r2
    wire [3:0] s3;     // 4 sum outputs
    wire [4:0] c3;     // carries: c3[0] is the input carry, c3[4] is the final carry
    assign c3[0] = 1'b0;

    full_adder fa3_0 (.a(pp3[0]), .b(r2[0]), .cin(c3[0]), .sum(s3[0]), .cout(c3[1]));
    full_adder fa3_1 (.a(pp3[1]), .b(r2[1]), .cin(c3[1]), .sum(s3[1]), .cout(c3[2]));
    full_adder fa3_2 (.a(pp3[2]), .b(r2[2]), .cin(c3[2]), .sum(s3[2]), .cout(c3[3]));
    full_adder fa3_3 (.a(pp3[3]), .b(r2[3]), .cin(c3[3]), .sum(s3[3]), .cout(c3[4]));

    // no need of r3; lol

    // Product: p[7:4] = {c3[4], s3[3:1]}, p[3]=s3[0], p[2]=s2[0], p[1]=s1[0], p[0]=pp0[0]
    assign prod = {c3[4], s3[3:0], s2[0], s1[0], pp0[0]};

endmodule