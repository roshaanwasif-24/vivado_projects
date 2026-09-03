`timescale 1ns / 1ps

module top (
    input  logic clk, reset,
    input  logic uart_rx,
    output logic uart_tx
);
    logic        PCWrite, AdrSrc, MemWrite, IRWrite, RegWrite, Zero;
    logic [2:0]  ImmSrc;
    logic [1:0]  ResultSrc, ALUSrcA, ALUSrcB;
    logic [3:0]  ALUControl;
    logic [31:0] Instr, MemAddr, MemWData, MemRData;

    logic        ram_we, fir_we, fir_re, uart_we, uart_re, fir_ready;
    logic [31:0] ram_rdata, fir_rdata, uart_rdata;

    always_comb begin
        ram_we   = 1'b0; fir_we   = 1'b0; fir_re   = 1'b0;
        uart_we  = 1'b0; uart_re  = 1'b0; MemRData = 32'b0;

        if (MemAddr <= 32'h00002FFF) begin
            ram_we   = MemWrite;
            MemRData = ram_rdata;
        end 
        else if (MemAddr >= 32'h00003000 && MemAddr <= 32'h00003FFF) begin
            fir_we   = MemWrite;
            fir_re   = ~MemWrite; 
            MemRData = fir_rdata;
        end
        else if (MemAddr >= 32'h00004000 && MemAddr <= 32'h00004FFF) begin
            uart_we  = MemWrite;
            uart_re  = ~MemWrite;
            MemRData = uart_rdata;
        end
    end

    controller ctrl (
        .clk(clk), .reset(reset),
        .op(Instr[6:0]), .funct3(Instr[14:12]), .funct7b5(Instr[30]), 
        .Zero(Zero), .PCWrite(PCWrite), .AdrSrc(AdrSrc), .MemWrite(MemWrite), 
        .IRWrite(IRWrite), .RegWrite(RegWrite), .ImmSrc(ImmSrc), 
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .ALUControl(ALUControl), 
        .ResultSrc(ResultSrc)
    );

    datapath dp (
        .clk(clk), .reset(reset),
        .PCWrite(PCWrite), .AdrSrc(AdrSrc), .MemWrite(MemWrite), 
        .IRWrite(IRWrite), .RegWrite(RegWrite), .ImmSrc(ImmSrc), 
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .ALUControl(ALUControl), 
        .ResultSrc(ResultSrc), .Zero(Zero), .Instr(Instr),
        .MemAddr(MemAddr), .MemWData(MemWData), .MemRData(MemRData)
    );

    memorys u_ram (
        .clk(clk), .we(ram_we), .addr(MemAddr[9:2]), .wd(MemWData), .rd(ram_rdata)
    );

    fir_accelerator_top #(.ADDR_WIDTH(8), .BUS_WIDTH(32)) u_fir (
        .clk(clk), .rst_n(~reset), 
        .bus_addr(MemAddr[7:0]), .bus_wdata(MemWData), 
        .bus_we(fir_we), .bus_re(fir_re), .bus_rdata(fir_rdata), .bus_ready(fir_ready)
    );

    uart_top u_uart (
        .clk(clk), .rst_n(~reset),
        .rx_pin(uart_rx), .tx_pin(uart_tx),
        .bus_addr(MemAddr[7:0]), .bus_wdata(MemWData), 
        .bus_we(uart_we), .bus_re(uart_re), .bus_rdata(uart_rdata)
    );
endmodule