`timescale 1ns / 1ps
`default_nettype none

function logic signed [31:0] mult_24_8;
  input logic signed [31:0] a;
  input logic signed [31:0] b;
  logic signed [63:0] intermediate;
  begin
    intermediate = a * b;
    mult_24_8 = {intermediate[63], intermediate[38:8]};
  end
endfunction

function logic signed [31:0] square_mag;
  input logic signed [31:0] x;
  input logic signed [31:0] y;
  input logic signed [31:0] z;
  logic signed [31:0] i;
  logic signed [31:0] j;
  logic signed [31:0] k;
  begin
    i = mult_24_8(x,x);
    j = mult_24_8(y,y);
    k = mult_24_8(z,z);
    square_mag = i + j + k;
  end
endfunction

function logic signed [31:0] dec_to_24_8;
  input logic [23:0] a;
  begin
    dec_to_24_8 = {a, 8'h00};
  end
endfunction

function logic signed [31:0] abs_24_8;
  input logic signed [31:0] a;
  begin
    abs_24_8 = a[31] ? ~a + 1 : a;
  end
endfunction

function logic signed [31:0] signed_minimum;
  input logic signed [31:0] a;
  input logic signed [31:0] b;
  begin
    if(a[31] && !b[31])
      signed_minimum = b;
    else if(!a[31] && b[31])
      signed_minimum = a;
    else if(a[31] && b[31])
      signed_minimum = a > b ? a : b;
    else
      signed_minimum = a < b ? a : b;
  end
endfunction

function logic [7:0] clamp_color;
  input logic [31:0] a;
  begin
    if(a > 8'hFF)
      clamp_color = 8'hFF;
    else if(a < 8'h00)
      clamp_color = 8'h00;
    else
      clamp_color = a;
  end
endfunction

module raymarcher
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter MAX_STEPS = 100,
  parameter signed [31:0] MAX_DIST_SQUARE = 32'h01_0000_00,
  parameter signed [31:0] EPSILON = 32'h00_0001_00
)
(
  input wire clk_pixel_in,
  input wire rst_in,
  input wire [$clog2(WIDTH)-1:0] curr_x,
  input wire [$clog2(HEIGHT)-1:0] curr_y,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic [$clog2(WIDTH)-1:0] out_x,
  output logic [$clog2(HEIGHT)-1:0] out_y,
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
  logic signed [31:0] sdf_out;
  logic [7:0] sdf_red_out;
  logic [7:0] sdf_green_out;
  logic [7:0] sdf_blue_out;
  sdf sdf_inst (
    .clk_in(clk_pixel_in),
    .rst_in(rst_in),
    .sdf_start(sdf_start),
    .x(ray_x),
    .y(ray_y),
    .z(ray_z),
    .sdf_done(sdf_done),
    .sdf_out(sdf_out),
    .sdf_red_out(sdf_red_out),
    .sdf_green_out(sdf_green_out),
    .sdf_blue_out(sdf_blue_out)
  );

  logic ray_gen_start;
  always_comb begin
    ray_gen_start = state == NORMALIZING_RAY;
  end
  logic ray_gen_done;
  logic signed [31:0] ray_gen_out_x;
  logic signed [31:0] ray_gen_out_y;
  logic signed [31:0] ray_gen_out_z;
  logic signed [31:0] ray_gen_in_x;
  logic signed [31:0] ray_gen_in_y;
  logic signed [31:0] ray_gen_in_z;
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

  logic signed [31:0] ray_x;
  logic signed [31:0] ray_y;
  logic signed [31:0] ray_z;
  logic signed [31:0] dir_x;
  logic signed [31:0] dir_y;
  logic signed [31:0] dir_z;

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
        $display("color out %d %d %d", red_out, green_out, blue_out);
        
        state <= INITIALIZING;
      end else if(state == INITIALIZING) begin
        ray_gen_in_x <= dec_to_24_8(curr_x - WIDTH/2'd2);
        ray_gen_in_y <= dec_to_24_8(curr_y - HEIGHT/2'd2);
        ray_gen_in_z <= dec_to_24_8(WIDTH/3'd4+HEIGHT/3'd4);
        out_x <= curr_x;
        out_y <= curr_y;
        $display("ray_gen_in %h %h %h", ray_gen_in_x, ray_gen_in_y, ray_gen_in_z);
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
        if (sdf_done) begin
          $display("sdf_out %d d", sdf_out >> 8);

          if(sdf_out[31] || sdf_out < EPSILON) begin
            $display("breaking from surface contact at distance %h h", sdf_out);
            red_out <= sdf_red_out;
            green_out <= sdf_green_out;
            blue_out <= sdf_blue_out;

            state <= PIXEL_DONE;
          end else begin

            state <= MARCHING;
          end
        end
      end else if (state == MARCHING) begin
        $display("marching from %h %h %h", ray_x, ray_y, ray_z);
        ray_x <= ray_x + mult_24_8(dir_x, sdf_out);
        ray_y <= ray_y + mult_24_8(dir_y, sdf_out);
        ray_z <= ray_z + mult_24_8(dir_z, sdf_out);
        $display("to %h %h %h", ray_x + mult_24_8(dir_x, sdf_out), ray_y + mult_24_8(dir_y, sdf_out), ray_z + mult_24_8(dir_z, sdf_out));
        if(ray_steps > MAX_STEPS) begin
          $display("breaking from max steps");
          red_out <= 8'hFF;
          green_out <= 8'h00;
          blue_out <= 8'h00;

          state <= PIXEL_DONE;
        end else if(square_mag(ray_x, ray_y, ray_z) > MAX_DIST_SQUARE) begin
          $display("breaking from max dist %b %b", square_mag(ray_x, ray_y, ray_z), MAX_DIST_SQUARE);
          red_out <= 8'hFF;
          green_out <= 8'hFF;
          blue_out <= out_x[4] ^ out_y[4] ? 8'hFF : 8'h00;

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
  input wire signed [31:0] x,
  input wire signed [31:0] y,
  input wire signed [31:0] z,
  output logic sdf_done,
  output logic signed [31:0] sdf_out,
  output logic [7:0] sdf_red_out,
  output logic [7:0] sdf_green_out,
  output logic [7:0] sdf_blue_out
);
  typedef enum {IDLE=0, PROCESSING=1} sdf_state;
  sdf_state state;

  logic signed [31:0] sphere_1_dist_squared;
  logic signed [31:0] sphere_2_dist_squared;
  logic sphere_1_sqrt_done;
  logic sphere_2_sqrt_done;
  logic signed [31:0] sphere_1_dist;
  logic signed [31:0] sphere_2_dist;

  logic sqrt_start;

  sqrt sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_1_dist_squared),
    .root(sphere_1_dist),
    .valid(sphere_1_sqrt_done)
  );

  sqrt sqrt_inst2 (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_2_dist_squared),
    .root(sphere_2_dist),
    .valid(sphere_2_sqrt_done)
  );

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= IDLE;
      sqrt_start <= 0;
      sdf_done <= 0;
    end else begin
      if (state == IDLE) begin
        sdf_done <= 0;
        
        if(sdf_start) begin
          sqrt_start <= 1;
          sphere_1_dist_squared <= square_mag(x - 32'h00000_00, y - 32'h00020_00, z - 32'h00096_00);
          sphere_2_dist_squared <= square_mag(x - 32'h00000_00, y + 32'h00020_00, z - 32'h00096_00);

          state <= PROCESSING;
        end
      end else if(state == PROCESSING) begin
        sqrt_start <= 0;
        if(sphere_1_sqrt_done && sphere_2_sqrt_done) begin
          sdf_out <= signed_minimum(
            (sphere_1_dist - 32'h00040_00), 
            (sphere_2_dist - 32'h00040_00)
          );
          sdf_red_out <= clamp_color(sphere_1_dist >> 7);
          sdf_green_out <= clamp_color(sphere_2_dist >> 7);
          sdf_blue_out <= 8'h00;
          sdf_done <= 1;

          state <= IDLE;
        end
      end
    end
  end
endmodule

module ray_gen (
  input wire clk_in,
  input wire rst_in,
  input wire ray_gen_start,
  output logic ray_gen_done,
  output logic signed [31:0] ray_gen_out_x,
  output logic signed [31:0] ray_gen_out_y,
  output logic signed [31:0] ray_gen_out_z,
  input wire signed [31:0] ray_gen_in_x,
  input wire signed [31:0] ray_gen_in_y,
  input wire signed [31:0] ray_gen_in_z
);

  logic signed [31:0] norm;
  logic signed [31:0] sqrt_in;
  logic processing;
  logic div_start;
  logic div_x_done;
  logic div_y_done;
  logic div_z_done;
  logic div_x_set;
  logic div_y_set;
  logic div_z_set;
  logic signed [31:0] div_x_out;
  logic signed [31:0] div_y_out;
  logic signed [31:0] div_z_out;
  logic sqrt_start;
  logic sqrt_done;
  logic signed [31:0] sqrt_out;

  sqrt sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sqrt_in),
    .root(sqrt_out),
    .valid(sqrt_done)
  );

  div divx (
    .clk(clk_in),
    .rst(rst_in),
    .start(div_start),
    .a(ray_gen_in_x),
    .b(norm),
    .done(div_x_done),
    .val(div_x_out)
  );

  div divy (
    .clk(clk_in),
    .rst(rst_in),
    .start(div_start),
    .a(ray_gen_in_y),
    .b(norm),
    .done(div_y_done),
    .val(div_y_out)
  );

  div divz (
    .clk(clk_in),
    .rst(rst_in),
    .start(div_start),
    .a(ray_gen_in_z),
    .b(norm),
    .done(div_z_done),
    .val(div_z_out)
  );

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      processing <= 0;
      ray_gen_done <= 0;
      sqrt_start <= 0;
      div_start <= 0;
    end else begin
      if(ray_gen_start && !processing) begin
        processing <= 1;
        sqrt_in <= square_mag(ray_gen_in_x, ray_gen_in_y, ray_gen_in_z);
        // $display("xin %h", ray_gen_in_x);
        // $display("yin %h", ray_gen_in_y);
        // $display("zin %h", ray_gen_in_z);
        // $display("sqrt_in %h", square_mag(ray_gen_in_x, ray_gen_in_y, ray_gen_in_z) >> 8);
        sqrt_start <= 1;
        ray_gen_done <= 0;
      end else begin
        sqrt_start <= 0;

        if(sqrt_done) begin
          norm <= sqrt_out;
          div_start <= 1;
          div_x_set <= 0;
          div_y_set <= 0;
          div_z_set <= 0;
        end else begin 
          div_start <= 0;
        end

        if(div_x_done) begin
          ray_gen_out_x <= div_x_out;
          div_x_set <= 1;
        end 
        if(div_y_done) begin
          ray_gen_out_y <= div_y_out;
          div_y_set <= 1;
        end 
        if(div_z_done) begin
          ray_gen_out_z <= div_z_out;
          div_z_set <= 1;
        end 

        if(div_x_set && div_y_set && div_z_set) begin
          processing <= 0;
          ray_gen_done <= 1;
        end
      end
    end
  end
endmodule

`default_nettype wire