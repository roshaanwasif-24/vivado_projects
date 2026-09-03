`timescale 1ns / 1ps

module control_unit(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    output logic       reg_write,
    output logic [2:0] imm_src,
    output logic       alu_src,
    output logic [2:0] alu_ctrl,
    output logic       branch,
    output logic       jump,
    output logic       mem_write,
    output logic [1:0] result_src
);
    logic [1:0] alu_op;

    always_comb begin
        case(opcode)
            // R-type
            7'b0110011: begin reg_write=1; imm_src=3'b000; alu_src=0; mem_write=0; result_src=2'b00; branch=0; jump=0; alu_op=2'b10; end
            // I-type
            7'b0010011: begin reg_write=1; imm_src=3'b000; alu_src=1; mem_write=0; result_src=2'b00; branch=0; jump=0; alu_op=2'b10; end
            // Load
            7'b0000011: begin reg_write=1; imm_src=3'b000; alu_src=1; mem_write=0; result_src=2'b01; branch=0; jump=0; alu_op=2'b00; end
            // Store
            7'b0100011: begin reg_write=0; imm_src=3'b001; alu_src=1; mem_write=1; result_src=2'b00; branch=0; jump=0; alu_op=2'b00; end
            // Branch
            7'b1100011: begin reg_write=0; imm_src=3'b010; alu_src=0; mem_write=0; result_src=2'b00; branch=1; jump=0; alu_op=2'b01; end
            // JAL (Jump and Link)
            7'b1101111: begin reg_write=1; imm_src=3'b011; alu_src=0; mem_write=0; result_src=2'b10; branch=0; jump=1; alu_op=2'b00; end
            
            default:    begin reg_write=0; imm_src=3'b000; alu_src=0; mem_write=0; result_src=2'b00; branch=0; jump=0; alu_op=2'b00; end
        endcase
    end

    always_comb begin
        case(alu_op)
            2'b00: alu_ctrl = 3'b000;
            2'b01: alu_ctrl = 3'b001;
            2'b10: case(funct3)
                       3'b000: if (opcode[5] && funct7b5) alu_ctrl = 3'b001; else alu_ctrl = 3'b000;
                       3'b010: alu_ctrl = 3'b101;
                       3'b110: alu_ctrl = 3'b011;
                       3'b111: alu_ctrl = 3'b010;
                       default: alu_ctrl = 3'b000;
                   endcase
            default: alu_ctrl = 3'b000;
        endcase
    end
endmodule