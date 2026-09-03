`timescale 1ns / 1ps
module register_simple (
    input  logic        clk,
    input  logic        reset,  
    input  logic [31:0] d,      // Data in
    output logic [31:0] q       // Data out
);

    always_ff @(posedge clk) begin
        if (reset) begin
            q <= 32'b0;
        end else begin
            q <= d;
        end
    end

endmodule