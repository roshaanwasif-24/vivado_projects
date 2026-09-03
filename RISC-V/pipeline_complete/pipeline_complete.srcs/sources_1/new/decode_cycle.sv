`timescale 1ns / 1ps

module decode_cycle(
    input  logic        clk,
    input  logic        rst,
    input  logic        flush_e,
    input  logic [31:0] instr_d,
    input  logic [31:0] pc_d,
    input  logic [31:0] pc_plus4_d,
    input  logic [31:0] result_w,
    input  logic [4:0]  rd_w,
    input  logic        reg_write_w,
    output logic        reg_write_e,
    output logic [1:0]  result_src_e,
    output logic        mem_write_e,
    output logic        jump_e,
    output logic        branch_e,
    output logic        alu_src_e,
    output logic [2:0]  alu_ctrl_e,
    output logic [31:0] rd1_e,
    output logic [31:0] rd2_e,
    output logic [31:0] pc_e,
    output logic [31:0] imm_ext_e,
    output logic [31:0] pc_plus4_e,
    output logic [4:0]  rs1_e,
    output logic [4:0]  rs2_e,
    output logic [4:0]  rd_e
);

logic        reg_write_d, mem_write_d, jump_d, branch_d, alu_src_d;
logic [1:0]  result_src_d;
logic [2:0]  alu_ctrl_d, imm_src_d;
logic [31:0] rd1_d, rd2_d, imm_ext_d;

    // Combinational
control_unit ctrl(.opcode(instr_d[6:0]), 
                  .funct3(instr_d[14:12]), 
                  .funct7b5(instr_d[30]),
                  .reg_write(reg_write_d), 
                  .imm_src(imm_src_d), 
                  .alu_src(alu_src_d),
                  .alu_ctrl(alu_ctrl_d), 
                  .branch(branch_d), 
                  .jump(jump_d), 
                  .mem_write(mem_write_d), 
                  .result_src(result_src_d));

regfile registers(.clk(clk), 
                  .we3(reg_write_w), 
                  .a1(instr_d[19:15]), 
                  .a2(instr_d[24:20]), 
                  .a3(rd_w), 
                  .wd3(result_w), 
                  .rd1(rd1_d), 
                  .rd2(rd2_d));

imm_gen immediate_generator(.instr(instr_d), 
                            .imm_src(imm_src_d), 
                            .imm_ext(imm_ext_d));

    // Embedded D -> E Pipeline Register
always_ff @(posedge clk or posedge rst) 
begin
        if (rst || flush_e) 
        begin
            reg_write_e <= 0; 
            result_src_e <= 0; 
            mem_write_e <= 0; 
            jump_e <= 0; 
            branch_e <= 0; 
            alu_ctrl_e <= 0; 
            alu_src_e <= 0;
            rd1_e <= 0; 
            rd2_e <= 0; 
            pc_e <= 0; 
            rs1_e <= 0; 
            rs2_e <= 0; 
            rd_e <= 0;
            imm_ext_e <= 0; 
            pc_plus4_e <= 0;
        end else begin
            reg_write_e <= reg_write_d; 
            result_src_e <= result_src_d; 
            mem_write_e <= mem_write_d; 
            jump_e <= jump_d; 
            branch_e <= branch_d; 
            alu_ctrl_e <= alu_ctrl_d; 
            alu_src_e <= alu_src_d;
            rd1_e <= rd1_d; 
            rd2_e <= rd2_d; 
            pc_e <= pc_d; 
            rs1_e <= instr_d[19:15]; 
            rs2_e <= instr_d[24:20]; 
            rd_e <= instr_d[11:7];
            imm_ext_e <= imm_ext_d; 
            pc_plus4_e <= pc_plus4_d;
        end
    end
endmodule