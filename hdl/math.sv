`timescale 1ns / 1ps
`default_nettype none

//https://projectf.io/posts/square-root-in-verilog/
module sqrt #(
    parameter WIDTH=32,  // width of radicand
    parameter FBITS=8   // fractional bits (for fixed point)
    ) (
    input wire logic clk,
    input wire logic start,             // start signal
    output     logic busy,              // calculation in progress
    output     logic valid,             // root and rem are valid
    input wire logic [WIDTH-1:0] rad,   // radicand
    output     logic [WIDTH-1:0] root,  // root
    output     logic [WIDTH-1:0] rem    // remainder
    );

    logic [WIDTH-1:0] x, x_next;    // radicand copy
    logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)

    localparam ITER = (WIDTH+FBITS) >> 1;  // iterations are half radicand+fbits width
    logic [$clog2(ITER)-1:0] i;            // iteration counter

    always_comb begin
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    end

    always_ff @(posedge clk) begin
        if (start) begin
            busy <= 1;
            valid <= 0;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
        end else if (busy) begin
            if (i == ITER-1) begin  // we're done
                busy <= 0;
                valid <= 1;
                root <= q_next;
                rem <= ac_next[WIDTH+1:2];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
            end
        end
    end
endmodule

//https://projectf.io/posts/division-in-verilog/
module div #(
    parameter WIDTH=32,  // width of numbers in bits (integer and fractional)
    parameter FBITS=8   // fractional bits within WIDTH
    ) (
    input wire logic clk,    // clock
    input wire logic rst,    // reset
    input wire logic start,  // start calculation
    output     logic busy,   // calculation in progress
    output     logic done,   // calculation is complete (high for one tick)
    output     logic valid,  // result is valid
    output     logic dbz,    // divide by zero
    output     logic ovf,    // overflow
    input wire logic signed [WIDTH-1:0] a,   // dividend (numerator)
    input wire logic signed [WIDTH-1:0] b,   // divisor (denominator)
    output     logic signed [WIDTH-1:0] val  // result value: quotient
    );

    localparam WIDTHU = WIDTH - 1;                 // unsigned widths are 1 bit narrower
    localparam FBITSW = (FBITS == 0) ? 1 : FBITS;  // avoid negative vector width when FBITS=0
    localparam SMALLEST = {1'b1, {WIDTHU{1'b0}}};  // smallest negative number

    localparam ITER = WIDTHU + FBITS;  // iteration count: unsigned input width + fractional bits
    logic [$clog2(ITER):0] i;          // iteration counter (allow ITER+1 iterations for rounding)

    logic a_sig, b_sig, sig_diff;      // signs of inputs and whether different
    logic [WIDTHU-1:0] au, bu;         // absolute version of inputs (unsigned)
    logic [WIDTHU-1:0] quo, quo_next;  // intermediate quotients (unsigned)
    logic [WIDTHU:0] acc, acc_next;    // accumulator (unsigned but 1 bit wider)

    // input signs
    always_comb begin
        a_sig = a[WIDTH-1+:1];
        b_sig = b[WIDTH-1+:1];
    end

    // division algorithm iteration
    always_comb begin
        if (acc >= {1'b0, bu}) begin
            acc_next = acc - bu;
            {acc_next, quo_next} = {acc_next[WIDTHU-1:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // calculation state machine
    enum {IDLE, INIT, CALC, ROUND, SIGN} state;
    always_ff @(posedge clk) begin
        done <= 0;
        case (state)
            INIT: begin
                state <= CALC;
                ovf <= 0;
                i <= 0;
                {acc, quo} <= {{WIDTHU{1'b0}}, au, 1'b0};  // initialize calculation
            end
            CALC: begin
                if (i == WIDTHU-1 && quo_next[WIDTHU-1:WIDTHU-FBITSW] != 0) begin  // overflow
                    state <= IDLE;
                    busy <= 0;
                    done <= 1;
                    ovf <= 1;
                end else begin
                    if (i == ITER-1) state <= ROUND;  // calculation complete after next iteration
                    i <= i + 1;
                    acc <= acc_next;
                    quo <= quo_next;
                end
            end
            ROUND: begin  // Gaussian rounding
                state <= SIGN;
                if (quo_next[0] == 1'b1) begin  // next digit is 1, so consider rounding
                    // round up if quotient is odd or remainder is non-zero
                    if (quo[0] == 1'b1 || acc_next[WIDTHU:1] != 0) quo <= quo + 1;
                end
            end
            SIGN: begin  // adjust quotient sign if non-zero and input signs differ
                state <= IDLE;
                if (quo != 0) val <= (sig_diff) ? {1'b1, -quo} : {1'b0, quo};
                busy <= 0;
                done <= 1;
                valid <= 1;
            end
            default: begin  // IDLE
                if (start) begin
                    valid <= 0;
                    if (b == 0) begin  // divide by zero
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                        dbz <= 1;
                        ovf <= 0;
                    end else if (a == SMALLEST || b == SMALLEST) begin  // overflow
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                        dbz <= 0;
                        ovf <= 1;
                    end else begin
                        state <= INIT;
                        au <= (a_sig) ? -a[WIDTHU-1:0] : a[WIDTHU-1:0];  // register abs(a)
                        bu <= (b_sig) ? -b[WIDTHU-1:0] : b[WIDTHU-1:0];  // register abs(b)
                        sig_diff <= (a_sig ^ b_sig);  // register input sign difference
                        busy <= 1;
                        dbz <= 0;
                        ovf <= 0;
                    end
                end
            end
        endcase
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            valid <= 0;
            dbz <= 0;
            ovf <= 0;
            val <= 0;
        end
    end
endmodule

function logic signed [31:0] square_mag;
  input logic signed [31:0] x;
  input logic signed [31:0] y;
  input logic signed [31:0] z;
  logic signed [31:0] i;
  logic signed [31:0] j;
  logic signed [31:0] k;
  begin
    i = mult_24_8(x,x);
    j = mult_24_8(y,y);
    k = mult_24_8(z,z);
    square_mag = i + j + k;
  end
endfunction

function logic signed [31:0] mult_24_8;
  input logic signed [31:0] a;
  input logic signed [31:0] b;
  logic signed [63:0] intermediate;
  begin
    intermediate = a * b;
    mult_24_8 = {intermediate[63], intermediate[38:8]};
  end
endfunction

function logic signed [31:0] dec_to_24_8;
  input logic [23:0] a;
  begin
    dec_to_24_8 = {a, 8'h00};
  end
endfunction

function logic signed [31:0] div_shift_estimate;
  input logic signed [31:0] a;
  input logic signed [31:0] b;
  logic [31:0] b_abs;
  logic [31:0] a_abs;
  logic [4:0] b_log;
  logic sign;
  begin
    sign = a[31] ^ b[31];
    b_abs = b[31] ? ~b + 1 : b;
    a_abs = a[31] ? ~a + 1 : a;
    for(int i = 0; i < 31; i++) begin
      if(b_abs[i] == 1) begin
        b_log = i;
      end
    end

    if(b_log != 31) begin
      if(b_log > 8) begin
        div_shift_estimate = a_abs >> (b_log - 8);
      end else begin
        div_shift_estimate = a_abs << (8 - b_log);
      end
    end else begin
      $display("div 0");
      div_shift_estimate = 32'h7FFFFF_00;
    end

    if(sign) begin
      div_shift_estimate = ~div_shift_estimate + 1;
    end
  end
endfunction

function logic signed [31:0] abs_24_8;
  input logic signed [31:0] a;
  begin
    abs_24_8 = a[31] ? ~a + 1 : a;
  end
endfunction

`default_nettype wire