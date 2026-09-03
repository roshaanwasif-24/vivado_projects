`timescale 1ns / 1ps

module execution_cycle(
    input  logic        clk,
    input  logic        rst,
    input  logic        reg_write_e,
    input  logic [1:0]  result_src_e,
    input  logic        mem_write_e,
    input  logic        jump_e,
    input  logic        branch_e,
    input  logic        alu_src_e,
    input  logic [2:0]  alu_ctrl_e,
    input  logic [31:0] rd1_e,
    input  logic [31:0] rd2_e,
    input  logic [31:0] pc_e,
    input  logic [31:0] imm_ext_e,
    input  logic [31:0] pc_plus4_e,
    input  logic [4:0]  rd_e,
    input  logic [1:0]  forward_a_e,
    input  logic [1:0]  forward_b_e,
    input  logic [31:0] result_w,
    input  logic [31:0] alu_result_m_in, 
    
    output logic        reg_write_m,
    output logic [1:0]  result_src_m,
    output logic        mem_write_m,
    output logic [31:0] alu_result_m,
    output logic [31:0] write_data_m,
    output logic [31:0] pc_plus4_m,
    output logic [4:0]  rd_m,
    output logic        pc_src_e,
    output logic [31:0] pc_target_e
);
    logic [31:0] src_a_e, src_b_e, write_data_e_wire, alu_result_e_wire;
    logic        zero_e;

    mux3 forward_a_mux(.d0(rd1_e),
     .d1(result_w),
     .d2(alu_result_m_in),
     .s(forward_a_e), 
     .y(src_a_e));
    
    mux3 forward_b_mux(.d0(rd2_e),
    .d1(result_w),
    .d2(alu_result_m_in),
    .s(forward_b_e),
    .y(write_data_e_wire));

    mux2 alu_src_mux(.d0(write_data_e_wire),
    .d1(imm_ext_e),
    .s(alu_src_e),
    .y(src_b_e));

    alu arithmetic_logic_unit(.a(src_a_e),
    .b(src_b_e),
    .alu_ctrl(alu_ctrl_e),
    .result(alu_result_e_wire),
    .zero(zero_e));
    
    adder_branch branch_adder(.pc(pc_e),
    .imm(imm_ext_e),
    .target(pc_target_e));

    assign pc_src_e = (branch_e & zero_e) | jump_e;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_m     <= 0; 
            result_src_m    <= 0; 
            mem_write_m     <= 0;
            alu_result_m    <= 0; 
            write_data_m    <= 0; 
            rd_m            <= 0; 
            pc_plus4_m      <= 0;
        end else begin
            reg_write_m     <= reg_write_e; 
            result_src_m    <= result_src_e; 
            mem_write_m     <= mem_write_e;
            alu_result_m    <= alu_result_e_wire; 
            write_data_m    <= write_data_e_wire; 
            rd_m            <= rd_e; 
            pc_plus4_m      <= pc_plus4_e;
        end
    end
endmodule