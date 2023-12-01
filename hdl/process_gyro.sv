`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module process_gyro_simple(
    input wire clk_100mhz,
    input wire rst_in,
    input wire signed [15:0] gx, 
    input wire signed [15:0] gy,
    input wire signed [15:0] gz,
    output reg [8:0] pitch,
    output reg [8:0] roll,
    output reg [8:0] yaw
    );

logic [$clog2(10000000):0] counter;
logic signed [42:0] chunkPitch, chunkRoll, chunkYaw; // 42.0 format, can fit 360 degrees per second constant reading (10000000 cycles)
logic signed [20:0] curPitch, curRoll, curYaw; // 12.8 format

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    curPitch <= 0;
    curRoll <= 0;
    curYaw <= 0;
    chunkPitch <= 0;
    chunkRoll <= 0;
    chunkYaw <= 0;
    pitch <= 0;
    roll <= 0;
    yaw <= 0;
    counter <= 0;
  end else begin  
    counter <= counter + 1;
    if (counter == 10000000 - 1) begin 
      // divide current pitch, roll, yaw by 100000000  (100mHz)
      // to do this, multiply by 43 (approx 1/100000000) (100mHz)
      // and shift right by 32 + 0 - 8 because curPitch has 0 fractional bits and "43" has 32, and we want 8 in our answer
      curPitch <= ((chunkPitch*43)>>>24) + curPitch;
      curRoll <= ((chunkRoll*43)>>>24) + curPitch;
      curYaw <= ((chunkYaw*43)>>>24) + curPitch;
      $display("ChunkYaw=%d", chunkYaw);
      $display("CurYaw=%d", curYaw);
      $display("Calculation=%d", ((chunkYaw*43)>>>32));
    end else if (counter == 10000000) begin
      if (curPitch < 0) begin
        curPitch <= curPitch + (360 << 8);
      end else if (curPitch > (360 << 8)) begin
        curPitch <= curPitch - (360 << 8);
      end
      if (curRoll < 0) begin
        curRoll <= curRoll + (360 << 8);
      end else if (curRoll > (360 << 8)) begin
        curRoll <= curRoll - (360 << 8);
      end
      if (curYaw < 0) begin
        curYaw <= curYaw + (360 << 8);
      end else if (curYaw >= (360 << 8)) begin
        curYaw <= curYaw - (360 << 8);
      end
    end else if (counter > 10000000) begin
      pitch <= curPitch >>> 8;
      roll <= curRoll >>> 8;
      yaw <= curYaw >>> 8;
      counter <= 0;
      chunkPitch <= 0;
      chunkRoll <= 0;
      chunkYaw <= 0;
    end else begin
      chunkPitch <= chunkPitch + (gy >>> 8);
      chunkRoll <= chunkRoll + (gx >>> 8);
      chunkYaw <= chunkYaw + (gz >>> 8);
    end
  end
end  
endmodule



module view_output_simple (
  input wire clk_100mhz,
  input wire rst_in,
  input wire [8:0] pitch,
  input wire [8:0] roll,
  input wire [8:0] yaw,
  // Calculates all three vectors
  output logic signed [31:0] x_forward,
  output logic signed [31:0] y_forward,
  output logic signed [31:0] z_forward,
  output logic signed [31:0] x_up,
  output logic signed [31:0] y_up,
  output logic signed [31:0] z_up,
  output logic signed [31:0] x_right,
  output logic signed [31:0] y_right,
  output logic signed [31:0] z_right
  ); 

logic signed [31:0] pitch_cos, pitch_sin, roll_cos, roll_sin, yaw_cos, yaw_sin;;

// Trigonometry calculations for forward vector
cosine cos_x_forward(
  .start(1),
  .value(pitch),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(pitch_cos)
);

sine sin_x_forward(
  .start(1),
  .value(pitch),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(pitch_sin)
);

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
  end else begin 
    x_forward <= pitch_sin;
    y_forward <= 0;
    z_forward <= pitch_cos;
    x_right <= pitch_cos;
    y_right <= 0;
    z_right <= -pitch_sin;

    x_up <= 0;
    y_up <= 1 << 16;
    z_up <= 0;
  end
end 
endmodule

`default_nettype wire