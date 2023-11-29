`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module cosine(input wire [8:0] value, input wire clk_in, input wire rst_in, output logic[31:0] amp_out, output logic ready);
  logic [8:0] value_to_use; 
  sine_lut cosine_of_value(
    .value(value_to_use),
    .clk_in(clk_in),
    .amp_out(amp_out)
  );
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      value_to_use <= 0;
    end else begin
      if (value < 90) begin 
        value_to_use <= value - 90 + 360;
      end else 
        value_to_use <= value - 90;
    end
  end
endmodule

module sine(input wire [8:0] value, input wire clk_in, input wire rst_in, output logic[31:0] amp_out, output logic ready);
  logic [8:0] value_to_use; 
  logic [8:0] amp_out_intermediate;
  logic negate;
  logic state;
  sine_lut sine_of_value(
    .value(value_to_use),
    .clk_in(clk_in),
    .amp_out(amp_out_intermediate)
  );
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      value_to_use <= 0;
      negate <= 0;
      state <= 0;
    end else begin
      case(state)
        1'b0: begin
          if (value < 180) begin 
            value_to_use <= value;
            negate <= 0;
          end else if (value < 270) begin 
            value_to_use <= (value - 180);
            negate <= 1;
          end else if (value < 360) begin 
            value_to_use <= (360 - value);
            negate <= 1;
          end 
          state <= 1;
        end 
        1'b1: begin 
          if (negate) begin 
            amp_out <= ~amp_out_intermediate;
          end else begin 
            amp_out <= amp_out_intermediate;
          end 
          ready <= 0;
          state <= 0;
        end
      endcase
    end
  end 
endmodule

//8bit sine lookup ( 0 -> 180), 32bit depth
module sine_lut(input wire [8:0] value, input wire clk_in, output logic[31:0] amp_out);
  always_ff @(posedge clk_in)begin
    case(value)
      8'd0: amp_out <= 32'b00000000000000000000000000000000;
      8'd1: amp_out <= 32'b00000000000000000000010001111000;
      8'd2: amp_out <= 32'b00000000000000000000100011101111;
      8'd3: amp_out <= 32'b00000000000000000000110101100110;
      8'd4: amp_out <= 32'b00000000000000000001000111011100;
      8'd5: amp_out <= 32'b00000000000000000001011001010000;
      8'd6: amp_out <= 32'b00000000000000000001101011000010;
      8'd7: amp_out <= 32'b00000000000000000001111100110011;
      8'd8: amp_out <= 32'b00000000000000000010001110100001;
      8'd9: amp_out <= 32'b00000000000000000010100000001100;
      8'd10: amp_out <= 32'b00000000000000000010110001110100;
      8'd11: amp_out <= 32'b00000000000000000011000011011001;
      8'd12: amp_out <= 32'b00000000000000000011010100111010;
      8'd13: amp_out <= 32'b00000000000000000011100110010110;
      8'd14: amp_out <= 32'b00000000000000000011110111101111;
      8'd15: amp_out <= 32'b00000000000000000100001001000010;
      8'd16: amp_out <= 32'b00000000000000000100011010010000;
      8'd17: amp_out <= 32'b00000000000000000100101011011001;
      8'd18: amp_out <= 32'b00000000000000000100111100011100;
      8'd19: amp_out <= 32'b00000000000000000101001101011000;
      8'd20: amp_out <= 32'b00000000000000000101011110001111;
      8'd21: amp_out <= 32'b00000000000000000101101110111110;
      8'd22: amp_out <= 32'b00000000000000000101111111100110;
      8'd23: amp_out <= 32'b00000000000000000110010000000111;
      8'd24: amp_out <= 32'b00000000000000000110100000100000;
      8'd25: amp_out <= 32'b00000000000000000110110000110001;
      8'd26: amp_out <= 32'b00000000000000000111000000111001;
      8'd27: amp_out <= 32'b00000000000000000111010000111001;
      8'd28: amp_out <= 32'b00000000000000000111100000101111;
      8'd29: amp_out <= 32'b00000000000000000111110000011100;
      8'd30: amp_out <= 32'b00000000000000001000000000000000;
      8'd31: amp_out <= 32'b00000000000000001000001111011010;
      8'd32: amp_out <= 32'b00000000000000001000011110101001;
      8'd33: amp_out <= 32'b00000000000000001000101101101101;
      8'd34: amp_out <= 32'b00000000000000001000111100100111;
      8'd35: amp_out <= 32'b00000000000000001001001011010110;
      8'd36: amp_out <= 32'b00000000000000001001011001111001;
      8'd37: amp_out <= 32'b00000000000000001001101000010001;
      8'd38: amp_out <= 32'b00000000000000001001110110011100;
      8'd39: amp_out <= 32'b00000000000000001010000100011011;
      8'd40: amp_out <= 32'b00000000000000001010010010001110;
      8'd41: amp_out <= 32'b00000000000000001010011111110011;
      8'd42: amp_out <= 32'b00000000000000001010101101001100;
      8'd43: amp_out <= 32'b00000000000000001010111010010111;
      8'd44: amp_out <= 32'b00000000000000001011000111010101;
      8'd45: amp_out <= 32'b00000000000000001011010100000101;
      8'd46: amp_out <= 32'b00000000000000001011100000100111;
      8'd47: amp_out <= 32'b00000000000000001011101100111010;
      8'd48: amp_out <= 32'b00000000000000001011111000111111;
      8'd49: amp_out <= 32'b00000000000000001100000100110101;
      8'd50: amp_out <= 32'b00000000000000001100010000011011;
      8'd51: amp_out <= 32'b00000000000000001100011011110011;
      8'd52: amp_out <= 32'b00000000000000001100100110111011;
      8'd53: amp_out <= 32'b00000000000000001100110001110011;
      8'd54: amp_out <= 32'b00000000000000001100111100011100;
      8'd55: amp_out <= 32'b00000000000000001101000110110100;
      8'd56: amp_out <= 32'b00000000000000001101010000111100;
      8'd57: amp_out <= 32'b00000000000000001101011010110011;
      8'd58: amp_out <= 32'b00000000000000001101100100011010;
      8'd59: amp_out <= 32'b00000000000000001101101101101111;
      8'd60: amp_out <= 32'b00000000000000001101110110110100;
      8'd61: amp_out <= 32'b00000000000000001101111111100111;
      8'd62: amp_out <= 32'b00000000000000001110001000001001;
      8'd63: amp_out <= 32'b00000000000000001110010000011001;
      8'd64: amp_out <= 32'b00000000000000001110011000010111;
      8'd65: amp_out <= 32'b00000000000000001110100000000100;
      8'd66: amp_out <= 32'b00000000000000001110100111011110;
      8'd67: amp_out <= 32'b00000000000000001110101110100110;
      8'd68: amp_out <= 32'b00000000000000001110110101011100;
      8'd69: amp_out <= 32'b00000000000000001110111011111111;
      8'd70: amp_out <= 32'b00000000000000001111000010010000;
      8'd71: amp_out <= 32'b00000000000000001111001000001110;
      8'd72: amp_out <= 32'b00000000000000001111001101111000;
      8'd73: amp_out <= 32'b00000000000000001111010011010000;
      8'd74: amp_out <= 32'b00000000000000001111011000010101;
      8'd75: amp_out <= 32'b00000000000000001111011101000111;
      8'd76: amp_out <= 32'b00000000000000001111100001100101;
      8'd77: amp_out <= 32'b00000000000000001111100101110000;
      8'd78: amp_out <= 32'b00000000000000001111101001101000;
      8'd79: amp_out <= 32'b00000000000000001111101101001100;
      8'd80: amp_out <= 32'b00000000000000001111110000011100;
      8'd81: amp_out <= 32'b00000000000000001111110011011001;
      8'd82: amp_out <= 32'b00000000000000001111110110000010;
      8'd83: amp_out <= 32'b00000000000000001111111000011000;
      8'd84: amp_out <= 32'b00000000000000001111111010011001;
      8'd85: amp_out <= 32'b00000000000000001111111100000111;
      8'd86: amp_out <= 32'b00000000000000001111111101100000;
      8'd87: amp_out <= 32'b00000000000000001111111110100110;
      8'd88: amp_out <= 32'b00000000000000001111111111011000;
      8'd89: amp_out <= 32'b00000000000000001111111111110110;
      8'd90: amp_out <= 32'b00000000000000010000000000000000;
      8'd91: amp_out <= 32'b00000000000000001111111111110110;
      8'd92: amp_out <= 32'b00000000000000001111111111011000;
      8'd93: amp_out <= 32'b00000000000000001111111110100110;
      8'd94: amp_out <= 32'b00000000000000001111111101100000;
      8'd95: amp_out <= 32'b00000000000000001111111100000111;
      8'd96: amp_out <= 32'b00000000000000001111111010011001;
      8'd97: amp_out <= 32'b00000000000000001111111000011000;
      8'd98: amp_out <= 32'b00000000000000001111110110000010;
      8'd99: amp_out <= 32'b00000000000000001111110011011001;
      8'd100: amp_out <= 32'b00000000000000001111110000011100;
      8'd101: amp_out <= 32'b00000000000000001111101101001100;
      8'd102: amp_out <= 32'b00000000000000001111101001101000;
      8'd103: amp_out <= 32'b00000000000000001111100101110000;
      8'd104: amp_out <= 32'b00000000000000001111100001100101;
      8'd105: amp_out <= 32'b00000000000000001111011101000111;
      8'd106: amp_out <= 32'b00000000000000001111011000010101;
      8'd107: amp_out <= 32'b00000000000000001111010011010000;
      8'd108: amp_out <= 32'b00000000000000001111001101111000;
      8'd109: amp_out <= 32'b00000000000000001111001000001110;
      8'd110: amp_out <= 32'b00000000000000001111000010010000;
      8'd111: amp_out <= 32'b00000000000000001110111011111111;
      8'd112: amp_out <= 32'b00000000000000001110110101011100;
      8'd113: amp_out <= 32'b00000000000000001110101110100110;
      8'd114: amp_out <= 32'b00000000000000001110100111011110;
      8'd115: amp_out <= 32'b00000000000000001110100000000100;
      8'd116: amp_out <= 32'b00000000000000001110011000010111;
      8'd117: amp_out <= 32'b00000000000000001110010000011001;
      8'd118: amp_out <= 32'b00000000000000001110001000001001;
      8'd119: amp_out <= 32'b00000000000000001101111111100111;
      8'd120: amp_out <= 32'b00000000000000001101110110110100;
      8'd121: amp_out <= 32'b00000000000000001101101101101111;
      8'd122: amp_out <= 32'b00000000000000001101100100011010;
      8'd123: amp_out <= 32'b00000000000000001101011010110011;
      8'd124: amp_out <= 32'b00000000000000001101010000111100;
      8'd125: amp_out <= 32'b00000000000000001101000110110100;
      8'd126: amp_out <= 32'b00000000000000001100111100011100;
      8'd127: amp_out <= 32'b00000000000000001100110001110011;
      8'd128: amp_out <= 32'b00000000000000001100100110111011;
      8'd129: amp_out <= 32'b00000000000000001100011011110011;
      8'd130: amp_out <= 32'b00000000000000001100010000011011;
      8'd131: amp_out <= 32'b00000000000000001100000100110101;
      8'd132: amp_out <= 32'b00000000000000001011111000111111;
      8'd133: amp_out <= 32'b00000000000000001011101100111010;
      8'd134: amp_out <= 32'b00000000000000001011100000100111;
      8'd135: amp_out <= 32'b00000000000000001011010100000101;
      8'd136: amp_out <= 32'b00000000000000001011000111010101;
      8'd137: amp_out <= 32'b00000000000000001010111010010111;
      8'd138: amp_out <= 32'b00000000000000001010101101001100;
      8'd139: amp_out <= 32'b00000000000000001010011111110011;
      8'd140: amp_out <= 32'b00000000000000001010010010001110;
      8'd141: amp_out <= 32'b00000000000000001010000100011011;
      8'd142: amp_out <= 32'b00000000000000001001110110011100;
      8'd143: amp_out <= 32'b00000000000000001001101000010001;
      8'd144: amp_out <= 32'b00000000000000001001011001111001;
      8'd145: amp_out <= 32'b00000000000000001001001011010110;
      8'd146: amp_out <= 32'b00000000000000001000111100100111;
      8'd147: amp_out <= 32'b00000000000000001000101101101101;
      8'd148: amp_out <= 32'b00000000000000001000011110101001;
      8'd149: amp_out <= 32'b00000000000000001000001111011010;
      8'd150: amp_out <= 32'b00000000000000001000000000000000;
      8'd151: amp_out <= 32'b00000000000000000111110000011100;
      8'd152: amp_out <= 32'b00000000000000000111100000101111;
      8'd153: amp_out <= 32'b00000000000000000111010000111001;
      8'd154: amp_out <= 32'b00000000000000000111000000111001;
      8'd155: amp_out <= 32'b00000000000000000110110000110001;
      8'd156: amp_out <= 32'b00000000000000000110100000100000;
      8'd157: amp_out <= 32'b00000000000000000110010000000111;
      8'd158: amp_out <= 32'b00000000000000000101111111100110;
      8'd159: amp_out <= 32'b00000000000000000101101110111110;
      8'd160: amp_out <= 32'b00000000000000000101011110001111;
      8'd161: amp_out <= 32'b00000000000000000101001101011000;
      8'd162: amp_out <= 32'b00000000000000000100111100011100;
      8'd163: amp_out <= 32'b00000000000000000100101011011001;
      8'd164: amp_out <= 32'b00000000000000000100011010010000;
      8'd165: amp_out <= 32'b00000000000000000100001001000010;
      8'd166: amp_out <= 32'b00000000000000000011110111101111;
      8'd167: amp_out <= 32'b00000000000000000011100110010110;
      8'd168: amp_out <= 32'b00000000000000000011010100111010;
      8'd169: amp_out <= 32'b00000000000000000011000011011001;
      8'd170: amp_out <= 32'b00000000000000000010110001110100;
      8'd171: amp_out <= 32'b00000000000000000010100000001100;
      8'd172: amp_out <= 32'b00000000000000000010001110100001;
      8'd173: amp_out <= 32'b00000000000000000001111100110011;
      8'd174: amp_out <= 32'b00000000000000000001101011000010;
      8'd175: amp_out <= 32'b00000000000000000001011001010000;
      8'd176: amp_out <= 32'b00000000000000000001000111011100;
      8'd177: amp_out <= 32'b00000000000000000000110101100110;
      8'd178: amp_out <= 32'b00000000000000000000100011101111;
      8'd179: amp_out <= 32'b00000000000000000000010001111000;
      8'd180: amp_out <= 32'b00000000000000000000000000000000;
      default: amp_out <= 32'b000;
    endcase
  end
endmodule

`default_nettype wire