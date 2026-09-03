`timescale 1ns / 1ps

module morse_encoder(
    input clk,                  // 100MHz System Clock
    input rst,                  // BTN0 - Active HIGH Reset (Fixed for Nexys A7)
    input start_store_btn,      // BTN1 - Start (Mode 0) or Store (Mode 1)
    input play_seq_btn,         // BTN2 - Play Sequence (Mode 1)
    input mode_sw,              // Switch to toggle modes (0 = Single, 1 = Multi)
    input [3:0] digit_in,       // 4 Switches for binary input
    output reg led_out,         // LED output for Morse signal
    output reg [2:0] state_led  // Debug LEDs to see current state
    );

    // ==============================================================================
    // PARAMETERS & TIMING
    // ==============================================================================
    // 0.5s = 50,000,000 cycles at 100MHz.
    parameter TIMER_LIMIT = 50000000; 
    
    // Timing Multipliers (based on 0.5s ticks)
    parameter TIME_DOT        = 2; // 1.0s
    parameter TIME_DASH       = 6; // 3.0s
    parameter TIME_GAP        = 1; // 0.5s
    parameter TIME_DIGIT_GAP  = 4; // 2.0s

    // FSM STATES
    parameter S_IDLE        = 0;
    parameter S_LOAD_DIGIT  = 1;
    parameter S_DECODE      = 2;
    parameter S_LED_ON      = 3;
    parameter S_LED_OFF     = 4;
    parameter S_NEXT_SYMBOL = 5;
    parameter S_INTER_DIGIT = 6;

    // ==============================================================================
    // INTERNAL SIGNALS
    // ==============================================================================
    reg [3:0] current_state;
    
    // Timer Signals
    integer clk_counter = 0;
    reg tick_05s;           
    integer duration_counter; 

    // Button Edge Detection
    reg btn1_prev, btn2_prev;
    wire btn1_pressed, btn2_pressed;

    // FIFO / Memory for Phase 2 (Max 6 digits)
    reg [3:0] digit_memory [0:5];
    reg [2:0] write_ptr;
    reg [2:0] read_ptr;
    reg [2:0] digits_to_play;
    reg [3:0] active_digit; 

    // Morse Encoding Logic
    reg [4:0] morse_pattern; 
    reg [2:0] symbol_index;  
    reg is_dash;             

    // ==============================================================================
    // 1. CLOCK DIVIDER (0.5s TICK GENERATOR)
    // ==============================================================================
    // Uses Active High Reset (rst)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            tick_05s <= 0;
        end else begin
            if (clk_counter >= TIMER_LIMIT - 1) begin
                clk_counter <= 0;
                tick_05s <= 1;
            end else begin
                clk_counter <= clk_counter + 1;
                tick_05s <= 0;
            end
        end
    end

    // ==============================================================================
    // 2. BUTTON EDGE DETECTION
    // ==============================================================================
    always @(posedge clk) begin
        btn1_prev <= start_store_btn;
        btn2_prev <= play_seq_btn;
    end
    assign btn1_pressed = (start_store_btn && !btn1_prev); 
    assign btn2_pressed = (play_seq_btn && !btn2_prev);    

    // ==============================================================================
    // 3. MORSE CODE LOOKUP TABLE
    // ==============================================================================
    function [4:0] get_morse;
        input [3:0] num;
        begin
            case(num)
                4'd0: get_morse = 5'b11111; // -----
                4'd1: get_morse = 5'b01111; // .----
                4'd2: get_morse = 5'b00111; // ..---
                4'd3: get_morse = 5'b00011; // ...--
                4'd4: get_morse = 5'b00001; // ....-
                4'd5: get_morse = 5'b00000; // .....
                4'd6: get_morse = 5'b10000; // -....
                4'd7: get_morse = 5'b11000; // --...
                4'd8: get_morse = 5'b11100; // ---..
                4'd9: get_morse = 5'b11110; // ----.
                default: get_morse = 5'b00000;
            endcase
        end
    endfunction

    // ==============================================================================
    // 4. MAIN FINITE STATE MACHINE (FSM)
    // ==============================================================================
    // Uses Active High Reset (rst)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_IDLE;
            led_out <= 0;
            write_ptr <= 0;
            read_ptr <= 0;
            digits_to_play <= 0;
            symbol_index <= 0;
            duration_counter <= 0;
            state_led <= 0;
            active_digit <= 0;
            morse_pattern <= 0;
        end else begin
            
            state_led <= current_state[2:0]; 

            case (current_state)

                // --------------------------------------------------------
                // STATE: IDLE
                // --------------------------------------------------------
                S_IDLE: begin
                    led_out <= 0;
                    
                    if (mode_sw == 0) begin // Phase 1
                        write_ptr <= 0; 
                        if (btn1_pressed) begin
                            active_digit <= digit_in; 
                            current_state <= S_DECODE; 
                        end
                    end 
                    else begin // Phase 2
                        if (btn1_pressed) begin
                            if (write_ptr < 6) begin
                                digit_memory[write_ptr] <= digit_in;
                                write_ptr <= write_ptr + 1;
                            end
                        end
                        else if (btn2_pressed && write_ptr > 0) begin
                            read_ptr <= 0;
                            digits_to_play <= write_ptr;
                            current_state <= S_LOAD_DIGIT;
                        end
                    end
                end

                // --------------------------------------------------------
                // STATE: LOAD_DIGIT 
                // --------------------------------------------------------
                S_LOAD_DIGIT: begin
                    if (read_ptr < digits_to_play) begin
                        active_digit <= digit_memory[read_ptr];
                        read_ptr <= read_ptr + 1;
                        current_state <= S_DECODE;
                    end else begin
                        write_ptr <= 0;
                        current_state <= S_IDLE;
                    end
                end

                // --------------------------------------------------------
                // STATE: DECODE 
                // --------------------------------------------------------
                S_DECODE: begin
                    morse_pattern <= get_morse(active_digit);
                    symbol_index <= 4; 
                    current_state <= S_LED_ON;
                    
                    // Look at MSB to decide initial timing
                    if (get_morse(active_digit) & (1 << 4))
                         duration_counter <= TIME_DASH;
                    else
                         duration_counter <= TIME_DOT;
                end

                // --------------------------------------------------------
                // STATE: LED_ON
                // --------------------------------------------------------
                S_LED_ON: begin
                    led_out <= 1;
                    if (tick_05s) begin
                        if (duration_counter > 1) begin
                            duration_counter <= duration_counter - 1;
                        end else begin
                            led_out <= 0;
                            current_state <= S_LED_OFF;
                            duration_counter <= TIME_GAP; 
                        end
                    end
                end

                // --------------------------------------------------------
                // STATE: LED_OFF (Inter-symbol gap)
                // --------------------------------------------------------
                S_LED_OFF: begin
                    led_out <= 0;
                    if (tick_05s) begin
                        if (duration_counter > 1) begin
                            duration_counter <= duration_counter - 1;
                        end else begin
                            current_state <= S_NEXT_SYMBOL;
                        end
                    end
                end

                // --------------------------------------------------------
                // STATE: NEXT_SYMBOL 
                // --------------------------------------------------------
                S_NEXT_SYMBOL: begin
                    if (symbol_index > 0) begin
                        symbol_index <= symbol_index - 1;
                        
                        if (morse_pattern[symbol_index - 1] == 1)
                            duration_counter <= TIME_DASH;
                        else
                            duration_counter <= TIME_DOT;
                            
                        current_state <= S_LED_ON;
                    end else begin
                        // Check if we need to play more digits (Phase 2)
                        if (mode_sw == 1 && read_ptr < digits_to_play) begin
                             duration_counter <= TIME_DIGIT_GAP;
                             current_state <= S_INTER_DIGIT;
                        end else begin
                             current_state <= S_IDLE;
                        end
                    end
                end

                // --------------------------------------------------------
                // STATE: INTER_DIGIT (2s gap)
                // --------------------------------------------------------
                S_INTER_DIGIT: begin
                    led_out <= 0;
                    if (tick_05s) begin
                        if (duration_counter > 1) begin
                            duration_counter <= duration_counter - 1;
                        end else begin
                            current_state <= S_LOAD_DIGIT;
                        end
                    end
                end
                
                default: current_state <= S_IDLE;
            endcase
        end
    end

endmodule