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
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
);
  logic [$clog2(WIDTH)-1:0] curr_x;
  logic [$clog2(HEIGHT)-1:0] curr_y;
  logic [$clog2(WIDTH)-1:0] ray_out_x;
  logic [$clog2(HEIGHT)-1:0] ray_out_y;

  logic [5:0] counter;
  logic pixel_done;
  logic [7:0] pixel_red;
  logic [7:0] pixel_green;
  logic [7:0] pixel_blue;
  logic [31:0] timer;

  // logic clk_half;
  // always_ff @(posedge clk_in) begin
  //   clk_half <= ~clk_half;
  // end 

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      curr_x <= 0;
      curr_y <= 0;
      timer <= 0;
    end else if(pixel_done) begin
      // $display("pixel_done");
      // $display("frame_addr: %d", frame_addr);
      // $display("image_addr: %d", img_addr);
      // $display("curr_x: %d", curr_x);
      // $display("curr_y: %d", curr_y);
      curr_x <= curr_x == WIDTH-1 ? 0 : curr_x + 1;
      curr_y <= curr_x == WIDTH-1 ? (curr_y == HEIGHT-1 ? 0 : curr_y + 1) : curr_y;
      timer <= timer + ((curr_x == WIDTH-1 && curr_y == HEIGHT-1) ? 1 : 0); 
    end
  end


  raymarcher #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) rm (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .timer(timer),
    .pixel_done(pixel_done),
    .red_out(pixel_red),
    .green_out(pixel_green),
    .blue_out(pixel_blue),
    .out_x(ray_out_x),
    .out_y(ray_out_y)
  );

  logic in_frame;
  assign in_frame = (hcount_in < WIDTH) && (vcount_in < HEIGHT);

  logic [31:0] img_addr;
  assign img_addr = hcount_in + WIDTH * vcount_in;

  logic [31:0] frame_addr;
  assign frame_addr = ray_out_x + WIDTH * ray_out_y;

  logic [23:0] frame_buff_raw;
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(24),
    .RAM_DEPTH(WIDTH * HEIGHT)
  ) frame_buffer (
    .addra(frame_addr),
    .clka(clk_in),
    .wea(pixel_done),
    .dina({pixel_red, pixel_green, pixel_blue}),
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

  assign red_out = in_frame ? frame_buff_raw[23:16] : hcount_in[7:0];
  assign green_out = in_frame ? frame_buff_raw[15:8] : vcount_in[7:0];
  assign blue_out = in_frame ? frame_buff_raw[7:0] : (hcount_in[7:0] + vcount_in[7:0]);

endmodule

`default_nettype wire