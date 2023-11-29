`timescale 1ns / 1ps
`default_nettype none

module tb_sqrt;
    logic clk;
    logic start;
    logic busy;
    logic valid;
    logic [31:0] rad;
    logic [31:0] root;
    logic [31:0] rem;

    sqrt #(
        .WIDTH(32),
        .FBITS(16)
    ) sqrt_inst (
        .clk(clk),
        .start(start),
        .busy(busy),
        .valid(valid),
        .rad(rad),
        .root(root),
        .rem(rem)
    );

    always begin
        #5;
        clk = !clk;
    end

    initial begin
        $dumpfile("sqrt_tb.vcd");
        $dumpvars(0, tb_sqrt);
        $display("Starting Sim");
        clk = 0;
        start = 1;
        rad = 32'h00020000; // Input: 2.0
        #10;
        start = 0;
        while (!valid) begin
            #1;
        end
        $display("inv_sqrt(2.0) = %d/16", root>>>12);

        start = 1;
        rad = 32'h00040000; // Input: 4.0
        #10;
        start = 0;
        while (!valid) begin
            #1;
        end
        $display("inv_sqrt(3.0) = %d/16", root>>>12);

        start = 1;
        rad = 32'h00100000; // Input: 16
        #10;
        start = 0;
        while (!valid) begin
            #1;
        end
        $display("inv_sqrt(10.0) = %d/16", root>>>12);

        // input .125
        start = 1;
        rad = 32'h00002000;
        #10;
        start = 0;
        while (!valid) begin
            #1;
        end
        $display("inv_sqrt(0.125) = %d/16", root>>>12);

        // input 144
        start = 1;
        rad = 32'h00900000;
        #10;
        start = 0;
        while (!valid) begin
            #1;
        end
        $display("inv_sqrt(144) = %d/16", root>>>12);

        #10
        $display("Finishing Sim");
        $finish;
    end
endmodule // tb_sqrt

`default_nettype wire
