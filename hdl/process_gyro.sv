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
      chunkPitch <= chunkPitch + (gy >>> 5);
      chunkRoll <= chunkRoll + (gx >>> 5);
      chunkYaw <= chunkYaw + (gz >>> 5);
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
  input wire start, 
  // Calculates all three vectors
  output logic signed [31:0] x_forward,
  output logic signed [31:0] y_forward,
  output logic signed [31:0] z_forward,
  output logic signed [31:0] x_up,
  output logic signed [31:0] y_up,
  output logic signed [31:0] z_up,
  output logic signed [31:0] x_right,
  output logic signed [31:0] y_right,
  output logic signed [31:0] z_right,
  output wire done
  ); 

logic sine1_done, sine2_done;
logic [8:0] sine1_value, sine2_value;
logic signed [31:0] sine1_out, sine2_out;

logic signed [31:0] x_forward_temp, y_forward_temp, z_forward_temp;
logic signed [31:0] x_right_temp, y_right_temp, z_right_temp;
logic signed [31:0] x_up_temp, y_up_temp, z_up_temp;

typedef enum { UPDATING_VALUES, CALCULATING, DONE } trig_calc_state;
typedef enum { IDLE, FORWARD, UP, RIGHT, DONE } vector_type_state;
typedef enum { X, Y, Z } vector_axis_state;
vector_type_state vector_type;
vector_axis_state vector_axis;
trig_calc_state trig_calc;

// Trigonometry functions 
sine sine1(
  .start(1),
  .value(sine1_value),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .done(sine1_done),
  .amp_out(sine1_out)
);

sine sine2(
  .start(1),
  .value(sine2_value),
  .clk_in(clk_100mhz),
  .rst_in(rst_in),
  .done(sine2_done),
  .amp_out(sine2_out)
);

always_comb begin
    done = (state == DONE);
end

always_ff @(posedge clk_100mhz) begin 
  if (rst_in) begin 
    vector_type <= FORWARD;
    vector_axis <= X;
    trig_calc <= UPDATING_VALUES;
  end else begin 
    case (vector_type)
      IDLE: begin
        (start)? vector_type <= FORWARD : vector_type <= IDLE;
      end   
      FORWARD: begin
        case(vector_axis)
          X: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch - 90;
                sine2_value <= yaw;
                trig_calc <= CALCULATING;
              end 
              CALCULATING: begin 
                if (sine1_done && sine2_done) begin 
                  x_forward_temp <= mult(sine1_out, sine2_out);
                end   
              end 
              DONE: begin 
                vector_axis <= Y;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end 
          Y: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch; 
              end 
              CALCULATING: begin 
                if (sine1_done) begin 
                  y_forward_temp <= mult(-1, sine1_out);
                end 
              end 
              DONE: begin 
                vector_axis <= Z;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end
          Z: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch - 90;
                sine2_value <= yaw - 90;
                trig_calc <= CALCULATING;
              end 
              CALCULATING: begin 
                if (sine1_done && sine2_done) begin 
                  z_forward_temp <= mult(sine1_out, sine2_out);
                end
              end 
              DONE: begin 
                vector_type <= UP;  
                vector_axis <= X;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end
        endcase 
      end 
      UP: begin
        case(vector_axis)
          X: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch;
                sine2_value <= yaw;
                trig_calc <= CALCULATING;
              end 
              CALCULATING: begin 
                if (sine1_done && sine2_done) begin 
                  x_up_temp <= mult(sine1_out, sine2_out);
                end   
              end 
              DONE: begin 
                vector_axis <= Y;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end 
          Y: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch - 90; 
              end 
              CALCULATING: begin 
                if (sine1_done) begin 
                  y_up_temp <= mult(-1, sine1_out);
                end 
              end 
              DONE: begin 
                vector_axis <= Z;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end
          Z: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= pitch;
                sine2_value <= yaw - 90;
                trig_calc <= CALCULATING;
              end 
              CALCULATING: begin 
                if (sine1_done && sine2_done) begin 
                  z_up_temp <= mult(sine1_out, sine2_out);
                end
              end 
              DONE: begin 
                vector_type <= UP;  
                vector_axis <= X;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end
        endcase 
      end
      RIGHT: begin
        case(vector_axis)
          X: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= yaw - 90;
              end 
              CALCULATING: begin 
                if (sine1_done) begin 
                  x_right_temp <= sine1_out;
                end   
              end 
              DONE: begin 
                vector_axis <= Y;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end 
          Y: begin
            y_right_temp <= 0;
            vector_axis <= Z;
            trig_calc <= UPDATING_VALUES;
          end
          Z: begin
            case(trig_calc) 
              UPDATING_VALUES: begin 
                sine1_value <= yaw;
                trig_calc <= CALCULATING;
              end 
              CALCULATING: begin 
                if (sine1_done) begin 
                  z_right_temp <= mult(-1, sine1_out);
                end
              end 
              DONE: begin 
                vector_type <= UP;  
                vector_axis <= X;
                trig_calc <= UPDATING_VALUES;
              end
            endcase
          end
        endcase 
      end
    DONE: begin 
      x_forward <= x_forward_temp;
      y_forward <= y_forward_temp;
      z_forward <= z_forward_temp;
      x_up <= x_up_temp;
      y_up <= y_up_temp;
      z_up <= z_up_temp;
      x_right <= x_right_temp;
      y_right <= y_right_temp;
      z_right <= z_right_temp;
      vector_axis <= X;
      vector_type <= IDLE;
      trig_calc <= UPDATING_VALUES;
    end 
    endcase
  end
end 
endmodule

`default_nettype wire