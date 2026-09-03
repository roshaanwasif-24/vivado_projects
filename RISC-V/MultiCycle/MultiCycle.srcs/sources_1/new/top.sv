`timescale 1ns / 1ps

module top (
    input  logic        clk,
    input  logic        reset
);

    // Internal wires connecting Controller and Datapath
    logic        PCWrite, AdrSrc, MemWrite, IRWrite, RegWrite, Zero;
    logic [1:0]  ResultSrc, ALUSrcA, ALUSrcB, ImmSrc;
    logic [3:0]  ALUControl;
    logic [31:0] Instr;

    // Instantiate Controller
    controller ctrl (
        .clk(clk), .reset(reset),
        .op(Instr[6:0]), .funct3(Instr[14:12]), .funct7b5(Instr[30]), 
        .Zero(Zero),
        .PCWrite(PCWrite), .AdrSrc(AdrSrc), .MemWrite(MemWrite), 
        .IRWrite(IRWrite), .RegWrite(RegWrite),
        .ImmSrc(ImmSrc), .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), 
        .ALUControl(ALUControl), .ResultSrc(ResultSrc)
    );

    // Instantiate Datapath
    datapath dp (
        .clk(clk), .reset(reset),
        .PCWrite(PCWrite), .AdrSrc(AdrSrc), .MemWrite(MemWrite), 
        .IRWrite(IRWrite), .RegWrite(RegWrite),
        .ImmSrc(ImmSrc), .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), 
        .ALUControl(ALUControl), .ResultSrc(ResultSrc),
        .Zero(Zero), .Instr(Instr)
    );

endmodule