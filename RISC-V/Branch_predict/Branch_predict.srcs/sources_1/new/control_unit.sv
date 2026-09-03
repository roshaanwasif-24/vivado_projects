`timescale 1ns / 1ps

module control_unit(
    input  logic [6:0] op,
    output logic       RegWrite, MemtoReg, MemWrite, MemRead, Branch, ALUSrc,
    output logic [1:0] ALUOp
);
    always_comb begin
        {RegWrite, MemtoReg, MemWrite, MemRead, Branch, ALUSrc, ALUOp} = 8'b0;
        case(op)
            7'b0110011: begin RegWrite=1; ALUOp=2'b10; end // R-type
            7'b0010011: begin RegWrite=1; ALUSrc=1; ALUOp=2'b00; end // I-type
            7'b0000011: begin RegWrite=1; ALUSrc=1; MemtoReg=1; MemRead=1; ALUOp=2'b00; end // lw
            7'b0100011: begin ALUSrc=1; MemWrite=1; ALUOp=2'b00; end // sw
            7'b1100011: begin Branch=1; ALUOp=2'b01; end // beq
        endcase
    end
endmodule