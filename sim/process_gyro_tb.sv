`timescale 1ns / 1ps
`default_nettype none

module tb_process_gyro;
  reg clk_100mhz;
  reg rst_in;
  reg [15:0] gx, gy, gz;
  reg signed [31:0] pitch, roll, yaw;

  // Instantiate the module
  process_gyro_simple dut (
    .clk_100mhz(clk_100mhz),
    .rst_in(rst_in),
    .gx(gx),
    .gy(gy),
    .gz(gz),
    .pitch(pitch),
    .roll(roll),
    .yaw(yaw)
  );

  initial begin
    clk_100mhz = 0;
    forever #5 clk_100mhz = ~clk_100mhz;
  end

  initial begin
    rst_in = 0;
    gx = 1;
    gy = 1;
    gz = 1;

    // Apply reset
    rst_in = 1;
    #10;
    rst_in = 0;

    gx = 1 << 8;
    gy = 2 << 8;
    gz = -10 <<< 8;
    repeat (1) begin
      #100000;
      $display("Time=%0t, Pitch=%0d, Roll=%0d, Yaw=%0d", $time, pitch>>>16, roll>>>16, $signed(yaw>>>16));
    end

    #10;
    $finish;
  end

endmodule
`default_nettype wire
