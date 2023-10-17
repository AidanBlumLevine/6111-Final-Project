module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20)
(
  input wire clk_pixel_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out,
  output logic hs_out,
  output logic ad_out,
  output logic nf_out,
  output logic [5:0] fc_out);
 
  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;
 
  logic last_reset;

  always_ff @(posedge clk_pixel_in) begin
    last_reset <= rst_in;
    if (rst_in || last_reset) begin
        hcount_out <= 0;
        vcount_out <= 0;
        hs_out <= 0;
        vs_out <= 0;
        ad_out <= ~rst_in;
        nf_out <= 0;
        fc_out <= 0;
    end else begin

    if (hcount_out == TOTAL_PIXELS-1) begin
      hcount_out <= 0;
      if (vcount_out == TOTAL_LINES-1) begin
                    vcount_out <= 0;
end else begin
        vcount_out <= vcount_out + 1;
      end
    if (vcount_out + 1 >= ACTIVE_LINES + V_FRONT_PORCH && vcount_out + 1 < ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH) begin
        vs_out <= 1;
        end else begin
        vs_out <= 0;
        end
    end else begin
      hcount_out <= hcount_out + 1;
    end

    if (hcount_out + 1 >= ACTIVE_H_PIXELS + H_FRONT_PORCH && hcount_out + 1 < ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH) begin
      hs_out <= 1;
    end else begin
      hs_out <= 0;
    end

    if (hcount_out + 1 < ACTIVE_H_PIXELS && vcount_out < ACTIVE_LINES || hcount_out + 1 == TOTAL_PIXELS && (vcount_out + 1 == TOTAL_LINES || vcount_out + 1 < ACTIVE_LINES)) begin
      ad_out <= 1;
    end else begin
      ad_out <= 0;
    end

    if (hcount_out + 1 == ACTIVE_H_PIXELS && vcount_out == ACTIVE_LINES) begin
      nf_out <= 1;
        if (fc_out == 59) begin
        fc_out <= 0;
        end else begin
        fc_out <= fc_out + 1;
        end
    end else begin
      nf_out <= 0;
    end
    end
  end
 
endmodule