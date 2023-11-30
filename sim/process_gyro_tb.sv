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

    gx = 4 << 8;
    gy = 0 << 8;
    gz = 0 <<< 8;
    repeat (100) begin
      gx = gx + (1 <<< 8);
      #1000;
      $display("Time=%0t, Pitch=%0d, Roll=%0d, Yaw=%0d", $time, pitch>>>16, roll>>>16, $signed(yaw>>>16));
    end
    $display("gx=%0d, gy=%0d, gz=%0d", gx>>>8, gy, gz);

    #10;
    $finish;
  end

endmodule
`default_nettype wire
