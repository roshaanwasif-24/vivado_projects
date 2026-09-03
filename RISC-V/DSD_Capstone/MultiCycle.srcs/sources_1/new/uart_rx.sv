`timescale 1ns / 1ps

module uart_rx #(parameter CLKS_PER_BIT = 868) (
    input  logic clk, rst_n, rx_in,
    output logic [7:0] rx_data,
    output logic rx_valid
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;
    logic [15:0] clk_count; logic [2:0] bit_idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; rx_valid <= 1'b0; rx_data <= 0; clk_count <= 0; bit_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_valid <= 1'b0;
                    if (rx_in == 1'b0) begin state <= START; clk_count <= 0; end
                end
                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2) - 1) begin 
                        if (rx_in == 1'b0) begin clk_count <= 0; state <= DATA; end 
                        else state <= IDLE; 
                    end else clk_count <= clk_count + 1;
                end
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0; rx_data[bit_idx] <= rx_in; 
                        if (bit_idx < 7) bit_idx <= bit_idx + 1;
                        else begin bit_idx <= 0; state <= STOP; end
                    end
                end
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) clk_count <= clk_count + 1;
                    else begin rx_valid <= 1'b1; clk_count <= 0; state <= IDLE; end
                end
            endcase
        end
    end
endmodule