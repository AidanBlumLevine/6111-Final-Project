`timescale 1ns / 1ps
`default_nettype none

module tb;
    logic clk_in;
    logic rst_in;
    logic [32:0] x_in;
    logic [32:0] y_in;
    logic [32:0] x_out;
    logic [32:0] y_out;
    logic [7:0] red_out;
    logic [7:0] green_out;
    logic [7:0] blue_out;
    logic pixel_done;
    logic [31:0] ray_steps;

    logic signed [23:0] a;
    logic signed [23:0] b;
    logic signed [23:0] c;

    raymarcher #(
      .WIDTH(300),
      .HEIGHT(300)
    ) raym (
      .clk_in(clk_in),
      .rst_in(rst_in),
      .curr_x(x_in),
      .curr_y(y_in),
      .red_out(red_out),
      .green_out(green_out),
      .blue_out(blue_out),
      .pixel_done(pixel_done),
      .out_x(x_out),
      .out_y(y_out)
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
        x_in = 300;
        y_in = 300;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        // a = dec_to_24_8(3);
        // b = dec_to_24_8(-1);
        // $display("a = %h", a);
        // $display("b = %h", b);
        // a = mult_24_8(a, b);
        // $display("prod = %h", a);
        // a = dec_to_24_8(3);
        // b = dec_to_24_8(4);
        // c = dec_to_24_8(0);
        // // a = mult_24_8(a, a);
        // // b = mult_24_8(b, b);
        // $display("a^2 = %h", mult_24_8(a, a));
        // $display("b^2 = %h", mult_24_8(b, b));
        // $display("c^2 = %h", mult_24_8(c, c));
        // $display("magsq 3,4,0 = %h", square_mag(a,b,c));
        
        #10;



        while(!pixel_done)begin
          // x_in = 100;
          // $display("i = %d", i);
          // $display("ray steps = %d", ray_steps);
          // $display("pixel_done = %d", pixel_done);
          #10;
        end
        // $display("pixel_done = %d", pixel_done);
        // $display("x out = %d", x_out);
        // $display("y out = %d", y_out);
        #10
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire   