`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module process_gyro(
    input wire clk_100mhz,
    input wire rst_in,
    input wire [15:0] gx, 
    input wire [15:0] gy,
    input wire [15:0] gz,
    output reg [15:0] pitch,
    output reg [15:0] roll,
    output reg [15:0] yaw,
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

module view_output (
  input wire clk_100mhz,
  input wire rst_in,
  input wire [15:0] pitch,
  input wire [15:0] roll,
  input wire [15:0] yaw,
  // Calculates all three vectors
  output wire [31:0] x_forward,
  output wire [31:0] y_forward,
  output wire [31:0] z_forward,
  output wire [31:0] x_up,
  output wire [31:0] y_up,
  output wire [31:0] z_up,
  output wire [31:0] x_right,
  output wire [31:0] y_right,
  output wire [31:0] z_right
  ); 


// Values for forward_vector
logic [8:0] x_forward_val1, x_forward_val2, y_forward_val, z_forward_val1, z_forward_val2;
logic [31:0] x_forward1, x_forward2, y_forward, z_forward1, z_forward2;
logic x_forward_go1, x_forward_go2, y_forward_go, z_forward_go1, z_forward_go2;
logic x_forward_ready1, x_forward_ready2, y_forward_ready, z_forward_ready1, z_forward_ready2;
// Values for up vector
logic [8:0] x_up_val1, x_up_val2, y_up_val, z_up_val1, z_up_val2;
logic [31:0] x_up1, x_up2, y_up1, y_up2, z_up1, z_up2;
logic x_up_go1, x_up_go2, y_up_go, z_up_go1, z_up_go2;
logic x_up_ready1, x_up_ready2 y_up_ready, z_up_ready1, z_up_ready2;
// Values for right vector
logic [8:0] x_right_val, z_right_val;
logic [31:0] x_right, z_right;
logic x_right_go, z_right_go;
logic x_right_ready, z_right_ready;


// Trigonometry calculations for forward vector
cosine cos_x_forward(
  .value(x_forward_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_forward_val1),
  .ready(x_forward_ready1)
);

sine sin_x_forward(
  .value(x_forward_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_forward_val2),
  .ready(x_forward_ready2)
);

sine sin_y_forward(
  .value(y_forward_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(y_forward_val),
  .ready(y_forward_ready)
);

cosine cos_z_forward1(
  .value(z_forward_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_forward_val1),
  .ready(z_forward_ready1)
);

cos cos_z_forward2(
  .value(z_forward_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_forward_val2),
  .ready(z_forward_ready2)
);

// Trigonometry calculations for up vector
cos cos_x_up(
  .value(x_up_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_up_val1),
  .ready(x_up_ready1)
);
sine sin_x_up(
  .value(x_up_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_up_val1),
  .ready(x_up_ready1)
);

cos cos_y_up(
  .value(y_up_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(y_up_val),
  .ready(y_up_ready)
);

sine sin_z_up(
  .value(z_up_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_up_val1),
  .ready(z_up_ready1)
);

cos cos_z_up(
  .value(z_up_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_up_val2),
  .ready(z_up_ready2)
);

// Trigonometry calculations for right vector

cos cos_x_right(
  .value(x_right_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_right_val),
  .ready(x_right_ready)
);

cos cos_z_right(
  .value(z_right_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_right_val),
  .ready(z_right_ready)
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
  end else begin 
    x_forward_val1 <= pitch;
    x_forward_val2 <= yaw;
    y_forward_val <= pitch;
    z_forward_val1 <= pitch;
    z_forward_val2 <= yaw;

    // x_forward <= sin; // x <= cos(pitch)*sin(yaw)
    // y_forward <= roll; // y <= -sin(pitch)
    // z_forward <= yaw; // z <= cos(pitch)*cos(yaw)

    x_up_val1 <= pitch;
    x_up_val2 <= yaw;
    y_up_val <= pitch;
    z_up_val1 <= pitch;
    z_up_val2 <= yaw;

    // x_up <= sin; // x <= sin(pitch)*sin(yaw)
    // y_up <= roll; // y <= cos(pitch)
    // z_up <= yaw; // z <= sin(pitch)*cos(yaw)

    x_right_val <= yaw;
    z_right_val <= yaw;
    
    // x_right <= sin; // x <= cos(yaw)
    // y_right <= roll; // y <= 0
    // z_right <= yaw; // z <= -sin(yaw)
  end 

end 
endmodule

`default_nettype wire