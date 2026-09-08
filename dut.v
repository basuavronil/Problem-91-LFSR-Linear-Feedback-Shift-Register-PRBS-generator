module lfsr_8bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,
    input  wire [7:0] seed,
    output reg  [7:0] lfsr
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 8'h01; // Non-zero reset state
        end else if (load) begin
            lfsr <= seed;
        end else begin
            if (lfsr[7]) begin
                // Feedback = 1: Shift right and apply XOR taps (x^6, x^5, x^4)
                lfsr[7] <= lfsr[0];
                lfsr[6] <= lfsr[7];
                lfsr[5] <= lfsr[6] ^ 1'b1;
                lfsr[4] <= lfsr[5] ^ 1'b1;
                lfsr[3] <= lfsr[4] ^ 1'b1;
                lfsr[2] <= lfsr[3];
                lfsr[1] <= lfsr[2];
                lfsr[0] <= lfsr[1];
            end else begin
                // Feedback = 0: Pure right shift without XOR toggling
                lfsr[7] <= lfsr[0];
                lfsr[6] <= lfsr[7];
                lfsr[5] <= lfsr[6];
                lfsr[4] <= lfsr[5];
                lfsr[3] <= lfsr[4];
                lfsr[2] <= lfsr[3];
                lfsr[1] <= lfsr[2];
                lfsr[0] <= lfsr[1];
            end
        end
    end

endmodule
