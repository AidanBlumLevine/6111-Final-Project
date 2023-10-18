`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module renderer
#(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
)
(
  input wire clk_pixel_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
);
  logic [$clog2(HEIGHT)-1:0] curr_y;
  logic [$clog2(WIDTH)-1:0] curr_x;

  logic [5:0] counter;
  logic pixel_done;
  logic [7:0] pixel_red;
  logic [7:0] pixel_green;
  logic [7:0] pixel_blue;

  always_ff @(posedge clk_pixel_in) begin
    if(rst_in) begin
      curr_x <= 0;
      curr_y <= 0;
    end else begin
      if(pixel_done) begin
        curr_x <= curr_x == WIDTH-1 ? 0 : curr_x + 1;
        curr_y <= curr_x == WIDTH-1 ? (curr_y == HEIGHT-1 ? 0 : curr_y + 1) : curr_y;
      end
    end
  end

  raymarcher #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) rm (
    .clk_pixel_in(clk_pixel_in),
    .rst_in(rst_in),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .pixel_done(pixel_done),
    .red_out(pixel_red),
    .green_out(pixel_green),
    .blue_out(pixel_blue)
  );

  logic in_frame;
  assign in_frame = (hcount_in < WIDTH) && (vcount_in < HEIGHT);

  logic [10:0] img_addr;
  assign img_addr = hcount_in + WIDTH * vcount_in;

  logic [23:0] frame_buff_raw;
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(24),
    .RAM_DEPTH(WIDTH * HEIGHT))
    frame_buffer (
    .addra(curr_x + WIDTH * curr_y),
    .clka(clk_pixel_in),
    .wea(pixel_done),
    .dina({pixel_red, pixel_green, pixel_blue}),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(), 
    .addrb(img_addr),
    .dinb(16'b0),
    .clkb(clk_pixel_in),
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