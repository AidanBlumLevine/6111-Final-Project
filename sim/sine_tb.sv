`timescale 1ns / 1ps
`default_nettype none

module tb_trig;

  logic clk;
  logic rst;
  logic [8:0] angle;
  logic signed [31:0] cos_out, sin_out;
  logic start;

  cosine cos_inst(
    .value(angle),
    .clk_in(clk),
    .rst_in(rst),
    .amp_out(cos_out),
    .start(start)
  );

  sine sin_inst(
    .value(angle),
    .clk_in(clk),
    .rst_in(rst),
    .amp_out(sin_out),
    .start(start)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    angle = 0;
    start = 0;
    #10 rst = 0;

    repeat (360) begin
      #10 
      angle = angle + 1;
      start = 1;
      #10
      start = 0;
      while(!sin_inst.done) begin
        #1;
      end
      $display("Angle: %d, Cos: %d/16, Sin: %d/16", angle, $signed(cos_out>>>12), $signed(sin_out>>>12));

    end
    $stop;
  end

endmodule
