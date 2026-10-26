// tb_mult.v : exhaustive self-checking testbench for mult_array
`timescale 1ns/1ps

module tb_mult;

    reg        clk = 0;
    reg        rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;
    integer i, j, errors, count;

    // Device under test
    mult_array dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p));

    // 10 ns clock: flip every 5 ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");        // waveform file
        $dumpvars(0, tb_mult);        // record every signal in the design

        errors = 0;
        count  = 0;
        a      = 0;
        b      = 0;

        // Reset: hold rst_n low for 2 clock cycles
        rst_n = 0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // Try all 256 combinations
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i;                 // apply inputs (we are at a falling edge)
                b = j;
                @(posedge clk);        // edge 1: inputs captured into a_r, b_r
                @(posedge clk);        // edge 2: product captured into p
                @(negedge clk);        // half a cycle later: p is stable

                count = count + 1;
                if (p !== i * j) begin
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d", i, j, i * j, p);
                    errors = errors + 1;
                end
            end
        end

        // Exactly one summary line
        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", count);
        else
            $display("FAIL: %0d vectors checked, %0d errors", count, errors);

        $finish;
    end

endmodule