`timescale 1ns / 1ps

module tb_morse_encoder;

    reg clk;
    reg rst; // Changed name to rst
    reg start_store_btn;
    reg play_seq_btn;
    reg mode_sw;
    reg [3:0] digit_in;

    wire led_out;
    wire [2:0] state_led;

    // Instantiate with fast timer for simulation
    morse_encoder #(
        .TIMER_LIMIT(10) 
    ) uut (
        .clk(clk), 
        .rst(rst), // Connect new Active High reset
        .start_store_btn(start_store_btn), 
        .play_seq_btn(play_seq_btn), 
        .mode_sw(mode_sw), 
        .digit_in(digit_in), 
        .led_out(led_out),
        .state_led(state_led)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize
        rst = 1; // Assert Reset (Active High)
        start_store_btn = 0;
        play_seq_btn = 0;
        mode_sw = 0;
        digit_in = 0;

        #100;
        rst = 0; // Release Reset (Active High)
        #50;

        // --- TEST PHASE 1 (Single Digit: 2) ---
        mode_sw = 0;
        digit_in = 4'b0010;
        #20;
        start_store_btn = 1;
        #20;
        start_store_btn = 0;
        #4000;

        // --- TEST PHASE 2 (Sequence: 1, 5) ---
        mode_sw = 1;
        
        // Store 1
        digit_in = 4'b0001;
        #10; start_store_btn = 1; #20; start_store_btn = 0; #50;
        
        // Store 5
        digit_in = 4'b0101;
        #10; start_store_btn = 1; #20; start_store_btn = 0; #50;

        // Play
        play_seq_btn = 1; #20; play_seq_btn = 0;
        
        #10000;
        $stop;
    end
endmodule