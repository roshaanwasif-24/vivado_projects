`timescale 1ns / 1ps

module ALU(
    input  logic [31:0] operand_a, operand_b,    
    input  logic [3:0]  alu_control,  
    output logic [31:0] alu_result,  
    output logic        zero_flag    
);
    always_comb begin
        case (alu_control)
            4'b0000:  alu_result = operand_a + operand_b;
            4'b0001:  alu_result = operand_a - operand_b;
            4'b0010:  alu_result = operand_a & operand_b;
            4'b0011:  alu_result = operand_a | operand_b;
            4'b0100:  alu_result = operand_a ^ operand_b;
            4'b0101:  alu_result = operand_a << operand_b[4:0];  
            4'b0110:  alu_result = operand_a >> operand_b[4:0];
            default:  alu_result = 32'b0; 
        endcase
    end
    assign zero_flag = (alu_result == 32'b0);
endmodule