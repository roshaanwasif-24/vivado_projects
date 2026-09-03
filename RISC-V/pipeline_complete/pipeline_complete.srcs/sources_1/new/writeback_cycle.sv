`timescale 1ns / 1ps

module writeback_cycle(
    input  logic [31:0] alu_result_w,
    input  logic [31:0] read_data_w,
    input  logic [31:0] pc_plus4_w,
    input  logic [1:0]  result_src_w,
    output logic [31:0] result_w
);
    mux3 writeback_mux(.d0(alu_result_w), .d1(read_data_w), .d2(pc_plus4_w), .s(result_src_w), .y(result_w));
endmodule