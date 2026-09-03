`timescale 1ns / 1ps

module hazard_unit(
    input  logic [4:0] rs1_d,
    input  logic [4:0] rs2_d,
    input  logic [4:0] rs1_e,
    input  logic [4:0] rs2_e,
    input  logic [4:0] rd_e,
    input  logic       pc_src_e,
    input  logic       result_src_e0, 
    input  logic [4:0] rd_m,
    input  logic       reg_write_m,
    input  logic [4:0] rd_w,
    input  logic       reg_write_w,
    output logic [1:0] forward_a_e,
    output logic [1:0] forward_b_e,
    output logic       stall_f,
    output logic       stall_d,
    output logic       flush_d,
    output logic       flush_e
);

    always_comb begin
        if ((rs1_e == rd_m) && reg_write_m && (rs1_e != 5'b0)) 
            forward_a_e = 2'b10;
        else if ((rs1_e == rd_w) && reg_write_w && (rs1_e != 5'b0)) 
            forward_a_e = 2'b01;
        else 
            forward_a_e = 2'b00;
    end

    always_comb begin
        if ((rs2_e == rd_m) && reg_write_m && (rs2_e != 5'b0)) 
            forward_b_e = 2'b10;
        else if ((rs2_e == rd_w) && reg_write_w && (rs2_e != 5'b0)) 
            forward_b_e = 2'b01;
        else 
            forward_b_e = 2'b00;
    end

    logic lw_stall;
    assign lw_stall = result_src_e0 & ((rs1_d == rd_e) | (rs2_d == rd_e));

    assign stall_f = lw_stall;
    assign stall_d = lw_stall;
    
    assign flush_d = pc_src_e;
    assign flush_e = lw_stall | pc_src_e;

endmodule
