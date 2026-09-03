`timescale 1ns / 1ps

module memory_cycle(
    input  logic        clk,
    input  logic        rst,
    input  logic        reg_write_m,
    input  logic [1:0]  result_src_m,
    input  logic        mem_write_m,
    input  logic [31:0] alu_result_m,
    input  logic [31:0] write_data_m,
    input  logic [31:0] pc_plus4_m,
    input  logic [4:0]  rd_m,
    output logic        reg_write_w,
    output logic [1:0]  result_src_w,
    output logic [31:0] alu_result_w,
    output logic [31:0] read_data_w,
    output logic [31:0] pc_plus4_w,
    output logic [4:0]  rd_w
);
    logic [31:0] read_data_m_wire;

    // Combinational Internal
    dmem data_memory(.clk(clk), .we(mem_write_m), .a(alu_result_m), .wd(write_data_m), .rd(read_data_m_wire));

    // Embedded M -> W Pipeline Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_w <= 0; 
            result_src_w <= 0;
            alu_result_w <= 0; 
            read_data_w <= 0; 
            rd_w <= 0; 
            pc_plus4_w <= 0;
        end else begin
            reg_write_w <= reg_write_m; 
            result_src_w <= result_src_m;
            alu_result_w <= alu_result_m; 
            read_data_w <= read_data_m_wire; 
            rd_w <= rd_m; 
            pc_plus4_w <= pc_plus4_m;
        end
    end
endmodule