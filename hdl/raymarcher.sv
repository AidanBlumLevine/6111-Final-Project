`timescale 1ns / 1ps
`default_nettype none

parameter BITS = 32;
parameter FIXED = 16;
parameter BG_RED = 8'hFF;
parameter BG_GREEN = 8'hFF;
parameter BG_BLUE = 8'hFF;

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
  parameter MAX_STEPS = 100,
  parameter signed [BITS-1:0] MAX_DIST_MANHATTEN = 1'b1 << (BITS - 7),
  parameter signed [BITS-1:0] EPSILON = 1'b1 << (FIXED - 3) // .0001
)
(
  input wire clk_in,
  input wire rst_in,
  input wire [$clog2(WIDTH)-1:0] curr_x,
  input wire [$clog2(HEIGHT)-1:0] curr_y,
  // ========================================
  input wire signed [BITS-1:0] camera_x,
  input wire signed [BITS-1:0] camera_y,
  input wire signed [BITS-1:0] camera_z,
  input wire signed [BITS-1:0] camera_u_x,
  input wire signed [BITS-1:0] camera_u_y,
  input wire signed [BITS-1:0] camera_u_z,
  input wire signed [BITS-1:0] camera_v_x,
  input wire signed [BITS-1:0] camera_v_y,
  input wire signed [BITS-1:0] camera_v_z,
  input wire signed [BITS-1:0] camera_forward_x,
  input wire signed [BITS-1:0] camera_forward_y,
  input wire signed [BITS-1:0] camera_forward_z,
  // ========================================
  input wire start_in,
  input wire [31:0] timer,
  output logic [23:0] color_out,
  output logic [$clog2(WIDTH)-1:0] out_x,
  output logic [$clog2(HEIGHT)-1:0] out_y,
  output logic pixel_done
);
  typedef enum {PIXEL_DONE=0, INITIALIZING=1, AWAITING_SDF=2, NORMALIZING_RAY=3, MARCHING1=4, MARCHING2=5, CALC_NORMAL=6, SHADING=7, SHADING2=8, SHADING3=9, PREINIT=10} raymarcher_state;
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

  // sdf sdf_inst (
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .sdf_start(sdf_start),
  //   .x(ray_x),
  //   .y(ray_y),
  //   .z(ray_z),
  //   .timer(timer),
  //   .sdf_done(sdf_done),
  //   .sdf_out(sdf_out),
  //   .sdf_red_out(sdf_red_out),
  //   .sdf_green_out(sdf_green_out),
  //   .sdf_blue_out(sdf_blue_out)
  // );

  // menger_sdf menger_sdf_inst (
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .sdf_start(sdf_start),
  //   .x(ray_x),
  //   .y(ray_y),
  //   .z(ray_z),
  //   .sdf_done(sdf_done),
  //   .sdf_out(sdf_out),
  //   .sdf_red_out(sdf_red_out),
  //   .sdf_green_out(sdf_green_out),
  //   .sdf_blue_out(sdf_blue_out)
  // );

  shapes_sdf shape_sdf_inst (
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

  logic signed [BITS-1:0] ray_dist;
  logic signed [BITS-1:0] ray_x;
  logic signed [BITS-1:0] ray_y;
  logic signed [BITS-1:0] ray_z;
  logic signed [BITS-1:0] dir_x;
  logic signed [BITS-1:0] dir_y;
  logic signed [BITS-1:0] dir_z;

  logic signed [BITS-1:0] light_fac;
  logic signed [BITS-1:0] light_weight;
  logic signed [BITS-1:0] tmp_x;
  logic signed [BITS-1:0] tmp_y;
  logic signed [BITS-1:0] tmp_z;
  localparam signed [BITS-1:0] light_x = to_fixed(28) >>> 5;
  localparam signed [BITS-1:0] light_y = to_fixed(11) >>> 5;
  localparam signed [BITS-1:0] light_z = to_fixed(-8) >>> 5;


  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= PIXEL_DONE;
    end else begin
      if(state == PIXEL_DONE && start_in) begin
        state <= PREINIT;
      end else if(state == PREINIT) begin
        out_x <= curr_x;
        out_y <= curr_y;
        tmp_x <= to_fixed(curr_x - (WIDTH>>1));
        tmp_y <= to_fixed(curr_y - (HEIGHT>>1));
        state <= INITIALIZING;
      end else if(state == INITIALIZING) begin
        ray_gen_in_x <= mult(tmp_x, camera_u_x) + mult(tmp_y, camera_v_x) + camera_forward_x;
        ray_gen_in_y <= mult(tmp_x, camera_u_y) + mult(tmp_y, camera_v_y) + camera_forward_y;
        ray_gen_in_z <= mult(tmp_x, camera_u_z) + mult(tmp_y, camera_v_z) + camera_forward_z;
        
        ray_gen_start <= 1;
        state <= NORMALIZING_RAY;
      end else if(state == NORMALIZING_RAY) begin
        ray_gen_start <= 0;
        if(~ray_gen_start && ray_gen_done) begin
          dir_x <= ray_gen_out_x;
          dir_y <= ray_gen_out_y;
          dir_z <= ray_gen_out_z;
          ray_x <= camera_x;
          ray_y <= camera_y;
          ray_z <= camera_z;
          ray_dist <= 0;
          ray_steps <= 0;
          sdf_start <= 1;
          state <= AWAITING_SDF;
        end
      end else if(state == AWAITING_SDF) begin
        sdf_start <= 0;
        if (sdf_done) begin
          if(sdf_out[BITS-1] || sdf_out < EPSILON) begin
            normal_base_dist <= sdf_out;
            color_out <= {sdf_red_out, sdf_green_out, sdf_blue_out};
            ray_gen_in_x <= UNCALCULATED_NORMAL_VALUE;
            ray_gen_in_y <= UNCALCULATED_NORMAL_VALUE;
            ray_gen_in_z <= UNCALCULATED_NORMAL_VALUE;
            ray_x <= ray_x + NORMAL_EPS;
            sdf_start <= 1;
            state <= CALC_NORMAL;
          end else begin
            state <= MARCHING1;
          end
        end
      end else if (state == MARCHING1) begin
        if(ray_steps > MAX_STEPS) begin
          color_out <= {8'hFF, 8'h00, 8'hFF};
          // color_out <= {BG_RED, BG_GREEN, BG_BLUE};
          state <= PIXEL_DONE;
        end else begin
          ray_x <= ray_x + mult(dir_x, sdf_out);
          ray_y <= ray_y + mult(dir_y, sdf_out);
          ray_z <= ray_z + mult(dir_z, sdf_out);
          ray_dist <= ray_dist + sdf_out;
          state <= MARCHING2;
        end
      end else if (state == MARCHING2) begin
        if(abs(ray_x) + abs(ray_y) + abs(ray_z) > MAX_DIST_MANHATTEN) begin
          color_out <= {BG_RED, BG_GREEN, BG_BLUE};
          state <= PIXEL_DONE;
        end else begin
          // domain repeptition =========================
          // if(ray_x > to_fixed(25)) begin
          //   ray_x <= ray_x - to_fixed(50);
          // end else if(ray_x < -to_fixed(25)) begin
          //   ray_x <= ray_x + to_fixed(50);
          // end
          // if(ray_y > to_fixed(25)) begin
          //   ray_y <= ray_y - to_fixed(50);
          // end else if(ray_y < -to_fixed(25)) begin
          //   ray_y <= ray_y + to_fixed(50);
          // end
          // if(ray_z > to_fixed(50)) begin
          //   ray_z <= ray_z - to_fixed(100);
          // end else if(ray_z < -to_fixed(50)) begin
          //   ray_z <= ray_z + to_fixed(100);
          // end
          // ===========================================

          ray_steps <= ray_steps + 1;
          sdf_start <= 1;
          state <= AWAITING_SDF;
        end
      end else if (state == CALC_NORMAL) begin
        if(~sdf_start && sdf_done) begin 
          if(0 && abs(sdf_out - normal_base_dist) > NORMAL_EPS) begin
            // this shouldnt be possible and indicates a rounding error on the initial read of this pixel
            state <= PIXEL_DONE;
            color_out <= {8'h00, 8'hFF, 8'hFF};
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
          light_fac <= (mult(ray_gen_out_x, light_x) + mult(ray_gen_out_y, light_y) + mult(ray_gen_out_z, light_z) + to_fixed(2)) >> 1;
          light_weight <= to_fixed(1) - ((ray_dist >> 8) <= to_fixed(1) ? (ray_dist >> 8) : to_fixed(1));
          state <= SHADING2;
        end
      end else if (state == SHADING2) begin
          light_fac <= mult(light_fac, light_weight);
          tmp_x <= (ray_gen_out_x + to_fixed(1)) << 7;
          tmp_y <= (ray_gen_out_y + to_fixed(1)) << 7;
          tmp_z <= (ray_gen_out_z + to_fixed(1)) << 7;
          state <= SHADING3;
      end else if (state == SHADING3) begin
        // red_out <= mult(to_fixed(red_out), (to_fixed(4) + (light_fac <<< 2)) >>> 4) >>> FIXED;
        // green_out <= mult(to_fixed(green_out), (to_fixed(4) + (light_fac <<< 2)) >>> 4) >>> FIXED;
        // blue_out <= mult(to_fixed(blue_out), (to_fixed(4) + (light_fac <<< 2)) >>> 4) >>> FIXED;
        color_out <= {clamp_color((mult(tmp_x, light_fac)) >>> FIXED),
                      clamp_color((mult(tmp_y, light_fac)) >>> FIXED),
                      clamp_color((mult(tmp_z, light_fac)) >>> FIXED)};

        // red_out <= clamp_color((mult(to_fixed(red_out), light_fac >> 1)) >>> FIXED);
        // green_out <= clamp_color((mult(to_fixed(green_out), light_fac >> 1)) >>> FIXED);
        // blue_out <= clamp_color((mult(to_fixed(blue_out), light_fac >> 1)) >>> FIXED);
        // red_out <= 255 - (ray_dist >> FIXED);
        // green_out <= 255 - (ray_dist >> FIXED);
        // blue_out <= 255 - (ray_dist >> FIXED);
        // red_out <= BG_RED;
        // green_out <= BG_GREEN;
        // blue_out <= BG_BLUE;
        state <= PIXEL_DONE;
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
          sdf_out <= signed_minimum(signed_minimum(
            (sphere_1_dist - to_fixed(10)), 
            (sphere_2_dist - to_fixed(10))),
            (sphere_3_dist - to_fixed(16))
          );
          if(sphere_1_dist < sphere_2_dist && sphere_1_dist < sphere_3_dist - to_fixed(6)) begin
            sdf_red_out <= 8'hF0;
            sdf_green_out <= 8'h00;
            sdf_blue_out <= 8'hF0;
          end else if (sphere_2_dist < sphere_3_dist - to_fixed(6)) begin
            sdf_red_out <= 8'h00;
            sdf_green_out <= 8'hF0;
            sdf_blue_out <= 8'h00;
          end else begin
            sdf_red_out <= 8'h00;
            sdf_green_out <= 8'h00;
            sdf_blue_out <= 8'hF0;
          end
          state <= DONE;
        end
      end else if (state == DONE) begin
        state <= IDLE;
      end
    end
  end
endmodule

module ray_gen_quick (
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

  logic signed [BITS-1:0] sqrt_in;
  logic sqrt_start;
  logic sqrt_done;
  logic signed [BITS-1:0] sqrt_out;

  typedef enum {IDLE=0, COMPUTE=1} raygen_state;
  raygen_state state;

  // Instantiate the inv_sqrt module
  inv_sqrt #(
    .WIDTH(BITS),
    .FBITS(FIXED)
  ) sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sqrt_in),
    .root(sqrt_out),
    .valid(sqrt_done)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      ray_gen_done <= 0;
      sqrt_start <= 0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (ray_gen_start) begin
            sqrt_in <= square_mag(ray_gen_in_x, ray_gen_in_y, ray_gen_in_z);
            sqrt_start <= 1;
            ray_gen_done <= 0;
            state <= COMPUTE;
          end
        end
        COMPUTE: begin
          sqrt_start <= 0;
          if (~sqrt_start && sqrt_done) begin
            ray_gen_out_x <= mult(ray_gen_in_x, sqrt_out);
            ray_gen_out_y <= mult(ray_gen_in_y, sqrt_out);
            ray_gen_out_z <= mult(ray_gen_in_z, sqrt_out);
            ray_gen_done <= 1;
            state <= IDLE;
          end
        end
      endcase
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
  logic div_start;
  logic div_x_done;
  logic div_y_done;
  logic div_z_done;
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
      ray_gen_done <= 0;
      sqrt_start <= 0;
      div_start <= 0;
      state <= IDLE;
    end else begin
      case(state)
        IDLE: begin
          if(ray_gen_start) begin
            sqrt_in <= square_mag(ray_gen_in_x, ray_gen_in_y, ray_gen_in_z);
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