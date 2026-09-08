`timescale 1ns/1ps

module tb_lfsr_prbs_rightshift;

    reg        clk = 0;
    reg        rst;
    reg        en;
    wire [7:0] lfsr_out;
    wire       prbs_bit;

    integer i, j;
    reg [7:0] seen [0:255];
    integer   dup_found;

    lfsr_prbs dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .lfsr_out(lfsr_out),
        .prbs_bit(prbs_bit)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        en  = 0;
        @(posedge clk);
        #1;
        rst = 0;

        if (lfsr_out !== 8'h01) begin
            $display("FAIL: seed after reset = %h, expected 01", lfsr_out);
            $finish;
        end

        en = 1;

        // Confirm the very first active-shift step matches the derived
        // right-shift transition from seed 8'h01 (feedback lfsr[0]=1
        // enters at lfsr[7], XORs into taps 5,4,3): expect 8'hB8
        @(posedge clk);
        #1;
        if (lfsr_out !== 8'hB8) begin
            $display("FAIL: first step from seed 01 = %h, expected b8", lfsr_out);
            $finish;
        end

        dup_found = 0;
        rst = 1; @(posedge clk); #1; rst = 0; // reload seed for full sweep
        for (i = 0; i < 255; i = i + 1) begin
            seen[i] = lfsr_out;
            if (lfsr_out == 8'h00) begin
                $display("FAIL: hit all-zero lockup state at cycle %0d", i);
                $finish;
            end
            @(posedge clk);
            #1;
        end

        if (lfsr_out !== 8'h01) begin
            $display("FAIL: state after 255 cycles = %h, expected 01 (wrap)", lfsr_out);
            $finish;
        end

        for (i = 0; i < 255; i = i + 1)
            for (j = i + 1; j < 255; j = j + 1)
                if (seen[i] == seen[j]) dup_found = dup_found + 1;

        if (dup_found != 0) begin
            $display("FAIL: found %0d duplicate states in the 255-cycle sequence", dup_found);
            $finish;
        end

        $display("PASS: true right-shift LFSR - 255 unique non-zero states, correct wrap");
        $display("First 8 states after reset: %h %h %h %h %h %h %h %h",
                  seen[0], seen[1], seen[2], seen[3], seen[4], seen[5], seen[6], seen[7]);
        $finish;
    end

endmodule
