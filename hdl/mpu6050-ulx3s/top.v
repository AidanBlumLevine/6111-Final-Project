module top (
    input clk_25mhz,
    inout wire [27:0] gp,
    input [6:0] btn,
    output [7:0] led
);

wire clk_50mhz;

pll_25_50 pll(
    .clk_25mhz(clk_25mhz)
    , .clk_50mhz(clk_50mhz)
    );

top_50 top_50_inst(
    .clk_50mhz(clk_50mhz)
    , .gp(gp)
    , .btn(btn)
    , .led(led)
);

endmodule
