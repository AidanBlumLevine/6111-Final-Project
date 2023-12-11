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
      .pitch(20),
      .roll(0),
      .yaw(20),
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
    $display("Camera Forward: (%d, %d, %d)", $signed(camera_forward_x), $signed(camera_forward_y), $signed(camera_forward_z));
    $display("Camera Up: (%d, %d, %d)", $signed(camera_u_x), $signed(camera_u_y), $signed(camera_u_z));
    $display("Camera Right: (%d, %d, %d)", $signed(camera_v_x), $signed(camera_v_y), $signed(camera_v_z));

    $finish;
  end

endmodule
