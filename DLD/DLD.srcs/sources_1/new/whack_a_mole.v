`timescale 1ns / 1ps

module whack_a_mole(
    input wire clk,          // 100MHz system clock
    input wire reset_btn,    // BTNC push button for reset
    input wire [3:0] sw,     // 4 Switches for hitting moles
    output wire [3:0] led,   // 4 LEDs acting as moles
    output reg [7:0] an,     // 7-segment display anodes
    output reg [6:0] seg     // 7-segment display cathodes
);

    // ==========================================
    // 1. Clock Dividers (Timing Mechanisms)
    // ==========================================
    reg [26:0] counter_1hz;
    reg [16:0] counter_1khz;
    reg tick_1hz;
    reg tick_1khz;

    always @(posedge clk) begin
        // 1Hz Timer for mole movement (100,000,000 cycles)
        if (counter_1hz >= 99_999_999) begin
            counter_1hz <= 0;
            tick_1hz <= 1'b1;
        end else begin
            counter_1hz <= counter_1hz + 1;
            tick_1hz <= 1'b0;
        end

        // 1kHz Timer for 7-Segment Multiplexing (100,000 cycles)
        if (counter_1khz >= 99_999) begin
            counter_1khz <= 0;
            tick_1khz <= 1'b1;
        end else begin
            counter_1khz <= counter_1khz + 1;
            tick_1khz <= 1'b0;
        end
    end

    // ==========================================
    // 2. LFSR (Pseudo-Random Number Generator)
    // ==========================================
    reg [7:0] lfsr = 8'b10101010; // Non-zero initial seed
    always @(posedge clk) begin
        if (reset_btn)
            lfsr <= 8'b10101010;
        else
            // XNOR feedback polynomial for pseudo-randomness
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end

    // ==========================================
    // 3. Switch Edge Detection
    // ==========================================
    // To allow toggling a switch up OR down to count as a hit
    reg [3:0] sw_sync_1, sw_sync_2;
    wire [3:0] sw_toggle;

    always @(posedge clk) begin
        sw_sync_1 <= sw;
        sw_sync_2 <= sw_sync_1;
    end
    
    // XOR detects any change in state (flip up or flip down)
    assign sw_toggle = sw_sync_1 ^ sw_sync_2; 

    // ==========================================
    // 4. Game Logic & Scoring (BCD / Decimal)
    // ==========================================
    reg [1:0] active_mole;
    reg mole_is_up;
    
    // Separate registers for Ones and Tens (Binary-Coded Decimal)
    reg [3:0] score_ones;
    reg [3:0] score_tens;

    always @(posedge clk) begin
        if (reset_btn) begin
            score_ones <= 4'd0;
            score_tens <= 4'd0;
            mole_is_up <= 1'b0;
            active_mole <= 2'd0;
        end else begin
            // Every 1 second, pop a new mole up
            if (tick_1hz) begin
                active_mole <= lfsr[1:0]; // Pick a random mole (0 to 3)
                mole_is_up <= 1'b1;       // Show the mole
            end 
            // If the mole is up and the corresponding switch is toggled
            else if (mole_is_up && sw_toggle[active_mole]) begin
                mole_is_up <= 1'b0;       // Hide the mole immediately
                
                // --- BCD Increment Logic ---
                if (score_ones == 4'd9) begin
                    score_ones <= 4'd0;          // Reset ones to 0
                    if (score_tens == 4'd9)
                        score_tens <= 4'd0;      // Roll over from 99 back to 00
                    else
                        score_tens <= score_tens + 4'd1; // Increment tens
                end else begin
                    score_ones <= score_ones + 4'd1;     // Increment ones
                end
            end
        end
    end

    // Map the active mole to the physical LEDs
    assign led[0] = (mole_is_up && active_mole == 2'd0);
    assign led[1] = (mole_is_up && active_mole == 2'd1);
    assign led[2] = (mole_is_up && active_mole == 2'd2);
    assign led[3] = (mole_is_up && active_mole == 2'd3);

    // ==========================================
    // 5. 7-Segment Display Controller
    // ==========================================
    reg [3:0] hex_to_display;
    reg display_toggle; // To alternate between the two score digits

    always @(posedge clk) begin
        if (tick_1khz) begin
            display_toggle <= ~display_toggle;
            if (display_toggle) begin
                an <= 8'b11111110;          // Enable rightmost digit (AN0)
                hex_to_display <= score_ones; // Display ones column
            end else begin
                an <= 8'b11111101;          // Enable second digit (AN1)
                hex_to_display <= score_tens; // Display tens column
            end
        end
    end

    // Decoder for 0-9 (Active Low Cathodes)
    always @(*) begin
        case(hex_to_display)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // Off
        endcase
    end

endmodule