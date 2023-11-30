`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module process_gyro_simple(
    input wire clk_100mhz,
    input wire rst_in,
    input wire signed [15:0] gx, 
    input wire signed [15:0] gy,
    input wire signed [15:0] gz,
    output reg [31:0] pitch,
    output reg [31:0] roll,
    output reg [31:0] yaw
    );

logic [31:0] counter;
logic signed [39:0] curPitch, curRoll, curYaw; // 32.8 format
logic [15:0] dPitch, dRoll, dYaw;

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    curPitch <= 0;
    curRoll <= 0;
    curYaw <= 0;
    pitch <= 0;
    roll <= 0;
    yaw <= 0;
    counter <= 0;
  end else begin  
    counter <= counter + 1;
    if (counter == 10000 - 1) begin 
      curPitch <= 0;
      curRoll <= 0;
      curYaw <= 0;
      // divide current pitch, roll, yaw by 10000
      // to do this, multiply by 7 (approx 1/10000)
      // and shift right by 16 + 8 - 16 because curPitch has 8 fractional bits and "7" has 16, and we want 16 in our answer
      pitch <= (curPitch*7)>>>8;
      roll <= (curRoll*7)>>>8;
      yaw <= (curYaw*7)>>>8;
      counter <= 0;
    end else begin
      curPitch <= curPitch + gy;
      curRoll <= curRoll + gx;
      curYaw <= curYaw + gz;
    end
  end
end  
endmodule

`default_nettype wire