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

logic [31:0] counter;
logic signed [39:0] curPitch, curRoll, curYaw; // 32.8 format

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
      // divide current pitch, roll, yaw by 10000
      // to do this, multiply by 7 (approx 1/10000)
      // and shift right by 16 + 8because curPitch has 8 fractional bits and "7" has 16
      curPitch <= (curPitch*7)>>>24;
      curRoll <= (curRoll*7)>>>24;
      curYaw <= (curYaw*7)>>>24;
    end else if (counter == 10000) begin
      if (curPitch < 0) begin
        pitch <= curPitch + 360;
      end else if (curPitch >= 360) begin
        pitch <= curPitch - 360;
      end else begin
        pitch <= curPitch;
      end
      if (curRoll < 0) begin
        roll <= curRoll + 360;
      end else if (curRoll >= 360) begin
        roll <= curRoll - 360;
      end else begin
        roll <= curRoll;
      end
      if (curYaw < 0) begin
        yaw <= curYaw + 360;
      end else if (curYaw >= 360) begin
        yaw <= curYaw - 360;
      end else begin
        yaw <= curYaw;
      end
      
      counter <= 0;
      curPitch <= 0;
      curRoll <= 0;
      curYaw <= 0;
    end else begin
      curPitch <= curPitch + gy;
      curRoll <= curRoll + gx;
      curYaw <= curYaw + gz;
    end
  end
end  
endmodule

module view_output (
  input wire clk_100mhz,
  input wire rst_in,
  input wire [31:0] pitch,
  input wire [31:0] roll,
  input wire [31:0] yaw,
  // Calculates all three vectors
  output logic [31:0] x_forward,
  output logic [31:0] y_forward,
  output logic [31:0] z_forward,
  output logic [31:0] x_up,
  output logic [31:0] y_up,
  output logic [31:0] z_up,
  output logic [31:0] x_right,
  output logic [31:0] y_right,
  output logic [31:0] z_right
  ); 


// Values for forward_vector
logic [8:0] x_forward_val1, x_forward_val2, y_forward_val, z_forward_val1, z_forward_val2;
logic [31:0] x_forward1, x_forward2, y_forward1, z_forward1, z_forward2;
logic x_forward_go1, x_forward_go2, y_forward_go, z_forward_go1, z_forward_go2;
logic x_forward_done1, x_forward_done2, y_forward_done, z_forward_done1, z_forward_done2;
// Values for up vector
logic [8:0] x_up_val1, x_up_val2, y_up_val, z_up_val1, z_up_val2;
logic [31:0] x_up1, x_up2, y_up1, y_up2, z_up1, z_up2;
logic x_up_go1, x_up_go2, y_up_go, z_up_go1, z_up_go2;
logic x_up_done1, x_up_done2, y_up_done, z_up_done1, z_up_done2;
// Values for right vector
logic [8:0] x_right_val, z_right_val;
logic [31:0] x_right1, z_right1;
logic x_right_go, z_right_go;
logic x_right_done, z_right_done;


// Trigonometry calculations for forward vector
cosine cos_x_forward(
  .start(x_forward_go1),
  .value(x_forward_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_forward1),
  .done(x_forward_done1)
);

sine sin_x_forward(
  .start(x_forward_go2),
  .value(x_forward_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_forward2),
  .done(x_forward_done2)
);

sine sin_y_forward(
  .start(y_forward_go),
  .value(y_forward_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(y_forward1),
  .done(y_forward_done)
);

cosine cos_z_forward1(
  .start(z_forward_go1),
  .value(z_forward_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_forward1),
  .done(z_forward_done1)
);

cosine cos_z_forward2(
  .start(z_forward_go2),
  .value(z_forward_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_forward2),
  .done(z_forward_done2)
);

// Trigonometry calculations for up vector
cosine cos_x_up(
  .start(x_up_go1),
  .value(x_up_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_up1),
  .done(x_up_done1)
);
sine sin_x_up(
  .start(x_up_go2),
  .value(x_up_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_up2),
  .done(x_up_done2)
);

cosine cos_y_up(
  .start(y_up_go),
  .value(y_up_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(y_up1),
  .done(y_up_done)
);

sine sin_z_up(
  .start(z_up_go1),
  .value(z_up_val1),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_up1),
  .done(z_up_done1)
);

cosine cos_z_up(
  .start(z_up_go2),
  .value(z_up_val2),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_up2),
  .done(z_up_done2)
);

// Trigonometry calculations for right vector

cosine cos_x_right(
  .start(x_right_go),
  .value(x_right_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(x_right1),
  .done(x_right_done)
);

cosine cos_z_right(
  .start(z_right_go),
  .value(z_right_val),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .amp_out(z_right1),
  .done(z_right_done)
);

logic state; // 0 = UPDATING, 1= CALCULATING
logic [0:7] sin_x_1, sin_x_2, sin_y_1, sin_y_2, sin_z_1; 
logic x_forward1_complete, x_forward2_complete, y_forward_complete, z_forward1_complete, z_forward2_complete;
logic x_up1_complete, x_up2_complete, y_up_complete, z_up1_complete, z_up2_complete;
logic x_right_complete, z_right_complete;
always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    state <= 0;
    x_forward_go1 <= 0;
    x_forward_go2 <= 0;
    y_forward_go <= 0;
    z_forward_go1 <= 0;
    z_forward_go2 <= 0;
  end else begin 
    case(state)
      1'b0: begin
        // Updates angles
        x_forward_val1 <= pitch >>> 16;
        x_forward_val2 <= yaw >>> 16;
        y_forward_val <= pitch >> 16;
        z_forward_val1 <= pitch >> 16;
        z_forward_val2 <= yaw >> 16;

        // Starts calculation
        x_forward_go1 <= 1;
        x_forward_go2 <= 1;
        y_forward_go <= 1;
        z_forward_go1 <= 1;
        z_forward_go2 <= 1;

        // Updates angles
        x_up_val1 <= pitch >>> 16;
        x_up_val2 <= yaw >>> 16;
        y_up_val <= pitch >>> 16;
        z_up_val1 <= pitch;
        z_up_val2 <= yaw;

        // Starts calculation
        x_up_go1 <= 1;
        x_up_go2 <= 1;
        y_up_go <= 1;
        z_up_go1 <= 1;
        z_up_go2 <= 1;

        // Updates angles
        x_right_val <= yaw;
        z_right_val <= yaw;
        x_right_go <= 1;
        z_right_go <= 1;

        // Sends to calculating state 
        state <= 1;
      end 
      1'b1: begin
        // Saves finished calculations
        if (x_forward_done1) begin
        $display("STATE 1");

          x_forward1_complete <= 1;
          x_forward_go1 <= 0;
        end 
        if (x_forward_done2) begin 
          x_forward2_complete <= 1;
          x_forward_go2 <= 0;
        end
        if (y_forward_done) begin 
          y_forward_complete <= 1;
          y_forward_go <= 0;
        end
        if (z_forward_done1) begin 
          z_forward1_complete <= 1;
          z_forward_go1 <= 0;
        end
        if (z_forward_done2) begin 
          z_forward2_complete <= 1;
          z_forward_go2 <= 0;
        end
        if (x_up_done1) begin 
          x_up1_complete <= 1;
          x_up_go1 <= 0;
        end
        if (x_up_done2) begin 
          x_up2_complete <= 1;
          x_up_go2 <= 0;
        end
        if (y_up_done) begin 
          y_up_complete <= 1;
          y_up_go <= 0;
        end
        if (z_up_done1) begin 
          z_up1_complete <= 1;
          z_up_go1 <= 0;
        end
        if (z_up_done2) begin 
          z_up2_complete <= 1;
          z_up_go2 <= 0;
        end
        if (x_right_done) begin 
          x_right_complete <= 1;
          x_right_go <= 0;
        end
        if (z_right_done) begin 
          z_right_complete <= 1;
          z_right_go <= 0;
        end
        if (x_forward_done1 && x_forward_done2
         && y_forward_done && z_forward_done1
         && z_forward_done2 && x_up_done1 
         && x_up_done2 && y_up_done 
         && z_up_done1 && z_up_done2 
         && x_right_done && z_right_done) begin 
          $display("SETTING VALUE");
          x_forward <= mult(x_forward_val1,x_forward_val2); 
          y_forward <= ~y_forward_val + 1;
          z_forward <= mult(z_forward_val1,z_forward_val2);
          x_up <= mult(x_up_val1,x_up_val2);
          y_up <= y_up_val;
          z_up <= mult(z_up_val1,z_up_val2);
          x_right <= x_right_val;
          y_right <= 0;
          z_right <= ~z_right_val + 1;
          state <= 0;
        end
      end 
    endcase 
  end 

end 
endmodule

`default_nettype wire