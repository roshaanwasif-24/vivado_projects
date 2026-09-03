module async_fifo #(
    parameter W = 8,
    parameter D = 16
)(
    input  logic         wclk,
    input  logic         wrst_n, // Active low asynchronous reset
    input  logic         winc,
    input  logic [W-1:0] wdata,
    output logic         wfull,
    
    input  logic         rclk,
    input  logic         rrst_n, // Active low asynchronous reset
    input  logic         rinc,
    output logic [W-1:0] rdata,
    output logic         rempty
);

    localparam ADDR_WIDTH = $clog2(D);

    logic [ADDR_WIDTH-1:0] waddr, raddr;
    logic [ADDR_WIDTH:0]   wptr, rptr, wq2_rptr, rq2_wptr;

    // Dual-Port RAM Memory
    logic [W-1:0] mem [0:D-1];
    
    always_ff @(posedge wclk) begin
        // Handle the situation where WEn is asserted but FIFO is full [cite: 19]
        if (winc && !wfull) 
            mem[waddr] <= wdata;
    end
    
    assign rdata = mem[raddr];

    // Read Pointer & Empty Logic
    logic [ADDR_WIDTH:0] rbin, rnext, rbnext;

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0;
            rptr <= 0;
        end else begin
            rbin <= rbnext;
            rptr <= rnext;
        end
    end

    assign rbnext = rbin + (rinc & ~rempty);
    assign rnext  = (rbnext >> 1) ^ rbnext; // Binary to Gray code
    assign raddr  = rbin[ADDR_WIDTH-1:0];
    assign rempty = (rnext == rq2_wptr);

    // Write Pointer & Full Logic
    logic [ADDR_WIDTH:0] wbin, wnext, wbnext;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0;
            wptr <= 0;
        end else begin
            wbin <= wbnext;
            wptr <= wnext;
        end
    end

    assign wbnext = wbin + (winc & ~wfull);
    assign wnext  = (wbnext >> 1) ^ wbnext; // Binary to Gray code
    assign waddr  = wbin[ADDR_WIDTH-1:0];
    // Full when Gray code pointers have opposite 2 MSBs but identical LSBs
    assign wfull  = (wnext == {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1], wq2_rptr[ADDR_WIDTH-2:0]});

    // Synchronizer: Write pointer to Read domain (sync_w2r)
    logic [ADDR_WIDTH:0] rq1_wptr;
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {rq2_wptr, rq1_wptr} <= 0;
        else         {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end

    // Synchronizer: Read pointer to Write domain (sync_r2w)
    logic [ADDR_WIDTH:0] wq1_rptr;
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {wq2_rptr, wq1_rptr} <= 0;
        else         {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end

endmodule