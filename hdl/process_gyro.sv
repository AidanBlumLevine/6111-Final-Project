module process_gyro(
    input wire clk_100mhz,
    input wire rst_in,
    input wire [0:15] gx, 
    input wire [0:15] gy,
    input wire [0:15] gz,
    output reg [0:15] pitch,
    output reg [0:15] roll,
    output reg [0:15] yaw,
    output reg ready 
    );

logic pitch_ready, roll_ready, yaw_ready;
logic [0:15] curPitch, curRoll, curYaw;
logic [0:15] dPitch, dRoll, dYaw;

div divide1 (
    .clk(clk_100mhz),
    .a(gx),
    .b(10),
    .val(dRoll)
    );

div divide2 (
    .clk(clk_100mhz),
    .a(gy),
    .b(10),
    .val(dPitch)
    );

div divide3 (
    .clk(clk_100mhz),
    .a(gz),
    .b(10),
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
  end else begin  
    curPitch <= pitch;
    curRoll <= roll;
    curYaw <= yaw;
    pitch <= curPitch + dPitch;
    roll <= curRoll + dRoll;
    yaw <= curYaw + dYaw;
    ready <= 1;
  end
end  
endmodule