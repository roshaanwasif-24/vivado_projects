`timescale 1ns / 1ps

module decode_cycle(
    input  logic        clk,
    input  logic [31:0] instr,
    input  logic [31:0] pc,
    input  logic [4:0]  wa3,
    input  logic [31:0] wd3,
    input  logic        we3,
    
    output logic [31:0] rd1, rd2, imm_ext,
    output logic [4:0]  rs1, rs2, rd,
    output logic        RegWrite, MemtoReg, MemWrite, MemRead, Branch, ALUSrc,
    output logic [1:0]  ALUOp
);

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    control_unit cu (
        .op(instr[6:0]), 
        .RegWrite(RegWrite), .MemtoReg(MemtoReg), .MemWrite(MemWrite), 
        .MemRead(MemRead), .Branch(Branch), .ALUSrc(ALUSrc), .ALUOp(ALUOp)
    );

    regfile rf (
        .clk(clk), .we3(we3), 
        .a1(rs1), .a2(rs2), .a3(wa3), .wd3(wd3), 
        .rd1(rd1), .rd2(rd2)
    );

    imm_gen ig (.instr(instr), .imm_ext(imm_ext));

endmodule