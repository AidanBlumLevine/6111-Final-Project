module mux8(
    input [2:0] in,
    output [7:0] out
);

assign out =
    in == 0 ? 1 : (
    in == 1 ? 2 : (
    in == 2 ? 4 : (
    in == 3 ? 8 : (
    in == 4 ? 16 : (
    in == 5 ? 32 : (
    in == 6 ? 64
            : 128))))));

endmodule
