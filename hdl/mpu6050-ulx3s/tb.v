`timescale 10ns/1ps
module tb;

reg clock;
reg [6:0] btn;
wire [7:0] led;
wire [27:0] gp;

always
    #5 clock = ~clock;

initial
begin
`ifdef icarus
    $dumpfile("tb.vcd");
    $dumpvars;
`endif
    clock = 1'b0;
    btn = 7'b0000001;
`ifdef icarus
    #20000000 $finish;
`endif
end


top_50 top_instance(
    .clk_50mhz(clock)
    , .gp(gp)
    , .btn(btn)
    , .led(led)
);

endmodule
