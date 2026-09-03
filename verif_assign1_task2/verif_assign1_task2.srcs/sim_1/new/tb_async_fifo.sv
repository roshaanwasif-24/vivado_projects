module tb_async_fifo;
    parameter W = 8;
    parameter D = 16;

    logic         wclk, rclk;
    logic         wrst_n, rrst_n;
    logic         winc, rinc;
    logic [W-1:0] wdata;
    logic [W-1:0] rdata;
    logic         wfull, rempty;

    async_fifo #(W, D) dut (.*);

    // Asynchronous Clocks
    always #5  wclk = ~wclk; // Fast write clock
    always #13 rclk = ~rclk; // Slow read clock

    initial begin
        wclk = 0; rclk = 0;
        winc = 0; rinc = 0;
        wdata = 0;
        
        // Active low resets
        wrst_n = 0; rrst_n = 0;
        #20;
        wrst_n = 1; rrst_n = 1;
        
        // Wait for synchronizers to settle
        #50;

        // Write Burst
        @(posedge wclk);
        winc = 1;
        for (int i = 0; i < 5; i++) begin
            wdata = $random;
            @(posedge wclk);
        end
        winc = 0;

        #100;

        // Read Burst
        @(posedge rclk);
        rinc = 1;
        for (int i = 0; i < 5; i++) begin
            @(posedge rclk);
        end
        rinc = 0;

        #100 $finish;
    end
endmodule