`timescale 1ns / 1ps

module execution_cycle(
    input  logic [31:0] pc_in, rd1_in, rd2_in, imm_in,
    input  logic [4:0]  rd_in,
    input  logic        ALUSrc, Branch, predict_taken_in,
    input  logic [1:0]  ALUOp,
    input  logic [2:0]  funct3,
    input  logic        funct7_bit,
    
    // Forwarding
    input  logic [1:0]  forward_a, forward_b,
    input  logic [31:0] fw_mem_data, fw_wb_data,
    
    // EX outputs
    output logic [31:0] alu_result, write_data_out,
    output logic [4:0]  rd_out,
    
    // Branch Resolution Outputs
    output logic        ex_flush,
    output logic [31:0] ex_recovery_pc,
    output logic        ex_update_en,
    output logic        ex_actual_taken,
    output logic [31:0] ex_actual_target
);

    logic [31:0] src_a, src_b_fwd, src_b, branch_target;
    logic [3:0]  alu_ctrl;
    logic        zero;

    // Forwarding Muxes
    mux3 srca_mux (.d0(rd1_in), .d1(fw_wb_data), .d2(fw_mem_data), .s(forward_a), .y(src_a));
    mux3 srcb_mux (.d0(rd2_in), .d1(fw_wb_data), .d2(fw_mem_data), .s(forward_b), .y(src_b_fwd));
    
    assign write_data_out = src_b_fwd;
    assign rd_out = rd_in;

    // ALU Src Mux
    mux2 alusrc_mux (.d0(src_b_fwd), .d1(imm_in), .s(ALUSrc), .y(src_b));

    // Simple ALU Control
    always_comb begin
        case(ALUOp)
            2'b00: alu_ctrl = 4'b0010; // ADD (lw/sw)
            2'b01: alu_ctrl = 4'b0110; // SUB (beq)
            2'b10: begin // R-type
                if (funct3 == 3'b000 && funct7_bit) alu_ctrl = 4'b0110; // sub
                else if (funct3 == 3'b110) alu_ctrl = 4'b0001; // or
                else if (funct3 == 3'b111) alu_ctrl = 4'b0000; // and
                else alu_ctrl = 4'b0010; // add
            end
            default: alu_ctrl = 4'b0010;
        endcase
    end

    alu alu_unit (.a(src_a), .b(src_b), .alu_ctrl(alu_ctrl), .result(alu_result), .zero(zero));
    adder_branch add_br (.a(pc_in), .b(imm_in), .y(branch_target));

    // Branch Resolution
    assign ex_actual_taken = Branch & zero;
    assign ex_actual_target = branch_target;
    assign ex_update_en = Branch;

    always_comb begin
        ex_flush = 1'b0;
        ex_recovery_pc = 32'b0;
        if (Branch) begin
            if (ex_actual_taken && !predict_taken_in) begin
                ex_flush = 1'b1;
                ex_recovery_pc = branch_target;
            end else if (!ex_actual_taken && predict_taken_in) begin
                ex_flush = 1'b1;
                ex_recovery_pc = pc_in + 4;
            end
        end
    end
endmodule