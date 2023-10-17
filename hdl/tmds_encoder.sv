`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
  logic [5:0] num_ones;
  logic [5:0] num_zeros;
  always_comb begin
    num_ones = 0;
    for (int i = 0; i < 8; i++) begin
      if (q_m[i] == 1) begin
        num_ones = num_ones + 1;
      end
    end
    num_zeros = 8 - num_ones;
  end
 
  logic [4:0] cnt;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      cnt <= 0;
      tmds_out <= 10'b0000000000;
    end else if (ve_in == 0) begin
        cnt <= 0;
        case(control_in)
          2'b00: begin
            tmds_out <= 10'b1101010100;
          end
          2'b01: begin
            tmds_out <= 10'b0010101011;
          end
          2'b10: begin
            tmds_out <= 10'b0101010100;
          end
          2'b11: begin
            tmds_out <= 10'b1010101011;
          end
        endcase
    end else begin
      if (cnt == 0 || num_ones == num_zeros) begin
        tmds_out[9] <= ~q_m[8];
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];

        if (q_m[8] == 1) begin
            cnt <= cnt + num_ones - num_zeros;
        end else begin
            cnt <= cnt - num_ones + num_zeros;
        end
      end else begin
        if((~cnt[4] && cnt > 0 && num_ones > num_zeros) || (cnt[4] && num_ones < num_zeros)) begin
            tmds_out[9] <= 1;
            tmds_out[8] <= q_m[8];
            tmds_out[7:0] <= ~q_m[7:0];
            cnt <= cnt + 2*q_m[8] + num_zeros - num_ones;
        end else begin
            tmds_out[9] <= 0;
            tmds_out[8] <= q_m[8];
            tmds_out[7:0] <= q_m[7:0];
            cnt <= cnt - (2'd2)*(!q_m[8]) - num_zeros + num_ones;
        end
      end
    end
  end 
 
endmodule
 
`default_nettype wire