module process_gyro(
    input wire clk_100mhz,
    input wire rst_in,
    input wire [0:15] gx, 
    input wire [0:15] gy,
    input wire [0:15] gz,
    input wire INT, 
    output reg [0:15] pitch,
    output reg [0:15] roll,
    output reg [0:15] yaw,
    output reg ready 
    );

logic pitch_ready, roll_ready, yaw_ready;
logic [0:15] dPitch, dRoll, dYaw;

div divide (
    .clk(clk_100mhz),
    .a(gx),
    .b(10),
    .q(dPitch),
    );

div divide (
    .clk(clk_100mhz),
    .a(gy),
    .b(10),
    .q(dRoll),
    );

div divide (
    .clk(clk_100mhz),
    .a(gz),
    .b(10),
    .q(dYaw),
    );

always_ff @(posedge clk_100mhz) begin 

end 
endmodule