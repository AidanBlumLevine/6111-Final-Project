`timescale 1ns / 1ps
`default_nettype none

module tb;
    logic clk_in;
    logic rst_in;
    logic [32:0] x_in;
    logic [32:0] y_in;
    logic [7:0] red_out;
    logic [7:0] green_out;
    logic [7:0] blue_out;

    renderer #(
      .WIDTH(320),
      .HEIGHT(180)
    ) raym (
      .clk_pixel_in(clk_in),
      .rst_in(rst_in),
      .hcount_in(x_in),
      .vcount_in(y_in),
      .red_out(red_out),
      .green_out(green_out),
      .blue_out(blue_out) 
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("renderer.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_in = 10;
        y_in = 10;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;


        x_in = i;
        y_in = 300-i;


        #10
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire   