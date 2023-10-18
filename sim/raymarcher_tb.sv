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
    logic pixel_done;
    logic [31:0] ray_dist_squared;
    logic [31:0] ray_steps;

    logic signed [23:0] a;
    logic signed [23:0] b;
    logic signed [23:0] c;

    raymarcher #(
      .WIDTH(300),
      .HEIGHT(300)
    ) raym (
      .clk_pixel_in(clk_in),
      .rst_in(rst_in),
      .curr_x(x_in),
      .curr_y(y_in),
      .red_out(red_out),
      .green_out(green_out),
      .blue_out(blue_out),
      .pixel_done(pixel_done),
      .ray_dist_squared(ray_dist_squared),
      .ray_steps(ray_steps)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("raymarcher.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_in = 150;
        y_in = 150;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        a = dec_to_16_8(3);
        b = dec_to_16_8(-1);
        $display("a = %h", a);
        $display("b = %h", b);
        a = mult_16_8(a, b);
        $display("prod = %h", a);
        a = dec_to_16_8(3);
        b = dec_to_16_8(4);
        c = dec_to_16_8(0);
        // a = mult_16_8(a, a);
        // b = mult_16_8(b, b);
        $display("a^2 = %h", mult_16_8(a, a));
        $display("b^2 = %h", mult_16_8(b, b));
        $display("c^2 = %h", mult_16_8(c, c));
        $display("magsq 3,4,0 = %h", square_mag(a,b,c));
        #10;

        for (int i = 0; i<150; i= i+1)begin
          $display("i = %d", i);
          $display("ray steps = %d", ray_steps);
          $display("ray dist squared = %h", ray_dist_squared);
          $display("pixel_done = %d", pixel_done);
          #10;
        end
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire   