`timescale 1ns / 1ps

module TOP(
    input logic clk, rst_n
);
    logic [31:0] if_id_pc, if_id_instr;
    logic        if_id_pred_taken;

    logic [31:0] id_ex_pc, id_ex_rd1, id_ex_rd2, id_ex_imm;
    logic [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    logic [2:0]  id_ex_funct3;
    logic        id_ex_funct7_b;
    logic        id_ex_RegWrite, id_ex_MemtoReg, id_ex_MemWrite, id_ex_MemRead;
    logic        id_ex_Branch, id_ex_ALUSrc, id_ex_pred_taken;
    logic [1:0]  id_ex_ALUOp;

    logic [31:0] ex_mem_alu_result, ex_mem_write_data;
    logic [4:0]  ex_mem_rd;
    logic        ex_mem_RegWrite, ex_mem_MemtoReg, ex_mem_MemWrite, ex_mem_MemRead;

    logic [31:0] mem_wb_read_data, mem_wb_alu_result;
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_RegWrite, mem_wb_MemtoReg;

    logic stall, ex_flush;
    logic [31:0] if_pc, if_instr; logic if_pred_taken;
    logic [31:0] wb_data;
    logic [31:0] id_rd1, id_rd2, id_imm;
    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic        id_RegWrite, id_MemtoReg, id_MemWrite, id_MemRead, id_Branch, id_ALUSrc;
    logic [1:0]  id_ALUOp;
    logic [31:0] ex_alu_result, ex_write_data, ex_recovery_pc, ex_actual_target;
    logic [4:0]  ex_rd;
    logic        ex_update_en, ex_actual_taken;
    logic [1:0]  forward_a, forward_b;
    logic [31:0] mem_read_data;

    fetch_cycle IF_stage (
        .clk(clk), .rst_n(rst_n), .stall(stall),
        .ex_flush(ex_flush), .ex_recovery_pc(ex_recovery_pc),
        .ex_update_en(ex_update_en), .ex_update_pc(id_ex_pc),
        .ex_actual_taken(ex_actual_taken), .ex_actual_target(ex_actual_target),
        .pc_out(if_pc), .instr_out(if_instr), .predict_taken_out(if_pred_taken)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || ex_flush) begin
            if_id_pc <= 0; if_id_instr <= 32'h00000013; if_id_pred_taken <= 0;
        end else if (!stall) begin
            if_id_pc <= if_pc; if_id_instr <= if_instr; if_id_pred_taken <= if_pred_taken;
        end
    end

    decode_cycle ID_stage (
        .clk(clk), .instr(if_id_instr), .pc(if_id_pc),
        .wa3(mem_wb_rd), .wd3(wb_data), .we3(mem_wb_RegWrite),
        .rd1(id_rd1), .rd2(id_rd2), .imm_ext(id_imm),
        .rs1(id_rs1), .rs2(id_rs2), .rd(id_rd),
        .RegWrite(id_RegWrite), .MemtoReg(id_MemtoReg), .MemWrite(id_MemWrite), 
        .MemRead(id_MemRead), .Branch(id_Branch), .ALUSrc(id_ALUSrc), .ALUOp(id_ALUOp)
    );

    hazard_unit HU (
        .rs1_id(id_rs1), .rs2_id(id_rs2), .rd_ex(id_ex_rd), 
        .memread_ex(id_ex_MemRead), .stall(stall)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || stall || ex_flush) begin
            id_ex_pc <= 0; id_ex_rd1 <= 0; id_ex_rd2 <= 0; id_ex_imm <= 0;
            id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
            id_ex_funct3 <= 0; id_ex_funct7_b <= 0;
            id_ex_RegWrite <= 0; id_ex_MemtoReg <= 0; id_ex_MemWrite <= 0; id_ex_MemRead <= 0;
            id_ex_Branch <= 0; id_ex_ALUSrc <= 0; id_ex_ALUOp <= 0; id_ex_pred_taken <= 0;
        end else begin
            id_ex_pc <= if_id_pc; id_ex_rd1 <= id_rd1; id_ex_rd2 <= id_rd2; id_ex_imm <= id_imm;
            id_ex_rs1 <= id_rs1; id_ex_rs2 <= id_rs2; id_ex_rd <= id_rd;
            id_ex_funct3 <= if_id_instr[14:12]; id_ex_funct7_b <= if_id_instr[30];
            id_ex_RegWrite <= id_RegWrite; id_ex_MemtoReg <= id_MemtoReg; id_ex_MemWrite <= id_MemWrite;
            id_ex_MemRead <= id_MemRead; id_ex_Branch <= id_Branch; id_ex_ALUSrc <= id_ALUSrc;
            id_ex_ALUOp <= id_ALUOp; id_ex_pred_taken <= if_id_pred_taken;
        end
    end

    forwarding_unit FW (
        .rs1_ex(id_ex_rs1), .rs2_ex(id_ex_rs2), .rd_mem(ex_mem_rd), .regwrite_mem(ex_mem_RegWrite),
        .rd_wb(mem_wb_rd), .regwrite_wb(mem_wb_RegWrite), .forward_a(forward_a), .forward_b(forward_b)
    );

    execution_cycle EX_stage (
        .pc_in(id_ex_pc), .rd1_in(id_ex_rd1), .rd2_in(id_ex_rd2), .imm_in(id_ex_imm), .rd_in(id_ex_rd),
        .ALUSrc(id_ex_ALUSrc), .Branch(id_ex_Branch), .predict_taken_in(id_ex_pred_taken),
        .ALUOp(id_ex_ALUOp), .funct3(id_ex_funct3), .funct7_bit(id_ex_funct7_b),
        .forward_a(forward_a), .forward_b(forward_b), .fw_mem_data(ex_mem_alu_result), .fw_wb_data(wb_data),
        .alu_result(ex_alu_result), .write_data_out(ex_write_data), .rd_out(ex_rd),
        .ex_flush(ex_flush), .ex_recovery_pc(ex_recovery_pc), .ex_update_en(ex_update_en),
        .ex_actual_taken(ex_actual_taken), .ex_actual_target(ex_actual_target)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result <= 0; ex_mem_write_data <= 0; ex_mem_rd <= 0;
            ex_mem_RegWrite <= 0; ex_mem_MemtoReg <= 0; ex_mem_MemWrite <= 0; ex_mem_MemRead <= 0;
        end else begin
            ex_mem_alu_result <= ex_alu_result; ex_mem_write_data <= ex_write_data; ex_mem_rd <= ex_rd;
            ex_mem_RegWrite <= id_ex_RegWrite; ex_mem_MemtoReg <= id_ex_MemtoReg;
            ex_mem_MemWrite <= id_ex_MemWrite; ex_mem_MemRead <= id_ex_MemRead;
        end
    end

    memory_cycle MEM_stage (
        .clk(clk), .MemWrite(ex_mem_MemWrite), .MemRead(ex_mem_MemRead),
        .alu_result(ex_mem_alu_result), .write_data(ex_mem_write_data), .read_data(mem_read_data)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_read_data <= 0; mem_wb_alu_result <= 0; mem_wb_rd <= 0;
            mem_wb_RegWrite <= 0; mem_wb_MemtoReg <= 0;
        end else begin
            mem_wb_read_data <= mem_read_data; mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_RegWrite <= ex_mem_RegWrite; mem_wb_MemtoReg <= ex_mem_MemtoReg;
        end
    end

    writeback_cycle WB_stage (
        .read_data(mem_wb_read_data), .alu_result(mem_wb_alu_result), 
        .MemtoReg(mem_wb_MemtoReg), .wb_data(wb_data)
    );

endmodule