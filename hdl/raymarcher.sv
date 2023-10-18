`timescale 1ns / 1ps
`default_nettype none


module raymarcher
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter MAX_STEPS = 100,
  parameter signed [23:0] MAX_DIST_SQUARE = 24'h080_00,
  parameter signed [23:0] EPSILON = 24'h0000_10
)
(
  input wire clk_pixel_in,
  input wire rst_in,
  input wire [$clog2(WIDTH)-1:0] curr_x,
  input wire [$clog2(HEIGHT)-1:0] curr_y,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic pixel_done
);
  typedef enum {PIXEL_DONE=0, INITIALIZING=1, AWAITING_SDF=2, NORMALIZING_RAY=3, MARCHING=4} raymarcher_state;
  raymarcher_state state;
  always_comb begin
    pixel_done = state == PIXEL_DONE;
  end

  logic [$clog2(MAX_STEPS):0] ray_steps;

  logic sdf_start;
  always_comb begin
    sdf_start = state == AWAITING_SDF;
  end
  logic sdf_done;
  logic signed [23:0] sdf_out;
  sdf sdf_inst (
    .clk_in(clk_pixel_in),
    .rst_in(rst_in),
    .sdf_start(sdf_start),
    .x(ray_x),
    .y(ray_y),
    .z(ray_z),
    .sdf_done(sdf_done),
    .sdf_out(sdf_out)
  );

  logic ray_gen_start;
  always_comb begin
    ray_gen_start = state == NORMALIZING_RAY;
  end
  logic ray_gen_done;
  logic signed [23:0] ray_gen_out_x;
  logic signed [23:0] ray_gen_out_y;
  logic signed [23:0] ray_gen_out_z;
  logic signed [23:0] ray_gen_in_x;
  logic signed [23:0] ray_gen_in_y;
  logic signed [23:0] ray_gen_in_z;
  ray_gen ray_gen_inst (
    .clk_in(clk_pixel_in),
    .rst_in(rst_in),
    .ray_gen_start(ray_gen_start),
    .ray_gen_done(ray_gen_done),
    .ray_gen_out_x(ray_gen_out_x),
    .ray_gen_out_y(ray_gen_out_y),
    .ray_gen_out_z(ray_gen_out_z),
    .ray_gen_in_x(ray_gen_in_x),
    .ray_gen_in_y(ray_gen_in_y),
    .ray_gen_in_z(ray_gen_in_z)
  );

  logic signed [23:0] ray_x;
  logic signed [23:0] ray_y;
  logic signed [23:0] ray_z;
  logic signed [23:0] dir_x;
  logic signed [23:0] dir_y;
  logic signed [23:0] dir_z;

  always_ff @(posedge clk_pixel_in) begin
    if(state == PIXEL_DONE) begin
      $display("PIXEL_DONE");
    end else if(state == INITIALIZING) begin
      $display("INITIALIZING");
    end else if(state == AWAITING_SDF) begin
      $display("AWAITING_SDF");
    end else if(state == NORMALIZING_RAY) begin
      $display("NORMALIZING_RAY");
    end else if(state == MARCHING) begin
      $display("MARCHING");
    end

    if(rst_in) begin
      state <= PIXEL_DONE;
    end else begin
      if(state == PIXEL_DONE) begin
        ray_steps <= 0;
        $display("color out %d %d %d", red_out, green_out, blue_out);
        
        state <= INITIALIZING;
      end else if(state == INITIALIZING) begin
        ray_gen_in_x <= dec_to_16_8(curr_x - WIDTH/2'd2);
        ray_gen_in_y <= dec_to_16_8(curr_y - HEIGHT/2'd2);
        ray_gen_in_z <= dec_to_16_8(WIDTH/3'd4+HEIGHT/3'd4);

        state <= NORMALIZING_RAY;
      end else if(state == NORMALIZING_RAY) begin
        if(ray_gen_done) begin
          dir_x <= ray_gen_out_x;
          dir_y <= ray_gen_out_y;
          dir_z <= ray_gen_out_z;
          ray_x <= 0;
          ray_y <= 0;
          ray_z <= 0;
          ray_steps <= 0;

          $display("normalized to %h %h %h", dir_x, dir_y, dir_z);

          state <= AWAITING_SDF;
        end
      end else if(state == AWAITING_SDF) begin
        sdf_start <= 0;

        if (sdf_done) begin
          $display("sdf_out %b", sdf_out);

          if(sdf_out[23] || sdf_out < EPSILON) begin
            $display("breaking from surface contact at distance %h", sdf_out);
            red_out <= 8'h00;
            green_out <= 8'h00;
            blue_out <= 8'h00;

            state <= PIXEL_DONE;
          end else begin

            state <= MARCHING;
          end
        end
      end else if (state == MARCHING) begin
        $display("marching from %h %h %h", ray_x, ray_y, ray_z);
        ray_x <= ray_x + mult_16_8(dir_x, sdf_out);
        ray_y <= ray_y + mult_16_8(dir_y, sdf_out);
        ray_z <= ray_z + mult_16_8(dir_z, sdf_out);
        $display("to %h %h %h", ray_x + mult_16_8(dir_x, sdf_out), ray_y + mult_16_8(dir_y, sdf_out), ray_z + mult_16_8(dir_z, sdf_out));
        if(ray_steps > MAX_STEPS) begin
          $display("breaking from max steps");
          red_out <= 8'hFF;
          green_out <= 8'h00;
          blue_out <= 8'hFF;

          state <= PIXEL_DONE;
        end else if(square_mag(ray_x, ray_y, ray_z) > MAX_DIST_SQUARE) begin
          $display("breaking from max dist");
          red_out <= 8'hFF;
          green_out <= 8'hFF;
          blue_out <= 8'hFF;

          state <= PIXEL_DONE;
        end else begin
          ray_steps <= ray_steps + 1;

          state <= AWAITING_SDF;
        end
      end  
    end
  end
endmodule

module sdf (
  input wire clk_in,
  input wire rst_in,
  input wire sdf_start,
  input wire signed [23:0] x,
  input wire signed [23:0] y,
  input wire signed [23:0] z,
  output logic sdf_done,
  output logic signed [23:0] sdf_out
);
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
    end else begin
      if(sdf_start) begin
        sdf_out <= abs_16_8(x) + abs_16_8(y) + abs_16_8(z - 24'h096_00) - 24'h001_00;
        sdf_done <= 1;
      end else begin
        sdf_done <= 0;
      end
    end
  end
endmodule

module ray_gen (
  input wire clk_in,
  input wire rst_in,
  input wire ray_gen_start,
  output logic ray_gen_done,
  output logic signed [23:0] ray_gen_out_x,
  output logic signed [23:0] ray_gen_out_y,
  output logic signed [23:0] ray_gen_out_z,
  input wire signed [23:0] ray_gen_in_x,
  input wire signed [23:0] ray_gen_in_y,
  input wire signed [23:0] ray_gen_in_z
);
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
    end else begin
      if(ray_gen_start) begin
        ray_gen_out_x <= ray_gen_in_x;
        ray_gen_out_y <= ray_gen_in_y;
        ray_gen_out_z <= 24'h0001_01;
        ray_gen_done <= 1;
      end else begin
        ray_gen_done <= 0;
      end
    end
  end
endmodule

function logic signed [23:0] square_mag;
  input logic signed [23:0] x;
  input logic signed [23:0] y;
  input logic signed [23:0] z;
  begin
    square_mag = mult_16_8(x,x) + mult_16_8(y,y) + mult_16_8(z,z);
  end
endfunction

function logic signed [23:0] mult_16_8;
  input logic signed [23:0] a;
  input logic signed [23:0] b;
  logic signed [47:0] intermediate;
  begin
    intermediate = a * b;
    mult_16_8 = {intermediate[47], intermediate[30:8]};
  end
endfunction

function logic signed [23:0] dec_to_16_8;
  input logic [15:0] a;
  begin
    dec_to_16_8 = {a, 8'h00};
  end
endfunction

function logic signed [23:0] div_shift_estimate;
  input logic signed [23:0] a;
  input logic signed [23:0] b;
  logic [23:0] b_abs;
  logic [23:0] a_abs;
  logic [4:0] b_log;
  logic sign;
  begin
    sign = a[23] ^ b[23];
    b_abs = b[23] ? ~b + 1 : b;
    a_abs = a[23] ? ~a + 1 : a;
    for(int i = 0; i < 23; i++) begin
      if(b_abs[i] == 1) begin
        b_log = i;
      end
    end

    if(b_log != 31) begin
      if(b_log > 8) begin
        div_shift_estimate = a_abs >> (b_log - 8);
      end else begin
        div_shift_estimate = a_abs << (8 - b_log);
      end
    end else begin
      $display("div 0");
      div_shift_estimate = 24'h7FFF_00;
    end

    if(sign) begin
      div_shift_estimate = ~div_shift_estimate + 1;
    end
  end
endfunction

function logic signed [23:0] abs_16_8;
  input logic signed [23:0] a;
  begin
    abs_16_8 = a[23] ? ~a + 1 : a;
  end
endfunction

`default_nettype wire