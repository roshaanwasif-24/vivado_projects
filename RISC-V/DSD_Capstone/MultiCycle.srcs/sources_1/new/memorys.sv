`timescale 1ns / 1ps

module memorys (
    input  wire        clk, we,    
    input  wire [7:0]  addr,  
    input  wire [31:0] wd,    
    output wire [31:0] rd     
);
    reg [31:0] RAM [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) RAM[i] = 32'b0;
        
        RAM[0]  = 32'h00003437; // lui s0, 0x3000
        RAM[1]  = 32'h00040413; // addi s0, s0, 0
        RAM[2]  = 32'h000044B7; // lui s1, 0x4000
        RAM[3]  = 32'h00048493; // addi s1, s1, 0
        RAM[4]  = 32'h0044A283; // wait_rx1: lw t0, 4(s1)
        RAM[5]  = 32'h0022F293; // andi t0, t0, 2
        RAM[6]  = 32'hFE028CE3; // beqz t0, wait_rx1
        RAM[7]  = 32'h0004A303; // lw t1, 0(s1)
        RAM[8]  = 32'h0044A283; // wait_rx2: lw t0, 4(s1)
        RAM[9]  = 32'h0022F293; // andi t0, t0, 2
        RAM[10] = 32'hFE028CE3; // beqz t0, wait_rx2
        RAM[11] = 32'h0004A383; // lw t2, 0(s1)       
        RAM[12] = 32'h00839393; // slli t2, t2, 8
        RAM[13] = 32'h00736E33; // or t3, t1, t2      
        RAM[14] = 32'h01C42023; // sw t3, 0(s0)     
        RAM[15] = 32'h00842283; // wait_fir: lw t0, 8(s0)
        RAM[16] = 32'h0012F293; // andi t0, t0, 1
        RAM[17] = 32'hFE028CE3; // beqz t0, wait_fir
        RAM[18] = 32'h00442E83; // lw t4, 4(s0)
        RAM[19] = 32'h00400F13; // li t5, 4 
        RAM[20] = 32'h0044A283; // wait_tx: lw t0, 4(s1)
        RAM[21] = 32'h0012F293; // andi t0, t0, 1
        RAM[22] = 32'hFE029CE3; // bnez t0, wait_tx
        RAM[23] = 32'h01D4A023; // sw t4, 0(s1) 
        RAM[24] = 32'h008EDE93; // srli t4, t4, 8 
        RAM[25] = 32'hFFFF0F13; // addi t5, t5, -1
        RAM[26] = 32'hFE0F14E3; // bnez t5, wait_tx 
        RAM[27] = 32'hFA5FF06F; // j wait_rx1 
    end
    assign rd = RAM[addr];
    always @(posedge clk) if (we) RAM[addr] <= wd;
endmodule