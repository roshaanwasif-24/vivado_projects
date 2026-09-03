`timescale 1ns / 1ps

module memory_cycle(
    input  logic        clk,
    input  logic        MemWrite, MemRead,
    input  logic [31:0] alu_result, write_data,
    output logic [31:0] read_data
);
    dmem data_mem (
        .clk(clk), .we(MemWrite), .a(alu_result), 
        .wd(write_data), .rd(read_data)
    );
endmodule