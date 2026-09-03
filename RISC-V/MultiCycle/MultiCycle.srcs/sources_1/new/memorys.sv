`timescale 1ns / 1ps

module memorys (
    input  wire        clk,   
    input  wire        we,    // Write Enable (1 = write, 0 = read)
    input  wire [7:0]  addr,  // 8-bit address (points to 1 of 256 words)
    input  wire [31:0] wd,    
    output wire [31:0] rd     
);

    reg [31:0] RAM [0:255];
    assign rd = RAM[addr];

    always @(posedge clk) begin
        if (we) begin
            RAM[addr] <= wd;
        end
    end

endmodule