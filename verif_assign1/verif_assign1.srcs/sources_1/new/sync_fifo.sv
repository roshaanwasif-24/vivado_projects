module sync_fifo #(
    parameter W = 8,  // Data Width
    parameter D = 16  // Depth
)(
    input  logic         CLK,
    input  logic         RST,   // Active high asynchronous reset
    input  logic         WEn,
    input  logic         REn,
    input  logic [W-1:0] DIN,
    output logic [W-1:0] DOUT,
    output logic         Full,
    output logic         Empty
);

    localparam ADDR_WIDTH = $clog2(D);
    
    // Register Array
    logic [W-1:0] mem [0:D-1];
    
    // Pointers (Extra bit for full/empty detection)
    logic [ADDR_WIDTH:0] WPTR, RPTR;
    
    // Empty and Full Logic
    assign Empty = (WPTR == RPTR);
    assign Full  = (WPTR == {~RPTR[ADDR_WIDTH], RPTR[ADDR_WIDTH-1:0]});

    // Write Logic
    always_ff @(posedge CLK or posedge RST) begin
        if (RST) begin
            WPTR <= 0;
        end else if (WEn && !Full) begin
            mem[WPTR[ADDR_WIDTH-1:0]] <= DIN;
            WPTR <= WPTR + 1;
        end
    end

    // Read Logic
    always_ff @(posedge CLK or posedge RST) begin
        if (RST) begin
            RPTR <= 0;
            DOUT <= 0;
        end else if (REn && !Empty) begin
            DOUT <= mem[RPTR[ADDR_WIDTH-1:0]];
            RPTR <= RPTR + 1;
        end
    end

endmodule