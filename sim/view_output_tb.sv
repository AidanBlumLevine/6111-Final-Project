`timescale 1ns / 1ps
`default_nettype none

module tb_view;

  logic clk;
  logic rst;
  logic signed [32-1:0] camera_u_x;
  logic signed [32-1:0] camera_u_y;
  logic signed [32-1:0] camera_u_z;
  logic signed [32-1:0] camera_v_x;
  logic signed [32-1:0] camera_v_y;
  logic signed [32-1:0] camera_v_z;
  logic signed [32-1:0] camera_forward_x;
  logic signed [32-1:0] camera_forward_y;
  logic signed [32-1:0] camera_forward_z;
  view_output_simple vi(
      .clk_100mhz(clk),
      .rst_in(rst),
      .pitch(9'd45),
      .roll(9'd0),
      .yaw(9'd30),
      .x_forward(camera_forward_x),
      .y_forward(camera_forward_y),
      .z_forward(camera_forward_z),
      .x_up(camera_u_x),
      .y_up(camera_u_y),
      .z_up(camera_u_z),
      .x_right(camera_v_x),
      .y_right(camera_v_y),
      .z_right(camera_v_z)
  ); 

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    #10 rst = 0;

    #1000;

    // print all three vectors
    $display("Camera Forward: (%d/16, %d/16, %d/16)", $signed(camera_forward_x)>>>12, $signed(camera_forward_y)>>>12, $signed(camera_forward_z)>>>12);
    $display("Camera Up: (%d/16, %d/16, %d/16)", $signed(camera_u_x)>>>12, $signed(camera_u_y)>>>12, $signed(camera_u_z)>>>12);
    $display("Camera Right: (%d/16, %d/16, %d/16)", $signed(camera_v_x)>>>12, $signed(camera_v_y)>>>12, $signed(camera_v_z)>>>12);

    $finish;
  end

endmodule
