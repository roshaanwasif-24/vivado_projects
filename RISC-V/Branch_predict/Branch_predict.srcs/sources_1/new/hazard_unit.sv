`timescale 1ns / 1ps

module hazard_unit(
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    input  logic [4:0] rd_ex,
    input  logic       memread_ex,
    output logic       stall
);
    always_comb begin
        if (memread_ex && (rd_ex != 0) && ((rd_ex == rs1_id) || (rd_ex == rs2_id)))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
endmodule