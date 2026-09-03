`timescale 1ns / 1ps

module register_en (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,     // Enable signal (e.g., IRWrite, PCWrite)
    input  logic [31:0] d,
    output logic [31:0] q
);

    always_ff @(posedge clk) begin
        if (reset) begin
            q <= 32'b0;
        end else if (en) begin
            q <= d;
        end
    end

endmodule