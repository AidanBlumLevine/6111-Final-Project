`timescale 1ns / 1ps
`default_nettype none

module tb;
    logic clk_in;
    logic rst_in;
    logic [32:0] x_in;
    logic [32:0] y_in;
    logic [32:0] x_out;
    logic [32:0] y_out;
    logic [23:0] col_out;
    logic pixel_done, start;
    logic [31:0] ray_steps;

    logic signed [23:0] a;
    logic signed [23:0] b;
    logic signed [23:0] c;

    raymarcher #(
      .WIDTH(320),
      .HEIGHT(180)
    ) raym (
      .clk_in(clk_in),
      .rst_in(rst_in),
      .curr_x(x_in),
      .curr_y(y_in),
      .color_out(col_out),
      .pixel_done(pixel_done),
      .start_in(start),
      .out_x(x_out),
      .out_y(y_out),
      // ====================================
    .camera_x(to_fixed(0)),
    .camera_y(to_fixed(0)),
    .camera_z(to_fixed(100)),
    .camera_u_x(to_fixed(1)),
    .camera_u_y(to_fixed(0)),
    .camera_u_z(to_fixed(0)),
    .camera_v_x(to_fixed(0)),
    .camera_v_y(to_fixed(1)),
    .camera_v_z(to_fixed(0)),
    .camera_forward_x(to_fixed(0)),
    .camera_forward_y(to_fixed(0)),
    .camera_forward_z(to_fixed(-100))
    );

    always begin
        #15;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("raymarcher.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_in = 160;
        y_in = 90;
        start = 1;
        #30  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #30; //hold high for a few clock cycles
        rst_in=0;
        #300;
        while(!pixel_done)begin
          #30;
        end
        $display("rgb out = %d %d %d", col_out[23:16], col_out[15:8], col_out[7:0]);
        // for(y_in = 40; y_in < 47 * 3; y_in += 1) begin
        //   $display("y_in = %d", y_in);
        //   while(!pixel_done)begin
        //     #30;
        //   end
        //   $display("rgb out = %d, %d, %d", red_out, green_out, blue_out);
        //   #30;
        // end
        #30
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire   