module tb_sync_fifo;
    parameter W = 8;
    parameter D = 16;

    logic         CLK;
    logic         RST;
    logic         WEn;
    logic         REn;
    logic [W-1:0] DIN;
    logic [W-1:0] DOUT;
    logic         Full;
    logic         Empty;

    sync_fifo #(W, D) dut (.*);

    // Clock Generation
    always #5 CLK = ~CLK;

    initial begin
        // Initialize
        CLK = 0; WEn = 0; REn = 0; DIN = 0;
        
        // Active high reset
        RST = 1; #15; RST = 0;
        
        // 1. Write until Full
        @(posedge CLK);
        WEn = 1;
        for (int i = 0; i < D + 2; i++) begin
            DIN = i;
            @(posedge CLK);
        end
        WEn = 0;
        
        // 2. Read until Empty
        #20;
        REn = 1;
        for (int i = 0; i < D + 2; i++) begin
            @(posedge CLK);
        end
        REn = 0;
        
        // 3. Simultaneous Read and Write
        #20;
        WEn = 1; DIN = 8'hAA;
        @(posedge CLK);
        REn = 1; DIN = 8'hBB;
        @(posedge CLK);
        WEn = 0; REn = 0;
        
        #50 $finish;
    end
endmodule