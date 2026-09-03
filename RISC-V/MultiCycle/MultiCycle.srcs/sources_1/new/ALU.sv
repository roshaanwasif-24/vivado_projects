`timescale 1ns / 1ps

module ALU(
    input  logic [31:0] operand_a,   
    input  logic [31:0] operand_b,   
    input  logic [3:0] alu_control,  
    output logic [31:0] alu_result,  
    output logic zero_flag    
);
    localparam ALU_ADD  = 4'b0000, ALU_SUB  = 4'b0001, ALU_AND  = 4'b0010, 
               ALU_OR   = 4'b0011, ALU_XOR  = 4'b0100, ALU_SLL  = 4'b0101, 
               ALU_SRL  = 4'b0110;

    always_comb begin
        case (alu_control)
            ALU_ADD:  alu_result = operand_a + operand_b;
            ALU_SUB:  alu_result = operand_a - operand_b;
            ALU_AND:  alu_result = operand_a & operand_b;
            ALU_OR:   alu_result = operand_a | operand_b;
            ALU_XOR:  alu_result = operand_a ^ operand_b;
            ALU_SLL:  alu_result = operand_a << operand_b[4:0];  
            ALU_SRL:  alu_result = operand_a >> operand_b[4:0];
            default:  alu_result = 32'b0; 
        endcase
    end

    assign zero_flag = (alu_result == 32'b0);
endmodule

