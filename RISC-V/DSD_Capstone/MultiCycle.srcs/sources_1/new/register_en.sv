`timescale 1ns / 1ps

module register_en (
    input  logic        clk, reset, en,    
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk) begin
        if (reset) q <= 32'b0;
        else if (en) q <= d;
    end
endmodule