`timescale 1ns / 1ps
`default_nettype none

module tb_view_output;
  reg clk_100mhz;
  reg rst_in;
  reg [31:0] pitch, roll, yaw;
  wire signed [31:0] x_forward, y_forward, z_forward, x_up, y_up, z_up, x_right, y_right, z_right;

  // Instantiate the module
  view_output dut (
    .clk_100mhz(clk_100mhz),
    .rst_in(rst_in),
    .pitch(pitch),
    .roll(roll),
    .yaw(yaw),
    .x_forward(x_forward),
    .y_forward(y_forward),
    .z_forward(z_forward),
    .x_up(x_up),
    .y_up(y_up),
    .z_up(z_up),
    .x_right(x_right),
    .y_right(y_right),
    .z_right(z_right)
  );

  initial begin
    clk_100mhz = 0;
    forever #5 clk_100mhz = ~clk_100mhz;
  end

  initial begin
    rst_in = 1; // Assert reset initially
    pitch = 90; // Set pitch value
    roll = 32'b0; // Set roll value
    yaw = 32'b0; // Set yaw value

    #10; // Release reset
    rst_in = 0;

    // Apply inputs and observe outputs after some time
    // Set values for pitch, roll, yaw
    #100000;
    $display("Time=%0t, X_Forward=%0d/16, Y_Forward=%0d/16, Z_Forward=%0d/16", $time, x_forward>>>12, y_forward>>>12, z_forward >>> 12);
    $display("Time=%0t, X_Up=%0d/16, Y_Up=%0d/16, Z_Up=%0d/16", $time, x_up>>>12, y_up>>>12, z_up >>> 12);
    $display("Time=%0t, X_Right=%0d/16, Y_Right=%0d/16, Right=%0d/16", $time, x_right>>>12, y_right>>>12, z_right >>> 12);
    #10; // Finishing simulation
    $finish;
  end

endmodule
`default_nettype wire