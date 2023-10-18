`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module raymarcher
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter MAX_STEPS = 100,
  parameter [23:0] MAX_DIST_SQUARE = 24'h008_00, //Q16.8
  parameter [23:0] EPSILON = 24'hF000_10 //Q16.8
)
(
  input wire clk_pixel_in,
  input wire rst_in,
  input wire [$clog2(WIDTH)-1:0] curr_x,
  input wire [$clog2(HEIGHT)-1:0] curr_y,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic pixel_done,

  output logic [23:0] ray_dist_squared,
  output logic [$clog2(MAX_STEPS):0] ray_steps
);

  logic signed [23:0] ray_x; //Q16.8
  logic signed [23:0] ray_y; //Q16.8
  logic signed [23:0] ray_z; //Q16.8
  logic signed [23:0] dir_x; //Q16.8
  logic signed [23:0] dir_y; //Q16.8
  logic signed [23:0] dir_z; //Q16.8
  // logic [$clog2(MAX_STEPS):0] ray_steps;
  // logic [23:0] ray_dist_squared;

  always_ff @(posedge clk_pixel_in) begin
    if(rst_in) begin
      ray_steps <= 0;
      pixel_done <= 0;
      ray_dist_squared <= 0;
    end else begin
      if(pixel_done) begin
        // reset, renderer will send new pixel coords next cycle
        ray_steps <= 0;
        pixel_done <= 0;
        ray_dist_squared <= 0;
      end else if(ray_steps == 0) begin
        // new ray has just been initialized
        dir_x <= dec_to_16_8(curr_x - WIDTH/2'd2);
        dir_y <= dec_to_16_8(curr_y - HEIGHT/2'd2);
        dir_z <= dec_to_16_8(WIDTH/3'd4+HEIGHT/3'd4);
        ray_x <= 0;
        ray_y <= 0;
        ray_z <= 0;
        ray_steps <= 1;

        red_out <= 8'hFF;
        green_out <= 8'hFF;
        blue_out <= 8'hFF;
      end else if(ray_steps == MAX_STEPS || ray_dist_squared > MAX_DIST_SQUARE) begin
        // ray has reached max depth, send pixel
        pixel_done <= 1;
      end else begin
        // ray is in flight
        ray_x <= ray_x + dir_x;
        ray_y <= ray_y + dir_y;
        ray_z <= ray_z + dir_z;
        // $display("dir_x: %h, dir_y: %h, dir_z: %h", dir_x, dir_y, dir_z);
        // $display("ray_x: %h, ray_y: %h, ray_z: %h", ray_x, ray_y, ray_z);

        ray_dist_squared <= square_mag(ray_x, ray_y, ray_z);
        ray_steps <= ray_steps + 1;

        if(ray_dist_squared > MAX_DIST_SQUARE) begin
          red_out <= 8'h00;
          green_out <= 8'h00;
          blue_out <= 8'h00;
        end
      end
    end
  end
endmodule

function logic [23:0] square_mag;
  input logic signed [23:0] x;
  input logic signed [23:0] y;
  input logic signed [23:0] z;
  begin
    square_mag = mult_16_8(x,x) + mult_16_8(y,y) + mult_16_8(z,z);
  end
endfunction

function logic [23:0] mult_16_8;
  input logic signed [23:0] a;
  input logic signed [23:0] b;
  begin
    mult_16_8 = (a * b) >> 8;
  end
endfunction

function logic [23:0] dec_to_16_8;
  input logic [31:0] a;
  begin
    dec_to_16_8 = {a, 8'h00};
  end
endfunction

`default_nettype wire