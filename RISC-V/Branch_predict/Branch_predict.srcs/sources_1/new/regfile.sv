`timescale 1ns / 1ps

module regfile(
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:0];
    
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end

    // Write on falling edge for robust forwarding
    always_ff @(negedge clk) begin
        if (we3 && a3 != 0) rf[a3] <= wd3;
    end
    
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
endmodule