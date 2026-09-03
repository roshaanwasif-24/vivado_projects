`timescale 1ns / 1ps

module branch_predictor #(
    parameter ENTRIES = 32
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Fetch Stage (Prediction)
    input  logic [31:0] pc_fetch,
    output logic        predict_taken,
    output logic [31:0] predict_target,
    
    // Execute Stage (Update)
    input  logic        update_en,
    input  logic [31:0] pc_update,
    input  logic        actual_taken,
    input  logic [31:0] actual_target
);

    typedef enum logic [1:0] {
        STR_NT = 2'b00, WEA_NT = 2'b01, 
        WEA_T  = 2'b10, STR_T  = 2'b11
    } bht_state_t;

    bht_state_t  bht [ENTRIES-1:0];
    logic [31:0] btb [ENTRIES-1:0];
    logic        valid [ENTRIES-1:0];

    logic [4:0] fetch_idx, update_idx;
    assign fetch_idx  = pc_fetch[6:2];
    assign update_idx = pc_update[6:2];

    always_comb begin
        predict_taken  = 1'b0;
        predict_target = pc_fetch + 4;
        if (valid[fetch_idx] && (bht[fetch_idx] == WEA_T || bht[fetch_idx] == STR_T)) begin
            predict_taken  = 1'b1;
            predict_target = btb[fetch_idx];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ENTRIES; i++) begin
                bht[i] <= WEA_NT; valid[i] <= 1'b0; btb[i] <= '0;
            end
        end else if (update_en) begin
            valid[update_idx] <= 1'b1;
            if (actual_taken) btb[update_idx] <= actual_target;
            
            case (bht[update_idx])
                STR_NT: bht[update_idx] <= actual_taken ? WEA_NT : STR_NT;
                WEA_NT: bht[update_idx] <= actual_taken ? WEA_T  : STR_NT;
                WEA_T:  bht[update_idx] <= actual_taken ? STR_T  : WEA_NT;
                STR_T:  bht[update_idx] <= actual_taken ? STR_T  : WEA_T;
            endcase
        end
    end
endmodule