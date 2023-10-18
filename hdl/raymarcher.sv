`timescale 1ns / 1ps
`default_nettype none


module raymarcher
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter MAX_STEPS = 100,
  parameter signed [31:0] MAX_DIST_SQUARE = 32'h00080_00,
  parameter signed [31:0] EPSILON = 32'h000000_10
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
  logic signed [31:0] sdf_out;
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
        ray_steps <= 0;
        $display("color out %d %d %d", red_out, green_out, blue_out);
        
        state <= INITIALIZING;
      end else if(state == INITIALIZING) begin
        ray_gen_in_x <= dec_to_24_8(curr_x - WIDTH/2'd2);
        ray_gen_in_y <= dec_to_24_8(curr_y - HEIGHT/2'd2);
        ray_gen_in_z <= dec_to_24_8(WIDTH/3'd4+HEIGHT/3'd4);
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
        sdf_start <= 0;

        if (sdf_done) begin
          $display("sdf_out %d d", sdf_out >> 8);

          if(sdf_out[31] || sdf_out < EPSILON) begin
            $display("breaking from surface contact at distance %h h", sdf_out);
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
        ray_x <= ray_x + mult_24_8(dir_x, sdf_out);
        ray_y <= ray_y + mult_24_8(dir_y, sdf_out);
        ray_z <= ray_z + mult_24_8(dir_z, sdf_out);
        $display("to %h %h %h", ray_x + mult_24_8(dir_x, sdf_out), ray_y + mult_24_8(dir_y, sdf_out), ray_z + mult_24_8(dir_z, sdf_out));
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
  input wire signed [31:0] x,
  input wire signed [31:0] y,
  input wire signed [31:0] z,
  output logic sdf_done,
  output logic signed [31:0] sdf_out
);
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
    end else begin
      if(sdf_start) begin
        sdf_out <= abs_24_8(x) + abs_24_8(y) + abs_24_8(z - 32'h00096_00) - 32'h00001_00;
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