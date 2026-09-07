module lfsr_prbs (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    
    output wire [7:0] lfsr_out,
    output wire       prbs_bit
);

    // Internal 8-bit register initialized to non-zero seed on reset
    reg [7:0] lfsr;

    // Polynomial: x^8 + x^6 + x^5 + x^4 + 1
    // Taps at indices 6, 5, 4 (and wrap-around 0)
    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 8'h01; // Non-zero seed value to avoid zero-lockup state
        end else if (en) begin
            lfsr[0] <= lfsr[7];
            lfsr[1] <= lfsr[0];
            lfsr[2] <= lfsr[1];
            lfsr[3] <= lfsr[2];
            lfsr[4] <= lfsr[3] ^ lfsr[7]; // Tap x^4
            lfsr[5] <= lfsr[4] ^ lfsr[7]; // Tap x^5
            lfsr[6] <= lfsr[5] ^ lfsr[7]; // Tap x^6
            lfsr[7] <= lfsr[6];
        end
    end

    // Outputs
    assign lfsr_out = lfsr;
    assign prbs_bit = lfsr[7];

endmodule
