`timescale 1ns / 1ps

module datapath (
    input logic clk,
    input logic reset,
    input logic PCWrite, AdrSrc, MemWrite, IRWrite, RegWrite,
    input logic [2:0] ImmSrc,    
    input logic [1:0] ALUSrcA, ALUSrcB, ResultSrc,
    input logic [3:0] ALUControl,
    
    output logic Zero,
    output logic [31:0] Instr,
    output logic [31:0] MemAddr, 
    output logic [31:0] MemWData, 
    input logic [31:0] MemRData  
);
    logic [31:0] PCNext, PC, OldPC, Adr, Data;
    logic [31:0] RD1, RD2, A, B, SrcA, SrcB, ALUResult, ALUOut, Result, ImmExt;

    assign MemAddr = Adr;
    assign MemWData = B;
    assign PCNext = Result;
    assign Adr = AdrSrc ? Result : PC;

    always_comb begin
        case (ALUSrcA)
            2'b00: SrcA = PC;
            2'b01: SrcA = OldPC;
            2'b10: SrcA = A;
            2'b11: SrcA = 32'b0; 
        endcase
    end

    always_comb begin
        case (ALUSrcB)
            2'b00: SrcB = B;
            2'b01: SrcB = 32'd4;
            2'b10: SrcB = ImmExt;
            default: SrcB = 32'bx;
        endcase
    end

    always_comb begin
        case (ResultSrc)
            2'b00: Result = ALUOut;
            2'b01: Result = Data;
            2'b10: Result = ALUResult;
            default: Result = 32'bx;
        endcase
    end

    register_en pcreg (.clk(clk), .reset(reset), .en(PCWrite), .d(PCNext), .q(PC));
    register_en instr_reg (.clk(clk), .reset(reset), .en(IRWrite), .d(MemRData), .q(Instr));
    
    register_en oldpc_reg (.clk(clk), .reset(reset), .en(IRWrite), .d(PC), .q(OldPC));
    
    register_simple data_reg (.clk(clk), .reset(reset), .d(MemRData), .q(Data));

    register_file rf (
        .clk(clk), .we3(RegWrite), 
        .a1(Instr[19:15]), .a2(Instr[24:20]), .a3(Instr[11:7]), 
        .wd3(Result), 
        .rd1(RD1), .rd2(RD2)
    );

    SignExt ext (.instr(Instr[31:7]), .immsrc(ImmSrc), .immext(ImmExt));
    
    register_simple reg_a (.clk(clk), .reset(reset), .d(RD1), .q(A));
    register_simple reg_b (.clk(clk), .reset(reset), .d(RD2), .q(B));
    
    ALU alu (
        .operand_a(SrcA), .operand_b(SrcB), 
        .alu_control(ALUControl), .alu_result(ALUResult), .zero_flag(Zero)
    );
    register_simple aluout_reg (.clk(clk), .reset(reset), .d(ALUResult), .q(ALUOut));

endmodule