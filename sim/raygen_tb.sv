`timescale 1ns / 1ps
`default_nettype none

module tb;
    logic clk_in;
    logic rst_in;
    logic start;
    logic done;
    logic [31:0] x_out;
    logic [31:0] y_out;
    logic [31:0] z_out;
    logic [31:0] x_in;
    logic [31:0] y_in;
    logic [31:0] z_in;

    ray_gen ray_gen(
      .clk_in(clk_in),
      .rst_in(rst_in),
      .ray_gen_start(start),
      .ray_gen_done(done),
      .ray_gen_out_x(x_out),
      .ray_gen_out_y(y_out),
      .ray_gen_out_z(z_out),
      .ray_gen_in_x(x_in),
      .ray_gen_in_y(y_in),
      .ray_gen_in_z(z_in)
    );

    
    always begin
        #5;
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("raygen.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;

        start = 1;
        x_in = 1 << 16;
        y_in = 1 << 16;
        z_in = 1 << 16;
        #10;
        start = 0;
        while(!done) begin
            #1;
        end
        $display("x_out = %d/16", x_out >> 12);
        $display("y_out = %d/16", y_out >> 12);
        $display("z_out = %d/16", z_out >> 12);


        start = 1;
        x_in = 1 << 16;
        y_in = 0;
        z_in = 1 << 16;
        #10;
        start = 0;
        while(!done) begin
            #1;
        end
        $display("x_out = %d/16", x_out >> 12);
        $display("y_out = %d/16", y_out >> 12);
        $display("z_out = %d/16", z_out >> 12);

        start = 1;
        x_in = 1 << 16;
        y_in = 1 << 12;
        z_in = 1 << 12;
        #10;
        start = 0;
        while(!done) begin
            #1;
        end
        $display("x_out = %d/16", x_out >> 12);
        $display("y_out = %d/16", y_out >> 12);
        $display("z_out = %d/16", z_out >> 12);

        #10
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire   