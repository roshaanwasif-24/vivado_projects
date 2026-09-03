`timescale 1ns / 1ps

module TOP(
    input  logic clk,
    input  logic rst
);

    // Internal Wire Declarations
    
    // Fetch wires
    logic [31:0] pc_next, pc, pc_plus_4, pc_target;
    logic [31:0] instr;
    
    // Control wires
    logic        reg_write, alu_src, jump, branch, mem_write;
    logic [2:0]  imm_src, alu_ctrl;
    logic [1:0]  result_src;
    logic        pc_src; // Derived branch signal
    
    // Data wires
    logic [31:0] rd1, rd2, imm_ext;
    logic [31:0] src_b, alu_result;
    logic        zero;
    logic [31:0] read_data, result;

    // 1. Fetch Stage
    
    // Next PC logic (Branch AND Zero flag determines if we take the branch)
    assign pc_src = (branch & zero) | jump;
    
    mux2 next_pc_mux(
        .d0(pc_plus_4), 
        .d1(pc_target), 
        .s(pc_src), 
        .y(pc_next)
    );

    pc_reg program_counter(
        .clk(clk), 
        .rst(rst), 
        .pc_next(pc_next), 
        .pc(pc)
    );

    adder_pc pc_adder(
        .a(pc), 
        .y(pc_plus_4)
    );

    imem instruction_memory(
        .a(pc), 
        .rd(instr)
    );

    // 2. Decode & Control Stage

    control_unit ctrl(
        .opcode(instr[6:0]), 
        .funct3(instr[14:12]), 
        .funct7b5(instr[30]), 
        .reg_write(reg_write), 
        .imm_src(imm_src), 
        .alu_src(alu_src), 
        .alu_ctrl(alu_ctrl), 
        .branch(branch),
        .jump(jump), 
        .mem_write(mem_write), 
        .result_src(result_src)
    );

    regfile registers(
        .clk(clk), 
        .we3(reg_write), 
        .a1(instr[19:15]), 
        .a2(instr[24:20]), 
        .a3(instr[11:7]), 
        .wd3(result), 
        .rd1(rd1), 
        .rd2(rd2)
    );

    imm_gen immediate_generator(
        .instr(instr), 
        .imm_src(imm_src), 
        .imm_ext(imm_ext)
    );

    // 3. Execution Stage

    mux2 alu_src_mux(
        .d0(rd2), 
        .d1(imm_ext), 
        .s(alu_src), 
        .y(src_b)
    );

    alu arithmetic_logic_unit(
        .a(rd1), 
        .b(src_b), 
        .alu_ctrl(alu_ctrl), 
        .result(alu_result), 
        .zero(zero)
    );

    adder_branch branch_adder(
        .pc(pc), 
        .imm(imm_ext), 
        .target(pc_target)
    );

    // 4. Memory & Write-back Stage

    dmem data_memory(
        .clk(clk), 
        .we(mem_write), 
        .a(alu_result), 
        .wd(rd2), 
        .rd(read_data)
    );

    mux3 writeback_mux(
        .d0(alu_result), 
        .d1(read_data), 
        .d2(pc_plus_4), 
        .s(result_src), 
        .y(result)
    );

endmodule