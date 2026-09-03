`timescale 1ns / 1ps

module fetch_cycle(
    input  logic        clk,
    input  logic        rst,
    input  logic        stall_f,
    input  logic        stall_d,
    input  logic        flush_d,
    input  logic        pc_src_e,
    input  logic [31:0] pc_target_e,
    output logic [31:0] instr_d,
    output logic [31:0] pc_d,
    output logic [31:0] pc_plus4_d
);
    logic [31:0] pc_f, pc_next_f, pc_plus4_f, instr_f;

    mux2   next_pc_mux(.d0(pc_plus4_f), 
                       .d1(pc_target_e), 
                       .s(pc_src_e), 
                       .y(pc_next_f));
    
    pc_reg program_counter(.clk(clk), 
                           .rst(rst), 
                           .en(!stall_f), 
                           .pc_next(pc_next_f), 
                           .pc(pc_f));
    
    adder_pc pc_adder(.a(pc_f), 
                      .y(pc_plus4_f));
    
    imem   instruction_memory(.a(pc_f), 
                              .rd(instr_f));

    always_ff @(posedge clk or posedge rst) 
    begin
        if (rst || flush_d) 
        begin
            instr_d    <= 32'b0;
            pc_d       <= 32'b0;
            pc_plus4_d <= 32'b0;
        end 
        else if (!stall_d) 
        begin
            instr_d    <= instr_f;
            pc_d       <= pc_f;
            pc_plus4_d <= pc_plus4_f;
        end
    end
endmodule