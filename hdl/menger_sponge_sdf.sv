`timescale 1ns / 1ps
`default_nettype none


// // VECTOR FUNCTIONS

// 3 dimensional vector structure
typedef struct packed {
    logic signed [BITS-1:0] x;
    logic signed [BITS-1:0] y;
    logic signed [BITS-1:0] z;
} vec3;

// 3 dimensional vector subtraction
function vec3 vec3_sub;
    input vec3 a;
    input vec3 b;
    vec3 vec3_subbed;
    begin
        vec3_subbed.x = a.x - b.x;
        vec3_subbed.y = a.y - b.y;
        vec3_subbed.z = a.z - b.z;
        return vec3_subbed;
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


function vec3 trans;
    input vec3 p;
    input logic [BITS-1:0] scale;
    logic signed [BITS-1:0] prev_x;
    logic signed [BITS-1:0] prev_z;
    begin
        p.x = ~p.x + 1;
        p.y = ~p.y + 1;
        p.z = ~p.z + 1;
        
        prev_x = p.x;
        p.x = ((p.x - p.y > 0) ? p.y : p.x);
        p.y = ((prev_x - p.y > 0) ? prev_x : p.y);
        prev_z = p.z;
        p.z = ((p.z - p.y > 0) ? p.y : p.z);
        p.y = ((prev_z - p.y > 0) ? prev_z : p.y);

        p.y = (abs(p.y-(scale >>> 1))-(scale >>> 1));

        return p;    
    end
endfunction

module menger_sdf (
  input wire clk_in,
  input wire rst_in,
  input wire sdf_start,
  input wire signed [BITS-1:0] x,
  input wire signed [BITS-1:0] y,
  input wire signed [BITS-1:0] z,
  input wire [BITS-1:0] timer,
  output logic sdf_done,
  output logic signed [BITS-1:0] sdf_out,
  output logic [7:0] sdf_red_out,
  output logic [7:0] sdf_green_out,
  output logic [7:0] sdf_blue_out
);
  typedef enum {IDLE=0, INIT_P=1, TRANS=2, DIV=3, INIT_Q=4, WAIT_Q=5, MULT=6, LEN_Q=7, SDF_BOX=8, DIV_PREP=9, FINAL_DIV=10, DONE=11, WAIT=12, WAIT2=13, WAIT3=14, CALC1=15, CALC2=16, CALC3=17, SQUARE=18, TRANS_PREP=19} sdf_state;
  typedef enum {X=0, Y=1, Z=2} square_state;
  square_state sq_state;
  sdf_state state;
  vec3 p;
  logic [BITS-1:0] scale, reciprocal_scale;
  vec3 half_vec;
  logic [BITS-1:0] p_scale;
  vec3 q;
  logic signed [BITS-1:0] sdBox;
  logic [BITS-1:0] length_q;

  logic [BITS-1:0] qx;
  logic [BITS-1:0] qy;
  logic [BITS-1:0] qz;
  logic [BITS-1:0] qx2;
  logic [BITS-1:0] qy2;
  logic [BITS-1:0] qz2;

  logic sqrt_start;
  logic sqrt_done;
  logic signed [BITS-1:0] sqrt_in;
  logic signed [BITS-1:0] sqrt_out;

  logic signed [BITS-1:0] max_y_z;
  logic signed [BITS-1:0] max_q_yz;
  logic signed [BITS-1:0] min_q_0;

  always_comb begin
    sdf_done = state == DONE;
  end

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
  
  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= IDLE;
      sqrt_start <= 0;
      sqrt_in <= 0;
      sq_state <= X;
      
      scale <= to_fixed(1) >> 2;
      reciprocal_scale <= to_fixed(1) << 2;
    end else begin
      case(state)
      IDLE: begin
        sdf_out <= 0;
        p_scale <= to_fixed(27);
        sdf_red_out <= 8'h00;
        sdf_green_out <= 8'h00;
        sdf_blue_out <= 8'h00;
        if(sdf_start) begin
          state <= INIT_P;
        end 
      end
      INIT_P: begin
        p.x <= mult(x, scale);
        p.y <= mult(y, scale);
        p.z <= mult(z, scale);
        state <= TRANS_PREP;
      end
      TRANS_PREP: begin
        p.x <= abs(p.x) - p_scale;
        p.y <= abs(p.y) - p_scale;
        p.z <= abs(p.z) - p_scale;
        state <= TRANS;
      end
      TRANS: begin
        p <= trans(p, p_scale);
        if(p_scale <= to_fixed(1.1))begin
          state <= WAIT3;
        end else begin
          state <= DIV;
        end
      end
      DIV: begin
        p_scale <= mult(p_scale, 32'b101010101010101); // divide by 3
        state <= TRANS_PREP;
      end
      WAIT3: begin
        p <= abs_vec3(p);
        state <= INIT_Q;
      end
      INIT_Q: begin
        q.x <= p.x - (1<<<15);
        q.y <= p.y - (1<<<15);
        q.z <= p.z - (1<<<15);
        state <= WAIT_Q;
      end
      WAIT_Q: begin
        qx <= signed_maximum(q.x,0);
        qy <= signed_maximum(q.y,0);
        qz <= signed_maximum(q.z,0);
        state <= SQUARE;
      end
      SQUARE: begin
        case(sq_state)
          X: begin
            qx2 <= mult(qx,qx);
            sq_state <= Y;
          end
          Y: begin
            qy2 <= mult(qy,qy);
            sq_state <= Z;
          end
          Z: begin
            sqrt_in <= (qx2 + qy2 + mult(qz,qz));
            state <= MULT;
            sq_state <= X;
          end
        endcase
      end
      MULT: begin
        sqrt_start <= 1;
        state <= LEN_Q;
      end
      LEN_Q: begin
        sqrt_start <= 0;
        if(~sqrt_start && sqrt_done) begin
          length_q <= sqrt_out;
          state <= CALC1;
        end
      end
      CALC1: begin
        max_y_z <= signed_maximum(q.y,q.z);
        state <= CALC2;
      end
      CALC2: begin
        max_q_yz <= signed_maximum(q.x, max_y_z);
        state <= CALC3;
      end
      CALC3: begin
        min_q_0 <= signed_minimum(max_q_yz,0);
        state <= SDF_BOX;
      end
      SDF_BOX: begin
        sdBox <= length_q + min_q_0;
        state <= FINAL_DIV;
      end
      FINAL_DIV: begin
        sdf_out <= mult(sdBox, reciprocal_scale);
        state <= DONE;
      end 
      DONE: begin
        state <= IDLE;
      end
      endcase
    end
  end
endmodule

module shapes_sdf (
  input wire clk_in,
  input wire rst_in,
  input wire sdf_start,
  input wire signed [31:0] x,
  input wire signed [31:0] y,
  input wire signed [31:0] z,
  input wire [31:0] timer,
  output logic sdf_done,
  output logic signed [31:0] sdf_out,
  output logic [7:0] sdf_red_out,
  output logic [7:0] sdf_green_out,
  output logic [7:0] sdf_blue_out
);
  typedef enum {IDLE=0, PROCESSING=1, DONE=2, SQUARE=3, INIT_Q=4, WAIT_Q=5, MULT=6, LEN_Q=7, SDF_BOX=8, CALC1=9, CALC2=10, CALC3=11, BOX=12, SQUARE2=13, CONE_SQRT=14} sdf_state;
  typedef enum {X=0, Y=1, Z=2} square_state;
  square_state sq_state;
  sdf_state state;

  logic signed [31:0] sphere_1_dist_squared;
  logic signed [31:0] sphere_2_dist_squared;
  logic signed [31:0] box_dist_squared;
  logic sphere_1_sqrt_done;
  logic sphere_2_sqrt_done;
  logic box_sqrt_done;
  logic signed [31:0] sphere_1_dist;
  logic signed [31:0] sphere_2_dist;
  logic signed [31:0] box_dist;
  logic sqrt_start;
  logic sqrt_box_start;
  logic sqrt_cone_start;
  logic cone_sqrt_done;
  logic signed [31:0] sqrt_cone_in;
  logic signed [31:0] cone_sqrt_out;


  logic signed [31:0] tmp_x_1;
  logic signed [31:0] tmp_y_1;
  logic signed [31:0] tmp_z_1;
  logic signed [31:0] tmp_x_2;
  logic signed [31:0] tmp_y_2;
  logic signed [31:0] tmp_z_2;
  logic signed [31:0] tmp_x_3;
  logic signed [31:0] tmp_y_3;
  logic signed [31:0] tmp_z_3;

  // 3 dimensional vector structure
  typedef struct packed {
      logic signed [31:0] x;
      logic signed [31:0] y;
      logic signed [31:0] z;
  } vec3;

  vec3 p;
  vec3 pc;
  vec3 q;

  logic signed [31:0] sdBox;

  logic [31:0] length_q;
  logic [31:0] qx;
  logic [31:0] qy;
  logic [31:0] qz;
  logic [31:0] qx2;
  logic [31:0] qy2;
  logic [31:0] qz2;

  logic [31:0] h;
  logic [31:0] cx;
  logic [31:0] cy;
  logic [31:0] dot;
  logic [31:0] qc;
  logic [31:0] sdf_cone;

  logic signed [31:0] max_y_z;
  logic signed [31:0] max_q_yz;
  logic signed [31:0] min_q_0;

  always_comb begin
    sdf_done = state == DONE;
  end

  sqrt #(
    .WIDTH(32),
    .FBITS(16)
  ) sqrt_inst (
    .clk(clk_in),
    .start(sqrt_start),
    .rad(sphere_1_dist_squared),
    .root(sphere_1_dist),
    .valid(sphere_1_sqrt_done)
  );

  // sqrt #(
  //   .WIDTH(32),
  //   .FBITS(16)
  // ) sqrt_inst2 (
  //   .clk(clk_in),
  //   .start(sqrt_start),
  //   .rad(sphere_2_dist_squared),
  //   .root(sphere_2_dist),
  //   .valid(sphere_2_sqrt_done)
  // );

  sqrt #(
    .WIDTH(32),
    .FBITS(16)
  ) sqrt_inst3 (
    .clk(clk_in),
    .start(sqrt_box_start),
    .rad(box_dist_squared),
    .root(box_dist),
    .valid(box_sqrt_done)
  );

  sqrt #(
    .WIDTH(32),
    .FBITS(16)
  ) sqrt_inst4 (
    .clk(clk_in),
    .start(sqrt_cone_start),
    .rad(sqrt_cone_in),
    .root(cone_sqrt_out),
    .valid(cone_sqrt_done)
  );

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      state <= IDLE;
      sqrt_start <= 0;
    end else begin
      if (state == IDLE) begin
        if(sdf_start) begin
          tmp_x_1 <= x + to_fixed(10);
          tmp_y_1 <= y - to_fixed(4);
          tmp_z_1 <= z - to_fixed(50);
          pc.x <= x;
          pc.y <= y + to_fixed(40);
          pc.z <= z - to_fixed(1);
          p.x <= x - to_fixed(2);
          p.y <= y;
          p.z <= z - to_fixed(85);
          cx <= to_fixed(40);
          cy <= to_fixed(40);
          h <= to_fixed(100);
          state <= SQUARE;
        end
      end else if(state == SQUARE) begin
        sqrt_start <= 1;
        sphere_1_dist_squared <= square_mag(tmp_x_1, tmp_y_1, tmp_z_1);
        // sphere_2_dist_squared <= square_mag(tmp_x_2, tmp_y_2, tmp_z_2);
        p <= abs_vec3(p);
        state <= INIT_Q;
      end else if (state == INIT_Q) begin
        q.x <= p.x - (1<<<16);
        q.y <= p.y - (1<<<16);
        q.z <= p.z - (1<<<16);
        state <= WAIT_Q;
      end else if (state == WAIT_Q) begin
        qx <= signed_maximum(q.x,0);
        qy <= signed_maximum(q.y,0);
        qz <= signed_maximum(q.z,0);
        sqrt_cone_in <= mult(pc.x, pc.x) + mult(pc.y, pc.y);
        state <= SQUARE2;
      end else if (state == SQUARE2) begin
        case(sq_state)
          X: begin
            qx2 <= mult(qx,qx);
            sq_state <= Y;
          end
          Y: begin
            qy2 <= mult(qy,qy);
            sq_state <= Z;
          end
          Z: begin
            box_dist_squared <= (qx2 + qy2 + mult(qz,qz));
            state <= MULT;
            sq_state <= X;
          end
        endcase
      end else if (state == MULT) begin
        sqrt_box_start <= 1;
        state <= LEN_Q;
      end else if (state == LEN_Q) begin
        sqrt_box_start <= 0;
        if(~sqrt_box_start && box_sqrt_done) begin
          length_q <= box_dist;
          sqrt_cone_start <= 1;
          state <= CONE_SQRT;
        end
      end else if (state == CONE_SQRT) begin
        sqrt_cone_start <= 0;
        if(~sqrt_cone_start && cone_sqrt_done) begin
          qc <= cone_sqrt_out;
          state <= CALC1;
        end
      end else if (state == CALC1) begin
        dot <= mult(cx, cy) + mult(qc, pc.y);
        max_y_z <= signed_maximum(q.y,q.z);
        state <= CALC2;
      end else if (state == CALC2) begin
        max_q_yz <= signed_maximum(q.x, max_y_z);
        sdf_cone <= signed_maximum(dot, -h-p.y);
        state <= CALC3;
      end else if (state == CALC3) begin
        min_q_0 <= signed_minimum(max_q_yz,0);
        state <= SDF_BOX;
      end else if (state == SDF_BOX) begin
        sdBox <= length_q + min_q_0;
        state <= PROCESSING;
      end else if(state == PROCESSING) begin
        if(sqrt_start) begin
          sqrt_start <= 0;
        end else if(sphere_1_sqrt_done && cone_sqrt_done && box_sqrt_done) begin
          sdf_out <= signed_minimum(signed_minimum(
             (sphere_1_dist - to_fixed(3)), 
             (sdf_cone - to_fixed(1))),
             (sdBox)
           );
          if(sphere_1_dist < sphere_2_dist && sphere_1_dist < sdBox - to_fixed(6)) begin
            sdf_red_out <= 8'hF0;
            sdf_green_out <= 8'h00;
            sdf_blue_out <= 8'h00;
          end else if (sphere_2_dist < sdBox - to_fixed(6)) begin
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