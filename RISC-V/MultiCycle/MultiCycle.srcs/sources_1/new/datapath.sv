`timescale 1ns / 1ps

module datapath (
    input  logic        clk,
    input  logic        reset,
    
    // Control Signals
    input  logic        PCWrite,
    input  logic        AdrSrc,
    input  logic        MemWrite,
    input  logic        IRWrite,
    input  logic        RegWrite,
    input  logic [1:0]  ImmSrc,
    input  logic [1:0]  ALUSrcA,
    input  logic [1:0]  ALUSrcB,
    input  logic [3:0]  ALUControl, // 4-bit to match ALU module
    input  logic [1:0]  ResultSrc,
    
    // Status Signals
    output logic        Zero,
    output logic [31:0] Instr
);

    // Internal Wires
    logic [31:0] PCNext, PC, OldPC, Adr, ReadData, Data;
    logic [31:0] RD1, RD2, A, B, SrcA, SrcB, ALUResult, ALUOut, Result, ImmExt;

    
    assign PCNext = Result;
    assign Adr = AdrSrc ? Result : PC;

    always_comb begin
        case (ALUSrcA)
            2'b00: SrcA = PC;
            2'b01: SrcA = OldPC;
            2'b10: SrcA = A;
            default: SrcA = 32'bx;
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

    // --- Sub-Module Instantiations ---

    register_en pcreg (
        .clk(clk), .reset(reset), .en(PCWrite), .d(PCNext), .q(PC)
    );

    memorys mem (
        .clk(clk), .we(MemWrite), .addr(Adr[7:0]), .wd(B), .rd(ReadData)
    );

    register_en instr_reg (
        .clk(clk), .reset(reset), .en(IRWrite), .d(ReadData), .q(Instr)
    );

    register_simple oldpc_reg (
        .clk(clk), .reset(reset), .d(PC), .q(OldPC)
    );

    register_simple data_reg (
        .clk(clk), .reset(reset), .d(ReadData), .q(Data)
    );

    register_file rf (
        .clk(clk), .we3(RegWrite), 
        .a1(Instr[19:15]), .a2(Instr[24:20]), .a3(Instr[11:7]), 
        .wd3(Result), 
        .rd1(RD1), .rd2(RD2)
    );

    SignExt ext (
        .instr(Instr[31:7]), .immsrc(ImmSrc), .immext(ImmExt)
    );

    register_simple reg_a (
        .clk(clk), .reset(reset), .d(RD1), .q(A)
    );

    register_simple reg_b (
        .clk(clk), .reset(reset), .d(RD2), .q(B)
    );

    ALU alu (
        .operand_a(SrcA), 
        .operand_b(SrcB), 
        .alu_control(ALUControl), 
        .alu_result(ALUResult), 
        .zero_flag(Zero)
    );

    register_simple aluout_reg (
        .clk(clk), .reset(reset), .d(ALUResult), .q(ALUOut)
    );

endmodule
