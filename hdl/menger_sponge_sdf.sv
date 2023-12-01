`timescale 1ns / 1ps
`default_nettype none


// // VECTOR FUNCTIONS

// // 3 dimensional vector structure
// typedef struct {
//     logic signed [BITS-1:0] x;
//     logic signed [BITS-1:0] y;
//     logic signed [BITS-1:0] z;
// } vec3;

// 3 dimensional vector subtraction
function vec3 vec3_sub;
    input vec3 a;
    input vec3 b;
    begin
        vec3_sub.x = a.x - b.x;
        vec3_sub.y = a.y - b.y;
        vec3_sub.z = a.z - b.z;
    end
endfunction

// Produces a new vector of the absolute value of vector v
function vec3 abs_vec3;
    input vec3 v;
    begin 
        abs_vec3.x = abs(v.x);
        abs_vec3.y = abs(v.y);
        abs_vec3.z = abs(v.z);
    end
endfunction

// Uses Aidan's implementation of sqrt in hdl/math.sv to return the length of a vector
function logic [BITS-1:0] length_vec3;
    input vec3 v;
    begin
        length_vec3 = sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    end
endfunction

// END VECTOR FUNCTIONS


function logic signed [BITS-1:0] signed_maximum;
  input logic signed [BITS-1:0] a;
  input logic signed [BITS-1:0] b;
  begin
    if(a[BITS-1] && !b[BITS-1]) begin
      signed_maximum = b;
    end else if(!a[BITS-1] && b[BITS-1]) begin
      signed_maximum = a;
    end else if(a[BITS-1] && b[BITS-1]) begin
      signed_maximum = a > b ? b : a;
    end else begin
      signed_maximum = a < b ? b : a;
    end
  end
endfunction


// function logic signed [BITS-1:0] sdBox;
//     input vec3 p;
//     input vec3 b;
//     begin
//         vec3_sub.x = a.x - b.x;
//         vec3_sub.y = a.y - b.y;
//         vec3_sub.z = a.z - b.z;
//     end
// endfunction

// // Absolute value of number to run vector coords through
// function logic signed [BITS-1:0] abs;
//   input logic signed [BITS-1:0] a;
//   begin
//     abs = a[BITS-1] ? ~a + 1 : a;
//   end
// endfunction

// // Produces a new vector of the absolute value of vector v
// function vec3 abs_vec3;
//     input vec3 v;
//     begin 
//         abs_vec3.x = abs(v.x);
//         abs_vec3.y = abs(v.y);
//         abs_vec3.z = abs(v.z);
//     end
// endfunction

// // Uses Aidan's implementation of sqrt in hdl/math.sv to return the length of a vector
// function logic [BITS-1:0] length_vec3;
//     input vec3 v;
//     begin
//         length_vec3 = sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
//     end
// endfunction

function vec3 trans;
    input vec3 p;
    input logic [BITS-1:0] scale;
    vec3 scale_vec;
    logic signed [BITS-1:0] prev_x;
    logic signed [BITS-1:0] prev_z;
    begin
        scale_vec.x = scale;
        scale_vec.y = scale;
        scale_vec.z = scale;

        p = vec3_sub(abs_vec3(p), scale_vec);
        p.x = p.x * to_fixed(-1);
        p.y = p.y * to_fixed(-1);
        p.z = p.z * to_fixed(-1);

        prev_x = p.x;
        p.x = ((p.x - p.y > 0) ? p.y : p.x);
        p.y = ((prev_x - p.y > 0) ? prev_x : p.y);
        prev_z = p.z;
        p.z = ((p.z - p.y > 0) ? p.y : p.z);
        p.y = ((prev_z - p.y > 0) ? prev_z : p.y);

        p.y = (abs(p.y-0.5*scale)-0.5*scale);

        return p;    
    end
endfunction

// function vec3 trans;
//     input vec3 p;
//     input logic [BITS-1:0] scale;
//     logic vec3 scale_vec;
//     logic signed [BITS-1:0] prev_x;
//     logic signed [BITS-1:0] prev_y;
//     begin
//         scale_vec.x = scale;
//         scale_vec.y = scale;
//         scale_vec.z = scale;

//         p = vec3_sub(abs_vec3(p), scale_vec);
//         p.x = p.x * -1;
//         p.y = p.y * -1;
//         p.z = p.z * -1;

//         prev_x = p.x;
//         p.x = ((p.x - p.y > 0.) ? p.y : p.x);
//         p.y = ((prev_x - p.y > 0.) ? prev_x : p.y);
//         prev_z = p.z;
//         p.z = ((p.z - p.y > 0.) ? p.y : p.z);
//         p.y = ((prev_z - p.y > 0.) ? prev_z : p.y);

//         p.y = (abs(p.y-0.5*s)-0.5*s);

//         return p;    
//     end
// endfunction

module sdf (
  input wire clk_in,
  input wire rst_in,
  input wire sdf_start,
  input wire signed [BITS-1:0] x,
  input wire signed [BITS-1:0] y,
  input wire signed [BITS-1:0] z,
  output logic sdf_done,
  output logic signed [BITS-1:0] sdf_out,
  output logic [7:0] sdf_red_out,
  output logic [7:0] sdf_green_out,
  output logic [7:0] sdf_blue_out
);
  typedef enum {IDLE=0, TRANS=1, DIV=2, INIT_Q=3, LEN_Q=4, SDF_BOX=5, FINAL_DIV=6, DONE=7} sdf_state;
  sdf_state state;
  vec3 p;
  logic [BITS-1:0] scale;
  vec3 half_vec;
  logic [BITS-1:0] p_scale;
  vec3 q;
  logic signed [BITS-1:0] sdBox;
  logic [BITS-1:0] length_q;

//   logic div_p_start;
//   logic div_p_done;
//   logic signed [BITS-1:0] div_p_out;

//   logic div_b_start;
//   logic div_b_done;
//   logic signed [BITS-1:0] div_b_in;
//   logic signed [BITS-1:0] div_b_out;

//   logic sqrt_start;
//   logic sqrt_done;
//   logic signed [BITS-1:0] sqrt_in;
//   logic signed [BITS-1:0] sqrt_out;

//   always_comb begin
//     sdf_done = state == DONE;
//   end

//   sqrt #(
//     .WIDTH(BITS),
//     .FBITS(FIXED)
//   ) sqrt_inst (
//     .clk(clk_in),
//     .start(sqrt_start),
//     .rad(sqrt_in),
//     .root(sqrt_out),
//     .valid(sqrt_done)
//   );

//   div #(
//     .WIDTH(BITS),
//     .FBITS(FIXED)
//   ) divp (
//     .clk(clk_in),
//     .rst(rst_in),
//     .start(div_p_start),
//     .a(p_scale),
//     .b(to_fixed(3)),
//     .done(div_p_done),
//     .val(div_p_out)
//   );

//   div #(
//     .WIDTH(BITS),
//     .FBITS(FIXED)
//   ) div_box (
//     .clk(clk_in),
//     .rst(rst_in),
//     .start(div_b_start),
//     .a(div_b_in),
//     .b(scale - to_fixed(0.0005)),
//     .done(div_b_done),
//     .val(div_b_out)
//   );

  assign sdf_red_out = 8'hF0;
  assign sdf_green_out = 8'h00;
  assign sdf_blue_out = 8'h00;
  
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= IDLE;
      sqrt_start <= 0;
      div_p_start <= 0;
    end else begin
      case(state)
      IDLE: begin
        if(sdf_start) begin
          scale <= to_fixed(260);
          half_vec.x <= to_fixed(0.5);
          half_vec.y <= to_fixed(0.5);
          half_vec.z <= to_fixed(0.5);
          p.x <= x * scale;
          p.y <= y * scale;
          p.z <= z * scale;
          p_scale <= to_fixed(27*9);
          state <= TRANS;
        end 
      end
      TRANS: begin
        p <= trans(p, p_scale);
        if(p_scale == 1)begin
          state <= SDF_BOX;
        end else begin
          div_p_start <= 1;
          state <= DIV;
        end
      end
      DIV: begin
          if(div_p_done)begin
            p_scale <= div_p_out;
            div_p_start <= 0;
            state <= TRANS;
          end
      end
      INIT_Q: begin
        q <= vec3_sub(abs_vec3(p), half_vec);
        state <= LEN_Q;
        sqrt_in <= (q.x*q.x + q.y*q.y + q.z*q.z);
        sqrt_start <= 1;
      end
      LEN_Q: begin
        if(sqrt_done)begin
          length_q <= sqrt_out;
          sqrt_start <= 0;
          state <= SDF_BOX;
        end
      end
      SDF_BOX: begin
        sdBox <= signed_maximum(length_q, 0) + signed_minimum(signed_maximum(q.x, signed_maximum(q.y,q.z)),0);
        div_b_in <= sdBox;
        div_b_start <= 1;
        state <= FINAL_DIV;
      end
      FINAL_DIV: begin
        if (div_b_done) begin
          div_b_start <= 0;
          sdf_out <= div_b_out;
          state <= DONE;
        end
      end 
      DONE: begin
        state <= IDLE;
      end
      endcase
    end
  end
endmodule
