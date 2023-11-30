`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module process_gyro(
    input wire clk_100mhz,
    input wire rst_in,
    input wire [15:0] gx, 
    input wire [15:0] gy,
    input wire [15:0] gz,
    output reg [31:0] pitch,
    output reg [31:0] roll,
    output reg [31:0] yaw,
    output reg ready 
    );

logic [31:0] counter;
logic pitch_ready, roll_ready, yaw_ready;
logic pitch_waiting, roll_waiting, yaw_waiting;
logic [15:0] curPitch, curRoll, curYaw;
logic [15:0] dPitch, dRoll, dYaw;
logic [15:0] gx_used, gy_used, gz_used;

// Adjusting for sampling every 1000 cycles
div #(
    .WIDTH(32),
    .FBITS(16)
) divide1 (
    .clk(clk_100mhz),
    .a({gx_used, 16'b0}),
    .start(1'b1),
    .b({16'b0000001111101000, 16'b0}),
    .val(dRoll)
    );

div #(
    .WIDTH(32),
    .FBITS(16)
) divide2 (
    .clk(clk_100mhz),
    .start(1'b1),
    .a({gy_used, 16'b0}),
    .b({16'b0000001111101000, 16'b0}),
    .val(dPitch)
    );

div #(
    .WIDTH(32),
    .FBITS(16)
  )
  divide3 (
    .clk(clk_100mhz),
    .start(1'b1),
    .a({gz_used, 16'b0}),
    .b({16'b0000001111101000, 16'b0}),
    .val(dYaw)
    );

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    curPitch <= 0;
    curRoll <= 0;
    curYaw <= 0;
    pitch <= 0;
    roll <= 0;
    yaw <= 0;
    ready <= 0;
    counter <= 0;
  end else begin  
    counter <= counter + 1;
    if (counter == 0) begin 
      // Updates values being used in the calculation 
      gx_used <= gx;
      gy_used <= gy; 
      gz_used <= gz;
      ready <= 0;
    end else if (counter == 100000 - 1) begin 
      // First, saves current pitch for next calculation
      curPitch <= pitch;
      curRoll <= roll;
      curYaw <= yaw;
      // Adds the change in pitch, roll, and yaw to the current pitch, roll, and yaw
      pitch <= curPitch + dPitch;
      roll <= curRoll + dRoll;
      yaw <= curYaw + dYaw;
      // Resets counter and throws ready high
      ready <= 1;
      counter <= 0;
    end
  end
end  
endmodule

// // module view_output (
// //   input wire clk_100mhz,
// //   input wire rst_in,
// //   input wire [0:15] pitch,
// //   input wire [0:15] roll,
// //   input wire [0:15] yaw,
// //   // Calculates all three vectors
// //   output wire [0:31] x_forward,
// //   output wire [0:31] y_forward,
// //   output wire [0:31] z_forward,
// //   output wire [0:31] x_up,
// //   output wire [0:31] y_up,
// //   output wire [0:31] z_up,
// //   output wire [0:31] x_right,
// //   output wire [0:31] y_right,
// //   output wire [0:31] z_right
// //   ); 

// // logic [0:7] sin_x_1, sin_x_2, sin_y_1, sin_y_2, sin_z_1; 
// // always_ff @(posedge clk_100mhz) begin 
// //   if (rst_in) begin 
// //     x <= 0;
// //     y <= 0;
// //     z <= 0;
// //     x_offset <= 0;
// //     y_offset <= 0;
// //     z_offset <= 0;
// //     sin_lut sine_1(
// //       .clk_in(clk_100mhz),
// //       .phase_in(),
// //       .amp_out(sin_x_1)
// //     );
// //   end else begin 
// //     x_forward <= sin; // x <= sin(yaw - pi/2)*sin(pitch - pi/2);
// //     y_forward <= roll; // y <= sin(yaw)*sin(pitch - pi/2);
// //     z_forward <= yaw; // z <= sin(pitch)
// //     x_up <= sin; // x <= sin(pitch)*sin(yaw)
// //     y_up <= roll; // y <= sin(pitch - pi/2)
// //     z_up <= yaw; // z <= sin(pitch)
// //     x_right <= sin; // x <= sin(pitch) * sin(yaw)
// //     y_right <= roll; // y <= 0
// //     z_right <= yaw; // z <= sin(pitch) * sin(yaw - pi/2)
// //   end 

// // end 
// // endmodule

`default_nettype wire