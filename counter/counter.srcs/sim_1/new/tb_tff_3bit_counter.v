`timescale 1ns / 1ps

module tb_tff_3bit_counter;

    reg clk;
    reg reset;
    wire [2:0] q;

    tff_3bit_counter uut (
        .clk(clk),
        .reset(reset),
        .q(q)
    );

    always #5 clk = ~clk;  

    initial begin
       
        clk = 0;
        reset = 1;


        #10;
        reset = 0;

  
        #160;
        $stop;
    end

    // Monitor output
    initial begin
        $monitor("Time=%0t | Count = %b (%0d)", $time, q, q);
    end

endmodule
