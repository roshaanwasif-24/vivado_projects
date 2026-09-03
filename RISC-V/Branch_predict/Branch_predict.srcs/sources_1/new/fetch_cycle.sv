`timescale 1ns / 1ps

module fetch_cycle(
    input  logic        clk, rst_n, stall,
    input  logic        ex_flush,          
    input  logic [31:0] ex_recovery_pc,    
    input  logic        ex_update_en,      
    input  logic [31:0] ex_update_pc,     
    input  logic        ex_actual_taken,   
    input  logic [31:0] ex_actual_target,  
    
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic        predict_taken_out
);

    logic [31:0] pc_reg_out, pc_plus4, predict_target, next_pc_pred, next_pc_final;
    logic pred_taken;

    assign next_pc_pred = pred_taken ? predict_target : pc_plus4;
    assign next_pc_final = ex_flush ? ex_recovery_pc : next_pc_pred;

    pc_reg pcreg (.clk(clk), .rst_n(rst_n), .en(~stall), .d(next_pc_final), .q(pc_reg_out));
    adder_pc addpc (.a(pc_reg_out), .y(pc_plus4));
    imem instrmem (.a(pc_reg_out), .rd(instr_out));

    branch_predictor bp (
        .clk(clk), .rst_n(rst_n),
        .pc_fetch(pc_reg_out), .predict_taken(pred_taken), .predict_target(predict_target),
        .update_en(ex_update_en), .pc_update(ex_update_pc), 
        .actual_taken(ex_actual_taken), .actual_target(ex_actual_target)
    );

    assign pc_out = pc_reg_out;
    assign predict_taken_out = pred_taken;
endmodule