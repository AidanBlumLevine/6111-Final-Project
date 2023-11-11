`timescale 1ns / 1ps
`default_nettype none

parameter BITS = 32;
parameter FIXED = 16;

function logic signed [BITS-1:0] mult;
  input logic signed [BITS-1:0] a;
  input logic signed [BITS-1:0] b;
  logic signed [2*BITS-1:0] intermediate;
  begin
    intermediate = a * b;
    mult = {intermediate[2*BITS-1], intermediate[BITS + FIXED - 2: FIXED]};
  end
endfunction

function logic signed [BITS-1:0] square_mag;
  input logic signed [BITS-1:0] x;
  input logic signed [BITS-1:0] y;
  input logic signed [BITS-1:0] z;
  logic signed [BITS-1:0] i;
  logic signed [BITS-1:0] j;
  logic signed [BITS-1:0] k;
  begin
    i = mult(x,x);
    j = mult(y,y);
    k = mult(z,z);
    square_mag = i + j + k;
  end
endfunction

function logic signed [BITS-1:0] to_fixed;
  input logic [BITS - FIXED - 1:0] a;
  begin
    to_fixed = {a, {FIXED{1'b0}}};
  end
endfunction

function logic signed [BITS-1:0] abs;
  input logic signed [BITS-1:0] a;
  begin
    abs = a[BITS-1] ? ~a + 1 : a;
  end
endfunction

function logic signed [BITS-1:0] signed_minimum;
  input logic signed [BITS-1:0] a;
  input logic signed [BITS-1:0] b;
  begin
    if(a[BITS-1] && !b[BITS-1]) begin
      signed_minimum = a;
    end else if(!a[BITS-1] && b[BITS-1]) begin
      signed_minimum = b;
    end else if(a[BITS-1] && b[BITS-1]) begin
      signed_minimum = a > b ? a : b;
    end else begin
      signed_minimum = a < b ? a : b;
    end
  end
endfunction

function logic [7:0] clamp_color;
  input logic [BITS-1:0] a;
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
  parameter MAX_STEPS = 200,
  parameter signed [BITS-1:0] MAX_DIST_MANHATTEN = 1'b1 << (BITS - 7),
  parameter signed [BITS-1:0] EPSILON = 1'b1 << (FIXED - 3) // .0001
)
(
  input wire clk_in,
  input wire rst_in,
  input wire [$clog2(WIDTH)-1:0] curr_x,
  input wire [$clog2(HEIGHT)-1:0] curr_y,
  input wire [31:0] timer,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out,
  output logic [$clog2(WIDTH)-1:0] out_x,
  output logic [$clog2(HEIGHT)-1:0] out_y,
  output logic pixel_done
);
  typedef enum {PIXEL_DONE=0, INITIALIZING=1, AWAITING_SDF=2, NORMALIZING_RAY=3, MARCHING1=4, MARCHING2=5, CALC_NORMAL=6, SHADING=7} raymarcher_state;
  raymarcher_state state;
  always_comb begin
    pixel_done = state == PIXEL_DONE;
  end

  logic [$clog2(MAX_STEPS):0] ray_steps;

  logic signed [BITS-1:0] normal_base_dist;
  localparam UNCALCULATED_NORMAL_VALUE = {3'b111, {FIXED{1'b0}}};
  localparam NORMAL_EPS = {1'b1, {(FIXED-5){1'b0}}};

  logic sdf_start;
  logic sdf_done;
  logic signed [BITS-1:0] sdf_out;
  logic [7:0] sdf_red_out;
  logic [7:0] sdf_green_out;
  logic [7:0] sdf_blue_out;
  sdf sdf_inst (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sdf_start(sdf_start),
    .x(ray_x),
    .y(ray_y),
    .z(ray_z),
    .timer(timer),
    .sdf_done(sdf_done),
    .sdf_out(sdf_out),
    .sdf_red_out(sdf_red_out),
    .sdf_green_out(sdf_green_out),
    .sdf_blue_out(sdf_blue_out)
  );

  logic ray_gen_start;
  logic ray_gen_done;
  logic signed [BITS-1:0] ray_gen_out_x;
  logic signed [BITS-1:0] ray_gen_out_y;
  logic signed [BITS-1:0] ray_gen_out_z;
  logic signed [BITS-1:0] ray_gen_in_x;
  logic signed [BITS-1:0] ray_gen_in_y;
  logic signed [BITS-1:0] ray_gen_in_z;
  ray_gen ray_gen_inst (
    .clk_in(clk_in),
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

  logic signed [BITS-1:0] ray_x;
  logic signed [BITS-1:0] ray_y;
  logic signed [BITS-1:0] ray_z;
  logic signed [BITS-1:0] dir_x;
  logic signed [BITS-1:0] dir_y;
  logic signed [BITS-1:0] dir_z;

  always_ff @(posedge clk_in) begin
    // if(state == PIXEL_DONE) begin
    //   $display("PIXEL_DONE");
    // end else if(state == INITIALIZING) begin
    //   $display("INITIALIZING");
    // end else if(state == AWAITING_SDF) begin
    //   $display("AWAITING_SDF");
    // end else if(state == NORMALIZING_RAY) begin
    //   $display("NORMALIZING_RAY");
    // end else if(state == MARCHING) begin
    //   $display("MARCHING");
    // end

    if(rst_in) begin
      state <= PIXEL_DONE;
    end else begin
      if(state == PIXEL_DONE) begin
        // $display("color out %d %d %d", red_out, green_out, blue_out);
        
        state <= INITIALIZING;
      end else if(state == INITIALIZING) begin
        ray_gen_in_x <= to_fixed(curr_x - WIDTH/2'd2);
        ray_gen_in_y <= to_fixed(curr_y - HEIGHT/2'd2);
        ray_gen_in_z <= to_fixed(WIDTH/3'd4+HEIGHT/3'd4);
        out_x <= curr_x;
        out_y <= curr_y;
        // $display("ray_gen_in curr_x %h adj %h fixed%h",curr_x, curr_x - WIDTH/2'd2, to_fixed(curr_x - WIDTH/2'd2));
        ray_gen_start <= 1;
        state <= NORMALIZING_RAY;
      end else if(state == NORMALIZING_RAY) begin
        ray_gen_start <= 0;
        if(~ray_gen_start && ray_gen_done) begin
          dir_x <= ray_gen_out_x;
          dir_y <= ray_gen_out_y;
          dir_z <= ray_gen_out_z;
          ray_x <= 0;
          ray_y <= 0;
          ray_z <= 0;
          ray_steps <= 0;

          // $display("normalized to (.%d) (.%d) (.%d)", $signed(ray_gen_out_x >> (FIXED-3)), $signed(ray_gen_out_y >> (FIXED-3)), $signed(ray_gen_out_z >> (FIXED-3)));

          sdf_start <= 1;
          state <= AWAITING_SDF;
        end
      end else if(state == AWAITING_SDF) begin
        sdf_start <= 0;
        if (sdf_done) begin
          $display("sdf_out %d", sdf_out >> FIXED);

          if(sdf_out[BITS-1] || sdf_out < EPSILON) begin
            // $display("breaking from surface contact at distance %h h", sdf_out);

            // red_out <= sdf_red_out >> (ray_steps >> 1);
            // green_out <= sdf_green_out >> (ray_steps >> 1);
            // blue_out <= sdf_blue_out >> (ray_steps >> 1);
            // state <= PIXEL_DONE;
            normal_base_dist <= sdf_out;
            // $display(" normal_base_dist %d", sdf_out);
            ray_gen_in_x <= UNCALCULATED_NORMAL_VALUE;
            ray_gen_in_y <= UNCALCULATED_NORMAL_VALUE;
            ray_gen_in_z <= UNCALCULATED_NORMAL_VALUE;
            ray_x <= ray_x + NORMAL_EPS;
            // $display("ray x %d", $signed(ray_x));
            // $display("ray y %d", $signed(ray_y));
            // $display("ray z %d", $signed(ray_z));
            sdf_start <= 1;
            state <= CALC_NORMAL;
          end else begin
            state <= MARCHING1;
          end
        end
      end else if (state == MARCHING1) begin
        $display("marching from %d %d %d", $signed(ray_x >> FIXED), $signed(ray_y >> FIXED), $signed(ray_z >> FIXED));
        if(ray_steps > MAX_STEPS) begin
          // $display("breaking from max steps");
          red_out <= 8'hFF;
          green_out <= 8'h00;
          blue_out <= 8'hFF;

          state <= PIXEL_DONE;
        end else begin
          ray_x <= ray_x + mult(dir_x, sdf_out);
          ray_y <= ray_y + mult(dir_y, sdf_out);
          ray_z <= ray_z + mult(dir_z, sdf_out);
          state <= MARCHING2;
        end
      end else if (state == MARCHING2) begin
        if(abs(ray_x) + abs(ray_y) + abs(ray_z) > MAX_DIST_MANHATTEN) begin
          red_out <= 8'hFF;
          green_out <= 8'hFF;
          // blue_out <= out_x[4] ^ out_y[4] ? 8'hFF : 8'h00;
          blue_out <= 8'hFF;

          state <= PIXEL_DONE;
        end else begin
          ray_steps <= ray_steps + 1;
          sdf_start <= 1;
          state <= AWAITING_SDF;
        end
      end else if (state == CALC_NORMAL) begin
        if(~sdf_start && sdf_done) begin 
          if(abs(sdf_out - normal_base_dist) > NORMAL_EPS) begin
            // this shouldnt be possible and indicates a rounding error on the initial read of this pixel
            state <= PIXEL_DONE;
            red_out <= 8'h00;
            green_out <= 8'h00;
            blue_out <= 8'h00;
          end else if (ray_gen_in_x == UNCALCULATED_NORMAL_VALUE) begin
            ray_gen_in_x <= (sdf_out - normal_base_dist) <<< 4;
            ray_x <= ray_x - NORMAL_EPS;
            ray_y <= ray_y + NORMAL_EPS;
            sdf_start <= 1;
          end else if (ray_gen_in_y == UNCALCULATED_NORMAL_VALUE) begin
            ray_gen_in_y <= (sdf_out - normal_base_dist) <<< 4;
            ray_y <= ray_y - NORMAL_EPS;
            ray_z <= ray_z + NORMAL_EPS;
            sdf_start <= 1;
          end else if (ray_gen_in_z == UNCALCULATED_NORMAL_VALUE) begin
            ray_gen_in_z <= (sdf_out - normal_base_dist) <<< 4;
            ray_gen_start <= 1;
            state <= SHADING;
          end
        end else begin
          sdf_start <= 0;
        end
      end else if (state == SHADING) begin
        ray_gen_start <= 0;
        if(~ray_gen_start && ray_gen_done) begin
          // $display("normalized ray %d %d %d", ray_gen_out_x, ray_gen_out_y, ray_gen_out_z);
          red_out <= mult(to_fixed(127), ray_gen_out_x + to_fixed(1)) >>> FIXED;
          green_out <= mult(to_fixed(127), ray_gen_out_y + to_fixed(1)) >>> FIXED;
          blue_out <= mult(to_fixed(127), ray_gen_out_z + to_fixed(1)) >>> FIXED;
          state <= PIXEL_DONE;
        end
      end
    end
  end
endmodule

module sdf (
  input wire clk_in,
  input wire rst_in,
  input wire sdf_start,
  input wire signed [BITS-1:0] x,
  input wire signed [BITS-1:0] y,
  input wire signed [BITS-1:0] z,
  input wire [31:0] timer,
  output logic sdf_done,
  output logic signed [BITS-1:0] sdf_out,
  output logic [7:0] sdf_red_out,
  output logic [7:0] sdf_green_out,
  output logic [7:0] sdf_blue_out
);
  typedef enum {IDLE=0, PROCESSING=1, DONE=2, SQUARE=3} sdf_state;
  sdf_state state;

  logic signed [BITS-1:0] sphere_1_dist_squared;
  logic signed [BITS-1:0] sphere_2_dist_squared;
  logic signed [BITS-1:0] sphere_3_dist_squared;
  logic sphere_1_sqrt_done;
  logic sphere_2_sqrt_done;
  logic sphere_3_sqrt_done;
  logic signed [BITS-1:0] sphere_1_dist;
  logic signed [BITS-1:0] sphere_2_dist;
  logic signed [BITS-1:0] sphere_3_dist;
  logic sqrt_start;

  logic signed [BITS-1:0] tmp_x_1;
  logic signed [BITS-1:0] tmp_y_1;
  logic signed [BITS-1:0] tmp_z_1;
  logic signed [BITS-1:0] tmp_x_2;
  logic signed [BITS-1:0] tmp_y_2;
  logic signed [BITS-1:0] tmp_z_2;
  logic signed [BITS-1:0] tmp_x_3;
  logic signed [BITS-1:0] tmp_y_3;
  logic signed [BITS-1:0] tmp_z_3;

  always_comb begin
    sdf_done = state == DONE;
  end

  sqrt #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_1_dist_squared),
    .root(sphere_1_dist),
    .valid(sphere_1_sqrt_done)
  );

  sqrt #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) sqrt_inst2 (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_2_dist_squared),
    .root(sphere_2_dist),
    .valid(sphere_2_sqrt_done)
  );

  sqrt #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) sqrt_inst3 (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_3_dist_squared),
    .root(sphere_3_dist),
    .valid(sphere_3_sqrt_done)
  );

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= IDLE;
      sqrt_start <= 0;
    end else begin
      if (state == IDLE) begin
        if(sdf_start) begin
          tmp_x_1 <= x + to_fixed(timer[3:0]) - to_fixed(8);
          tmp_y_1 <= y - to_fixed(7);
          tmp_z_1 <= z - to_fixed(50);
          tmp_x_2 <= x;
          tmp_y_2 <= y + to_fixed(7);
          tmp_z_2 <= z - to_fixed(50);
          tmp_x_3 <= x - to_fixed(16);
          tmp_y_3 <= y;
          tmp_z_3 <= z - to_fixed(60) + to_fixed(timer[3:0]);
          state <= SQUARE;
        end
      end else if(state == SQUARE) begin
        sqrt_start <= 1;
        sphere_1_dist_squared <= square_mag(tmp_x_1, tmp_y_1, tmp_z_1);
        sphere_2_dist_squared <= square_mag(tmp_x_2, tmp_y_2, tmp_z_2);
        sphere_3_dist_squared <= square_mag(tmp_x_3, tmp_y_3, tmp_z_3);
        state <= PROCESSING;
      end else if(state == PROCESSING) begin
        if(sqrt_start) begin
          sqrt_start <= 0;
        end else if(sphere_1_sqrt_done && sphere_2_sqrt_done && sphere_3_sqrt_done) begin
          $display("sphere_1_dist %b", sphere_1_dist - to_fixed(10));
          $display("sphere_2_dist %b", sphere_2_dist - to_fixed(10));
          $display("sphere_3_dist %b", sphere_3_dist - to_fixed(16));
          $display("MIN %d", signed_minimum(signed_minimum(
            (sphere_1_dist - to_fixed(10)), 
            (sphere_2_dist - to_fixed(10))),
            (sphere_3_dist - to_fixed(16))
          ) >>> FIXED);
          sdf_out <= signed_minimum(signed_minimum(
            (sphere_1_dist - to_fixed(10)), 
            (sphere_2_dist - to_fixed(10))),
            (sphere_3_dist - to_fixed(16))
          );
          sdf_red_out <= sphere_1_dist < sphere_2_dist ? 8'hF0 : 8'h00;
          sdf_green_out <= sphere_1_dist >= sphere_2_dist ? 8'hF0 : 8'h00;
          sdf_blue_out <= sphere_1_dist >= sphere_2_dist ? 8'hF0 : 8'h00;
          state <= DONE;
        end
      end else if (state == DONE) begin
        state <= IDLE;
      end
    end
  end
endmodule

module ray_gen (
  input wire clk_in,
  input wire rst_in,
  input wire ray_gen_start,
  output logic ray_gen_done,
  output logic signed [BITS-1:0] ray_gen_out_x,
  output logic signed [BITS-1:0] ray_gen_out_y,
  output logic signed [BITS-1:0] ray_gen_out_z,
  input wire signed [BITS-1:0] ray_gen_in_x,
  input wire signed [BITS-1:0] ray_gen_in_y,
  input wire signed [BITS-1:0] ray_gen_in_z
);

  logic signed [BITS-1:0] norm;
  logic signed [BITS-1:0] sqrt_in;
  logic processing;
  logic div_start;
  logic div_x_done;
  logic div_y_done;
  logic div_z_done;
  logic div_x_set;
  logic div_y_set;
  logic div_z_set;
  logic signed [BITS-1:0] div_x_out;
  logic signed [BITS-1:0] div_y_out;
  logic signed [BITS-1:0] div_z_out;
  logic sqrt_start;
  logic sqrt_done;
  logic signed [BITS-1:0] sqrt_out;

  typedef enum {IDLE=0, CALC_NORMAL=1, DIVIDING=2} raygen_state;
  raygen_state state;

  sqrt #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sqrt_in),
    .root(sqrt_out),
    .valid(sqrt_done)
  );

  div #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) divx (
    .clk(clk_in),
    .rst(rst_in),
    .start(div_start),
    .a(ray_gen_in_x),
    .b(norm),
    .done(div_x_done),
    .val(div_x_out)
  );

  div #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) divy (
    .clk(clk_in),
    .rst(rst_in),
    .start(div_start),
    .a(ray_gen_in_y),
    .b(norm),
    .done(div_y_done),
    .val(div_y_out)
  );

  div #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) divz (
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
      state <= IDLE;
    end else begin
      case(state)
        IDLE: begin
          if(ray_gen_start) begin
            sqrt_in <= square_mag(ray_gen_in_x, ray_gen_in_y, ray_gen_in_z);
            div_x_set <= 0;
            div_y_set <= 0;
            div_z_set <= 0;
            sqrt_start <= 1;
            ray_gen_done <= 0;
            state <= CALC_NORMAL;
          end
        end
        CALC_NORMAL: begin
          sqrt_start <= 0;
          if(~sqrt_start && sqrt_done) begin
            norm <= sqrt_out;
            div_start <= 1;
            state <= DIVIDING;
          end
        end
        DIVIDING: begin
          div_start <= 0;
          if(~div_start && div_x_done && div_y_done && div_z_done) begin
            ray_gen_out_x <= div_x_out;
            ray_gen_out_y <= div_y_out;
            ray_gen_out_z <= div_z_out;
            ray_gen_done <= 1;
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule

`default_nettype wire