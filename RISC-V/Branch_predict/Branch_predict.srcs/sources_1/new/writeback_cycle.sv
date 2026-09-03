`timescale 1ns / 1ps

module writeback_cycle(
    input  logic [31:0] read_data, alu_result,
    input  logic        MemtoReg,
    output logic [31:0] wb_data
);
    mux2 wb_mux (.d0(alu_result), .d1(read_data), .s(MemtoReg), .y(wb_data));
endmodule