`timescale 1ns / 1ps

module adder_branch(
    input  logic [31:0] pc,
    input  logic [31:0] imm,
    output logic [31:0] target
);
    assign target = pc + imm;
endmodule