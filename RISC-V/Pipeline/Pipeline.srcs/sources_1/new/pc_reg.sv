`timescale 1ns / 1ps

module pc_reg(
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic [31:0] pc_next,
    output logic [31:0] pc
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'b0;
        else if (en) pc <= pc_next;
    end
endmodule