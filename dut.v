// =============================================================================
// lfsr_prbs.v
// 8-bit Maximal-Length Galois LFSR / PRBS Generator (TRUE RIGHT-SHIFT)
//
// Generator polynomial:  P(x) = x^8 + x^6 + x^5 + x^4 + 1
// Period:                2^8 - 1 = 255 non-zero states
// Reset seed:            8'h01 (synchronous, active-high)
// Shift direction:       RIGHT  (bits move from lfsr[7] toward lfsr[0];
//                         feedback exits at lfsr[0] and re-enters at lfsr[7])
// =============================================================================
//
// Block diagram:
//
//   LEFTMOST (MSB)                                            RIGHTMOST (LSB)
//   +---------+---------+---------+---------+---------+---------+---------+---------+
//   | lfsr[7] | lfsr[6] | lfsr[5] | lfsr[4] | lfsr[3] | lfsr[2] | lfsr[1] | lfsr[0] |
//   +---------+---------+---------+---------+---------+---------+---------+---------+
//        ^          |         |         |                                     |
//        |          |         |         |                                     |
//        |        [XOR]<----------------+                                     |
//        |          |       [XOR]<--------------------------------------------|
//        |          |         |       [XOR]<----------------------------------|
//        |          v         v         v                                     |
//        +----------+---------+---------+-------------------------------------+
//                             FEEDBACK SIGNAL = lfsr[0]  (exits at the LSB,
//                             re-enters at lfsr[7], XORed into taps 5, 4, 3
//                             as the shifted bits pass through them)
//
//   prbs_bit  <---- lfsr[0]  (serial output, taken from the feedback/LSB tap)
//
// -----------------------------------------------------------------------------
// Bit-level update equations (every posedge clk, when en=1 and rst=0):
//
//   lfsr[7]_next = lfsr[0]                        (feedback re-enters at MSB)
//   lfsr[6]_next = lfsr[7]
//   lfsr[5]_next = lfsr[6] ^ lfsr[0]     (tap x^6)
//   lfsr[4]_next = lfsr[5] ^ lfsr[0]     (tap x^5)
//   lfsr[3]_next = lfsr[4] ^ lfsr[0]     (tap x^4)
//   lfsr[2]_next = lfsr[3]
//   lfsr[1]_next = lfsr[2]
//   lfsr[0]_next = lfsr[1]
//
// Note: this replaces an earlier version of this file where feedback ran
// lfsr[7] -> lfsr[0]. Tracing a single bit's value through that version
// showed it walking 0 -> 1 -> 2 -> ... -> 7 -> 0, i.e. climbing from the
// LSB position toward the MSB position each cycle -- a LEFT shift, despite
// the "right shift" label. This version fixes that: feedback now exits at
// the LSB (lfsr[0]) and re-enters at the MSB (lfsr[7]), which is the
// correct entry/exit convention for a right-shifting register.
// =============================================================================

module lfsr_prbs (
    input  wire       clk,      // system clock
    input  wire       rst,      // synchronous active-high reset -> loads seed 8'h01
    input  wire       en,       // clock enable: 1 = advance, 0 = freeze
    output wire [7:0] lfsr_out, // parallel 8-bit pseudo-random byte output
    output wire       prbs_bit  // serial PRBS bitstream output (= lfsr[0])
);

    reg [7:0] lfsr_reg;

    always @(posedge clk) begin
        if (rst) begin
            // Zero-lockup-safe: always boot into a valid non-zero seed
            lfsr_reg <= 8'h01;
        end
        else if (en) begin
            lfsr_reg[7] <= lfsr_reg[0];
            lfsr_reg[6] <= lfsr_reg[7];
            lfsr_reg[5] <= lfsr_reg[6] ^ lfsr_reg[0];   // tap x^6
            lfsr_reg[4] <= lfsr_reg[5] ^ lfsr_reg[0];   // tap x^5
            lfsr_reg[3] <= lfsr_reg[4] ^ lfsr_reg[0];   // tap x^4
            lfsr_reg[2] <= lfsr_reg[3];
            lfsr_reg[1] <= lfsr_reg[2];
            lfsr_reg[0] <= lfsr_reg[1];
        end
        // if en=0 and rst=0: hold current state (freeze)
    end

    assign lfsr_out = lfsr_reg;
    assign prbs_bit = lfsr_reg[0];

endmodule
