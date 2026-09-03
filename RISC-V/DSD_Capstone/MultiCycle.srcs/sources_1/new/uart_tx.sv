`timescale 1ns / 1ps

module uart_tx #(parameter CLKS_PER_BIT = 868) (
    input  logic clk, rst_n, tx_start,
    input  logic [7:0] tx_data,
    output logic tx_busy, tx_out
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;
    logic [15:0] clk_count; logic [2:0] bit_idx; logic [7:0] tx_shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; tx_out <= 1'b1; tx_busy <= 1'b0;
            clk_count <= 0; bit_idx <= 0; tx_shift_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out <= 1'b1; tx_busy <= 1'b0;
                    if (tx_start) begin
                        tx_shift_reg <= tx_data; tx_busy <= 1'b1; state <= START;
                    end
                end
                START: begin
                    tx_out <= 1'b0; 
                    if (clk_count < CLKS_PER_BIT - 1) clk_count <= clk_count + 1;
                    else begin clk_count <= 0; state <= DATA; end
                end
                DATA: begin
                    tx_out <= tx_shift_reg[bit_idx];
                    if (clk_count < CLKS_PER_BIT - 1) clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        if (bit_idx < 7) bit_idx <= bit_idx + 1;
                        else begin bit_idx <= 0; state <= STOP; end
                    end
                end
                STOP: begin
                    tx_out <= 1'b1; 
                    if (clk_count < CLKS_PER_BIT - 1) clk_count <= clk_count + 1;
                    else begin clk_count <= 0; state <= IDLE; end
                end
            endcase
        end
    end
endmodule