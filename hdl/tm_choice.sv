module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );
  logic [31:0] ones;
  always_comb begin
    ones = 0;
    for(int i=0; i<8; i=i+1) begin
      if(data_in[i] == 1) begin
        ones = ones + 1;
      end
    end

    if (ones > 4 || (ones == 4 && data_in[0] == 0)) begin
      qm_out[8] = 0;
      qm_out[0] = data_in[0];
      qm_out[1] = qm_out[0] ~^ data_in[1];
    qm_out[2] = qm_out[1] ~^ data_in[2];
    qm_out[3] = qm_out[2] ~^ data_in[3];
    qm_out[4] = qm_out[3] ~^ data_in[4];
    qm_out[5] = qm_out[4] ~^ data_in[5];
    qm_out[6] = qm_out[5] ~^ data_in[6];
    qm_out[7] = qm_out[6] ~^ data_in[7];
      
    end else begin
      qm_out[8] = 1;
        qm_out[0] = data_in[0];
        qm_out[1] = qm_out[0] ^ data_in[1];
        qm_out[2] = qm_out[1] ^ data_in[2];
        qm_out[3] = qm_out[2] ^ data_in[3];
        qm_out[4] = qm_out[3] ^ data_in[4];
        qm_out[5] = qm_out[4] ^ data_in[5];
        qm_out[6] = qm_out[5] ^ data_in[6];
        qm_out[7] = qm_out[6] ^ data_in[7];
    end
  end

endmodule //end tm_choice
