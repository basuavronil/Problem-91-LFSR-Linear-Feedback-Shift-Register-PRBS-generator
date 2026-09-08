`timescale 1ns / 1ps

module tb_lfsr_8bit;

    // Testbench Signals
    reg        clk;
    reg        rst_n;
    reg        load;
    reg  [7:0] seed;
    wire [7:0] lfsr;

    // Instantiate the Unit Under Test (UUT)
    lfsr_8bit uut (
        .clk  (clk),
        .rst_n(rst_n),
        .load (load),
        .seed (seed),
        .lfsr (lfsr)
    );

    // Clock Generation (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk   = 0;
        rst_n = 0;
        load  = 0;
        seed  = 8'h00;

        // Display output header
        $display("Time(ns) | rst_n | load | seed | lfsr (HEX) | lfsr (BIN)");
        $monitor("%8t |   %b   |  %b   |  %h  |     %h     | %b", 
                  $time, rst_n, load, seed, lfsr, lfsr);

        // 1. Apply Reset
        #15;
        rst_n = 1;

        // 2. Load a Custom Seed (e.g., 8'hA5)
        #10;
        load = 1;
        seed = 8'hA5;
        #10;
        load = 0;

        // 3. Run LFSR for several clock cycles to observe sequence
        #200;

        // 4. Test Reset Priority
        rst_n = 0;
        #10;
        rst_n = 1;

        #50;
        $finish;
    end

    // Optional: Generate a VCD waveform file for GTKWave or EDA Playground
    initial begin
        $dumpfile("lfsr_tb.vcd");
        $dumpvars(0, tb_lfsr_8bit);
    end

endmodule
