`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module renderer
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
)
(
  input wire clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [7:0] color_out,
  input wire start_next_frame,
  output logic frame_done,
  // ====================================
  input wire signed [BITS-1:0] camera_ori_x_raw,
  input wire signed [BITS-1:0] camera_ori_y_raw,
  input wire signed [BITS-1:0] camera_ori_z_raw,
  input wire signed [BITS-1:0] camera_u_x_raw,
  input wire signed [BITS-1:0] camera_u_y_raw,
  input wire signed [BITS-1:0] camera_u_z_raw,
  input wire signed [BITS-1:0] camera_v_x_raw,
  input wire signed [BITS-1:0] camera_v_y_raw,
  input wire signed [BITS-1:0] camera_v_z_raw,
  input wire signed [BITS-1:0] camera_forward_x_raw,
  input wire signed [BITS-1:0] camera_forward_y_raw,
  input wire signed [BITS-1:0] camera_forward_z_raw
);
  logic [$clog2(WIDTH)-1:0] curr_x;
  logic [$clog2(HEIGHT)-1:0] curr_y;

  logic [5:0] counter;
  logic [31:0] starting;
  logic [31:0] timer;

  logic signed [BITS-1:0] camera_ori_x;
  logic signed [BITS-1:0] camera_ori_y;
  logic signed [BITS-1:0] camera_ori_z;
  logic signed [BITS-1:0] camera_u_x;
  logic signed [BITS-1:0] camera_u_y;
  logic signed [BITS-1:0] camera_u_z;
  logic signed [BITS-1:0] camera_v_x;
  logic signed [BITS-1:0] camera_v_y;
  logic signed [BITS-1:0] camera_v_z;
  logic signed [BITS-1:0] camera_forward_x;
  logic signed [BITS-1:0] camera_forward_y;
  logic signed [BITS-1:0] camera_forward_z;

  logic pixel_done_1;
  logic [7:0] color_1;
  logic [$clog2(WIDTH)-1:0] ray_out_x_1;
  logic [$clog2(HEIGHT)-1:0] ray_out_y_1;

  // logic pixel_done_2;
  // logic [23:0] color_2;
  // logic [$clog2(WIDTH)-1:0] ray_out_x_2;
  // logic [$clog2(HEIGHT)-1:0] ray_out_y_2;

  // logic pixel_done_3;
  // logic [23:0] color_3;
  // logic [$clog2(WIDTH)-1:0] ray_out_x_3;
  // logic [$clog2(HEIGHT)-1:0] ray_out_y_3;

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      curr_x <= 0;
      curr_y <= 0;
      timer <= 0;
      starting <= 0;
      camera_ori_x <= camera_ori_x_raw;
      camera_ori_y <= camera_ori_y_raw;
      camera_ori_z <= camera_ori_z_raw;
      camera_u_x <= camera_u_x_raw;
      camera_u_y <= camera_u_y_raw;
      camera_u_z <= camera_u_z_raw;
      camera_v_x <= camera_v_x_raw;
      camera_v_y <= camera_v_y_raw;
      camera_v_z <= camera_v_z_raw;
      camera_forward_x <= camera_forward_x_raw;
      camera_forward_y <= camera_forward_y_raw;
      camera_forward_z <= camera_forward_z_raw;
      frame_done <= 1;
  end else if(pixel_done_1 && starting == 0) begin
      curr_x <= curr_x == WIDTH-1 ? 0 : curr_x + 1;
      curr_y <= curr_x == WIDTH-1 ? (curr_y == HEIGHT-1 ? 0 : curr_y + 1) : curr_y;
      if(curr_x == WIDTH-1 && curr_y == HEIGHT-1) begin
        timer <= timer + 1;
        // set camera vectors
        camera_ori_x <= camera_ori_x_raw;
        camera_ori_y <= camera_ori_y_raw;
        camera_ori_z <= camera_ori_z_raw;
        camera_u_x <= camera_u_x_raw;
        camera_u_y <= camera_u_y_raw;
        camera_u_z <= camera_u_z_raw;
        camera_v_x <= camera_v_x_raw;
        camera_v_y <= camera_v_y_raw;
        camera_v_z <= camera_v_z_raw;
        camera_forward_x <= camera_forward_x_raw;
        camera_forward_y <= camera_forward_y_raw;
        camera_forward_z <= camera_forward_z_raw;
      end
      starting <= 1;
    // end else if(pixel_done_2 && starting == 0) begin
    //   curr_x <= curr_x == WIDTH-1 ? 0 : curr_x + 1;
    //   curr_y <= curr_x == WIDTH-1 ? (curr_y == HEIGHT-1 ? 0 : curr_y + 1) : curr_y;
    //   timer <= timer + ((curr_x == WIDTH-1 && curr_y == HEIGHT-1) ? 1 : 0); 
    //   starting <= 2;
    // end else if(pixel_done_3) begin
    //   curr_x <= curr_x == WIDTH-1 ? 0 : curr_x + 1;
    //   curr_y <= curr_x == WIDTH-1 ? (curr_y == HEIGHT-1 ? 0 : curr_y + 1) : curr_y;
    //   timer <= timer + ((curr_x == WIDTH-1 && curr_y == HEIGHT-1) ? 1 : 0); 
    //   starting <= 3;
    end else begin
      starting <= 0;
    end
  end


  raymarcher #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) rm1 (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .start_in(starting == 1),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .timer(timer),
    .pixel_done(pixel_done_1),
    .color_out(color_1),
    .out_x(ray_out_x_1),
    .out_y(ray_out_y_1),
    // ====================================
    .camera_x(camera_ori_x),
    .camera_y(camera_ori_y),
    .camera_z(camera_ori_z),
    .camera_u_x(camera_u_x),
    .camera_u_y(camera_u_y),
    .camera_u_z(camera_u_z),
    .camera_v_x(camera_v_x),
    .camera_v_y(camera_v_y),
    .camera_v_z(camera_v_z),
    .camera_forward_x(camera_forward_x),
    .camera_forward_y(camera_forward_y),
    .camera_forward_z(camera_forward_z)
  );
  // raymarcher #(
  //   .WIDTH(WIDTH),
  //   .HEIGHT(HEIGHT)
  // ) rm2 (
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .start_in(starting == 2),
  //   .curr_x(curr_x),
  //   .curr_y(curr_y),
  //   .timer(timer),
  //   .pixel_done(pixel_done_2),
  //   .color_out(color_2),
  //   .out_x(ray_out_x_2),
  //   .out_y(ray_out_y_2),
  //   // ====================================
  //   .camera_x(to_fixed(0)),
  //   .camera_y(to_fixed(0)),
  //   .camera_z(to_fixed(150)),
  //   .camera_u_x(to_fixed(1)),
  //   .camera_u_y(to_fixed(0)),
  //   .camera_u_z(to_fixed(0)),
  //   .camera_v_x(to_fixed(0)),
  //   .camera_v_y(to_fixed(1)),
  //   .camera_v_z(to_fixed(0)),
  //   .camera_forward_x(to_fixed(0)),
  //   .camera_forward_y(to_fixed(0)),
  //   .camera_forward_z(to_fixed(-150))
  // );
  // raymarcher #(
  //   .WIDTH(WIDTH),
  //   .HEIGHT(HEIGHT)
  // ) rm3 (
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .start_in(starting == 3),
  //   .curr_x(curr_x),
  //   .curr_y(curr_y),
  //   .timer(timer),
  //   .pixel_done(pixel_done_3),
  //   .color_out(color_3),
  //   .out_x(ray_out_x_3),
  //   .out_y(ray_out_y_3),
  //   // ====================================
  //   .camera_x(to_fixed(0)),
  //   .camera_y(to_fixed(0)),
  //   .camera_z(to_fixed(150)),
  //   .camera_u_x(to_fixed(1)),
  //   .camera_u_y(to_fixed(0)),
  //   .camera_u_z(to_fixed(0)),
  //   .camera_v_x(to_fixed(0)),
  //   .camera_v_y(to_fixed(1)),
  //   .camera_v_z(to_fixed(0)),
  //   .camera_forward_x(to_fixed(0)),
  //   .camera_forward_y(to_fixed(0)),
  //   .camera_forward_z(to_fixed(-150))
  // );

  logic in_frame;
  assign in_frame = (hcount_in < WIDTH) && (vcount_in < HEIGHT);

  logic [31:0] img_addr;
  assign img_addr = hcount_in + WIDTH * vcount_in;

  logic frame_write;
  assign frame_write = pixel_done_1;// || pixel_done_2; // || pixel_done_3
  logic [31:0] frame_addr;
  assign frame_addr = pixel_done_1 ? ray_out_x_1 + WIDTH * ray_out_y_1 : 0;
                      //(pixel_done_2 ? ray_out_x_2 + WIDTH * ray_out_y_2 : 0);
                      // (pixel_done_3 ? ray_out_x_3 + WIDTH * ray_out_y_3 : 0));
  logic [7:0] frame_color;
  assign frame_color = pixel_done_1 ? color_1 : 0;
                       //(pixel_done_2 ? color_2 : 0); 
                      //  (pixel_done_3 ? color_3 : 0));

  logic [7:0] frame_buff_raw;
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(WIDTH * HEIGHT)
  ) frame_buffer (
    .addra(frame_addr),
    .clka(clk_in),
    .wea(frame_write),
    .dina(frame_color),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(), 
    .addrb(img_addr),
    .dinb(16'b0),
    .clkb(clk_in),
    .web(1'b0),
    .enb(in_frame),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(frame_buff_raw)
  );

  assign color_out = in_frame ? frame_buff_raw : 0;
endmodule

`default_nettype wire