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

assign half_pi = 32'b00000000000000011001001000011111
logic counter;
logic pitch_ready, roll_ready, yaw_ready;
logic pitch_waiting, roll_waiting, yaw_waiting;
logic [0:15] curPitch, curRoll, curYaw;
logic [0:15] dPitch, dRoll, dYaw;
logic [0:15] gx_used, gy_used, gz_used;
div #(
    .WIDTH(32),
    .FBITS(16)
) divide1 (
    .clk(clk_100mhz),
    .a(gx_used),
    .b(32'b01001110001000000000000000000000),
    .val(dRoll)
    );

div #(
    .WIDTH(32),
    .FBITS(16)
) divide2 (
    .clk(clk_100mhz),
    .a(gy_used),
    .b(32'b01001110001000000000000000000000),
    .val(dPitch)
    );

div #(
    .WIDTH(32),
    .FBITS(16)
  )
  divide3 (
    .clk(clk_100mhz),
    .a(gz_used),
    .b(32'b01001110001000000000000000000000),
    .val(dYaw)
    );

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    curPitch <= 0;
    curRoll <= 0;
    curYaw <= 0;
    pitch <= 0;
    roll <= 0;
    counter <= 0;
    yaw <= 0;
    ready <= 0;
    counter <= 0;
  end else begin  
    counter <= counter + 1;
    if (counter == 0) begin 
      gx_used <= gx;
      gy_used <= gy;
      gz_used <= gz;
      ready <= 0;
    end else if (counter == 1000) begin 
      curPitch <= pitch;
      curRoll <= roll;
      curYaw <= yaw;
      pitch <= curPitch + dPitch;
      roll <= curRoll + dRoll;
      yaw <= curYaw + dYaw;
      ready <= 1;
      counter <= 0;
    end
  end
end  
endmodule

module view_output (
  input wire clk_100mhz,
  input wire rst_in,
  input wire [0:15] pitch,
  input wire [0:15] roll,
  input wire [0:15] yaw,
  output wire [0:31] x,
  output wire [0:31] y,
  output wire [0:31] z,
  output wire [0:31] x_offset, 
  output wire [0:31] y_offset,
  output wire [0:31] z_offset
  ); 

logic [0:7] sin_x_1, sin_x_2, sin_y_1, sin_y_2, sin_z_1; 
always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    x <= 0;
    y <= 0;
    z <= 0;
    x_offset <= 0;
    y_offset <= 0;
    z_offset <= 0;
    sin_lut sine_1(
      .clk_in(clk_100mhz),
      .phase_in(),
      .amp_out(sin_x_1)
    );
  end else begin 
    x <= sin; // x <= sin(yaw - pi/2)*sin(pitch - pi/2);
    y <= roll; // y <= sin(yaw)*sin(pitch - pi/2);
    z <= yaw; // z <= sin(pitch)
  end 

end 
endmodule