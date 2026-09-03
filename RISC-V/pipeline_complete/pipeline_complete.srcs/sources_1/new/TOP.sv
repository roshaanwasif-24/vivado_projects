`timescale 1ns / 1ps


module TOP(
    input logic clk,
    input logic rst
);

    logic [1:0] forward_a_e, forward_b_e;
    logic       stall_f, stall_d, flush_d, flush_e;

    logic [31:0] instr_d, pc_d, pc_plus4_d; 
    
    logic        reg_write_e, mem_write_e, jump_e, branch_e, alu_src_e, pc_src_e;
    logic [1:0]  result_src_e;
    logic [2:0]  alu_ctrl_e;
    logic [31:0] rd1_e, rd2_e, pc_e, imm_ext_e, pc_plus4_e, pc_target_e;
    logic [4:0]  rs1_e, rs2_e, rd_e; 
    
    logic        reg_write_m, mem_write_m;
    logic [1:0]  result_src_m;
    logic [31:0] alu_result_m, write_data_m, pc_plus4_m;
    logic [4:0]  rd_m; 
    
    logic        reg_write_w;
    logic [1:0]  result_src_w;
    logic [31:0] alu_result_w, read_data_w, pc_plus4_w, result_w;
    logic [4:0]  rd_w; 

    // 0. Hazard Unit
    hazard_unit hu(
        .rs1_d(instr_d[19:15]), .rs2_d(instr_d[24:20]), .rs1_e(rs1_e), .rs2_e(rs2_e), .rd_e(rd_e),
        .pc_src_e(pc_src_e), .result_src_e0(result_src_e[0]), .rd_m(rd_m), .reg_write_m(reg_write_m),
        .rd_w(rd_w), .reg_write_w(reg_write_w), .forward_a_e(forward_a_e), .forward_b_e(forward_b_e),
        .stall_f(stall_f), .stall_d(stall_d), .flush_d(flush_d), .flush_e(flush_e)
    );

    // 1. Fetch Cycle
    fetch_cycle stage_f(
        .clk(clk), .rst(rst), .stall_f(stall_f), .stall_d(stall_d), .flush_d(flush_d),
        .pc_src_e(pc_src_e), .pc_target_e(pc_target_e),
        .instr_d(instr_d), .pc_d(pc_d), .pc_plus4_d(pc_plus4_d)
    );

    // 2. Decode Cycle
    decode_cycle stage_d(
        .clk(clk), .rst(rst), .flush_e(flush_e),
        .instr_d(instr_d), .pc_d(pc_d), .pc_plus4_d(pc_plus4_d),
        .result_w(result_w), .rd_w(rd_w), .reg_write_w(reg_write_w),
        .reg_write_e(reg_write_e), .result_src_e(result_src_e), .mem_write_e(mem_write_e),
        .jump_e(jump_e), .branch_e(branch_e), .alu_src_e(alu_src_e), .alu_ctrl_e(alu_ctrl_e),
        .rd1_e(rd1_e), .rd2_e(rd2_e), .pc_e(pc_e), .imm_ext_e(imm_ext_e), .pc_plus4_e(pc_plus4_e),
        .rs1_e(rs1_e), .rs2_e(rs2_e), .rd_e(rd_e)
    );

    // 3. Execute Cycle
    execution_cycle stage_e(
        .clk(clk), .rst(rst),
        .reg_write_e(reg_write_e), .result_src_e(result_src_e), .mem_write_e(mem_write_e),
        .jump_e(jump_e), .branch_e(branch_e), .alu_src_e(alu_src_e), .alu_ctrl_e(alu_ctrl_e),
        .rd1_e(rd1_e), .rd2_e(rd2_e), .pc_e(pc_e), .imm_ext_e(imm_ext_e), .pc_plus4_e(pc_plus4_e), .rd_e(rd_e),
        .forward_a_e(forward_a_e), .forward_b_e(forward_b_e),
        .result_w(result_w), .alu_result_m_in(alu_result_m),
        .reg_write_m(reg_write_m), .result_src_m(result_src_m), .mem_write_m(mem_write_m),
        .alu_result_m(alu_result_m), .write_data_m(write_data_m), .pc_plus4_m(pc_plus4_m), .rd_m(rd_m),
        .pc_src_e(pc_src_e), .pc_target_e(pc_target_e)
    );

    // 4. Memory Cycle
    memory_cycle stage_m(
        .clk(clk), .rst(rst),
        .reg_write_m(reg_write_m), .result_src_m(result_src_m), .mem_write_m(mem_write_m),
        .alu_result_m(alu_result_m), .write_data_m(write_data_m), .pc_plus4_m(pc_plus4_m), .rd_m(rd_m),
        .reg_write_w(reg_write_w), .result_src_w(result_src_w),
        .alu_result_w(alu_result_w), .read_data_w(read_data_w), .pc_plus4_w(pc_plus4_w), .rd_w(rd_w)
    );

    // 5. Writeback Cycle
    writeback_cycle stage_w(
        .alu_result_w(alu_result_w), .read_data_w(read_data_w), .pc_plus4_w(pc_plus4_w),
        .result_src_w(result_src_w), .result_w(result_w)
    );

endmodule