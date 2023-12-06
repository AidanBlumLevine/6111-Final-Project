`timescale 1ns / 1ps
`default_nettype none

module tb_menger;

  logic clk_in;
  logic rst_in;
  logic sdf_start;
  logic sdf_done;
  logic signed [31:0] sdf_out;
  logic [31:0] ray_x;
  logic [31:0] ray_y;
  logic [31:0] ray_z;
  logic [7:0] sdf_red_out;
  logic [7:0] sdf_blue_out;
  logic [7:0] sdf_green_out;


  menger_sdf menger_sdf_inst (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sdf_start(sdf_start),
    .x(ray_x),
    .y(ray_y),
    .z(ray_z),
    .sdf_done(sdf_done),
    .sdf_out(sdf_out),
    .sdf_red_out(sdf_red_out),
    .sdf_green_out(sdf_green_out),
    .sdf_blue_out(sdf_blue_out)
  );

  always begin
    #15;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
    clk_in = !clk_in;
  end

  initial begin
    $display("Starting Sim"); //print nice message
    clk_in = 0; //initialize clk (super important)
    rst_in = 0; //initialize rst (super important)

    #30;  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #30; //hold high for a few clock cycles
    rst_in=0;
    #30;

    ray_x = to_fixed(0);
    ray_y = to_fixed(0);
    ray_z = to_fixed(23);
    sdf_start = 1;

    while(!sdf_done)begin
      #30;
    end
    sdf_start = 0;
    $display("SDF OUT:",$signed(sdf_out) >>> 16);
    #30;
    
    // ray_x = to_fixed(100);
    // ray_y = to_fixed(15);
    // ray_z = to_fixed(22);
    // sdf_start = 1;


    // while(!sdf_done)begin
    //   #30;
    // end

    // $display("SDF OUT:",sdf_out);
    // #30;

    // ray_x = to_fixed(200);
    // ray_y = to_fixed(30);
    // ray_z = to_fixed(25);
    // sdf_start = 1;

    // while(!sdf_done)begin
    //   #30;
    // end

    // $display("SDF OUT:",sdf_out);
    // #30;

    $display("Finishing Sim"); //print nice message
    $finish;
  end

endmodule
