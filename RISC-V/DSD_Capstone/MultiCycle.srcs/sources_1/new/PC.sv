`timescale 1ns / 1ps

module PC(
input logic clk,en,rst,
output logic [31:0]pc
    );
    
    always @(posedge clk) begin
    
        if (rst)
            pc <= 0;
         
         else if (en)
            pc <= pc + 4;
            
          else pc <= pc;       
    end
    
endmodule
