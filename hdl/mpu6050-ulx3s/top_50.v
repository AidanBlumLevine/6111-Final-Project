module top_50 (
    input clk_50mhz,
    inout wire [27:0] gp,
    input [6:0] btn,
    output [7:0] led
);

wire signed [15:0] gx;
wire signed [15:0] gy;
wire signed [15:0] gz;
wire signed [15:0] ax;
wire signed [15:0] ay;
wire signed [15:0] az;

// trigger reset_n after 5 clocks
reg [5:0] reset_counter = 1'b0;
reg reset_n = 0;
always @(posedge clk_50mhz) begin
    if (reset_counter < 10) begin
        reset_counter <= reset_counter + 1;
        reset_n <= 1;
    end else if (reset_counter < 20) begin
        reset_counter <= reset_counter + 1;
        reset_n <= 0;
    end else begin
        reset_n <= 1;
    end
end

reg left_button;

debounce left_button_debouncer(
    .clock(clk_50mhz)
    , .btn(btn[0])
    , .debounced(left_button));

reg [2:0] axis = 0;

always @(posedge left_button) begin
    if (axis > 5) begin
        axis <= 0;
    end else begin
        axis <= axis + 1;
    end
end

mux8 mux(
    .in(axis == 0 ? ax[15:13] : (
        axis == 1 ? ay[15:13] : (
        axis == 2 ? az[15:13] : (
        axis == 3 ? gx[15:13] : (
        axis == 4 ? gy[15:13]
                  : gz[15:13]
    ))))),
    .out({led[3:0], led[7:4]})
);

mpu_rg mpu_rg_instance(
    .CLOCK_50(clk_50mhz)
    , .reset_n(reset_n)
    , .en(1'b1)
    , .I2C_SDAT(gp[12])
    , .I2C_SCLK(gp[13])
    , .gx(gx)
    , .gy(gy)
    , .gz(gz)
    , .ax(ax)
    , .ay(ay)
    , .az(az)
    );

endmodule
