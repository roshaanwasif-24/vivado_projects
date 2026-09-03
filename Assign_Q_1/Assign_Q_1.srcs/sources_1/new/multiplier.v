`timescale 1ns / 1ps

module booth_multiplier_16bit (
    // System Inputs
    input clk_50mhz,  // 50 MHz clock (20ns period)
    input reset,

    // Control Inputs
    input start,      // Start multiplication
    
    // Data Inputs
    input signed [15:0] Multiplicand_in, // M
    input signed [15:0] Multiplier_in,   // Q
    
    // Outputs
    output reg done,                     // Signals completion
    output reg signed [31:0] Product     // Final 32-bit result
);

    // --- Parameters ---
    localparam DATA_WIDTH = 16;
    localparam CLK_DIV_FACTOR = 50; // 50 MHz / 50 = 1 MHz

    // --- Internal Registers ---
    reg signed [15:0] M; // Multiplicand (N bits)
    
    // A is (N+1) bits to handle overflow
    reg signed [16:0] A; // Accumulator (N+1 bits)
    
    reg signed [15:0] Q; // Multiplier (N bits)
    reg Q_minus_1;
    reg [4:0] count;     // Iteration counter (0 to 16)
    
    // --- State Machine ---
    reg [1:0] state;
    localparam S_IDLE = 0, S_MULTIPLY = 1, S_DONE = 2;
    
    // --- 1 MHz Clock Enable Generator ---
    reg [$clog2(CLK_DIV_FACTOR)-1:0] clk_div_counter;
    wire clk_enable;

    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            clk_div_counter <= 0;
        end else begin
            if (clk_div_counter == CLK_DIV_FACTOR - 1)
                clk_div_counter <= 0;
            else
                clk_div_counter <= clk_div_counter + 1;
        end
    end

    assign clk_enable = (clk_div_counter == CLK_DIV_FACTOR - 1);

    // --- Combinational Logic for Add/Subtract (N+1 bits) ---
    
    // Sign-extend M to (N+1) bits for addition/subtraction
    wire signed [16:0] M_ext;
    assign M_ext = {M[15], M}; // e.g., 16'h8000 -> 17'h1_8000

    // Adder/Subtractor is (N+1) bits
    wire signed [16:0] A_temp; 
    assign A_temp = ({Q[0], Q_minus_1} == 2'b01) ? A + M_ext :
                    ({Q[0], Q_minus_1} == 2'b10) ? A - M_ext :
                    A; // Default: no operation

    // --- Main Control and Datapath Logic ---
    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            // Reset all registers
            state <= S_IDLE;
            M <= 0;
            A <= 0;
            Q <= 0;
            Q_minus_1 <= 0;
            count <= 0;
            done <= 0;
            Product <= 0;
        end else if (clk_enable) begin 
            // This entire block runs at 1 MHz
            
            case (state)
                S_IDLE: begin
                    done <= 0;
                    Product <= 0; // Clear product on new start
                    if (start) begin
                        // Load inputs and initialize
                        M <= Multiplicand_in;
                        Q <= Multiplier_in;
                        A <= 17'b0; // A is (N+1) bits
                        Q_minus_1 <= 1'b0;
                        count <= DATA_WIDTH; // Start 16 iterations
                        state <= S_MULTIPLY;
                    end
                end
                
                S_MULTIPLY: begin
                    if (count > 0) begin
                        count <= count - 1; // Decrement counter
                        
                        // Perform (N+1) bit Arithmetic Right Shift
                        A <= {A_temp[16], A_temp[16:1]}; // ARS on 17-bit A_temp
                        Q <= {A_temp[0], Q[15:1]};       // Q gets LSB of 17-bit A_temp
                        Q_minus_1 <= Q[0];               // Q_m1 gets the *old* Q[0]
                        
                    end else begin
                        // 16 cycles are done
                        state <= S_DONE;
                    end
                end
                
                S_DONE: begin
                    // Final product is {A[15:0], Q}
                    Product <= {A[15:0], Q}; // Truncate A back to 16 bits
                    done <= 1;
                    state <= S_IDLE;
                end
                
                default: begin
                    state <= S_IDLE;
                end
                
            endcase
        end
    end
endmodule