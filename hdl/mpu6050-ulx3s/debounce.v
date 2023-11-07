module debounce(
    input clock,
    input btn,
    output debounced
);

reg last = 0;
reg [24:0] cooldown = 0;

always @(posedge clock) begin
    if (cooldown == 0) begin
        if (last != btn) begin
            last <= btn;
            cooldown <= 4000000;
        end
    end else begin
        cooldown <= cooldown - 1;
    end
end

assign debounced = last;

endmodule
