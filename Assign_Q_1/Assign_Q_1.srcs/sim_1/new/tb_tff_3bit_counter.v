`timescale 1ns / 1ps

module tb_tff_3bit_counter;

    reg clk;
    reg reset;
    wire [2:0] q;

    // Instantiate the counter
    tff_3bit_counter uut (
        .clk(clk),
        .reset(reset),
        .q(q)
    );

    // Generate clock
    always #5 clk = ~clk;  // 10ns period -> 100 MHz

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Apply reset
        #10;
        reset = 0;

        // Run counter for several cycles
        #160;
        $stop;
    end

    // Monitor output
    initial begin
        $monitor("Time=%0t | Count = %b (%0d)", $time, q, q);
    end

endmodule
