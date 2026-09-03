`timescale 1ns / 1ps


module PC_TB( );

logic clk,en,rst;
logic [31:0]pc;

PC uut (.*);

always #5 clk = ~clk;

initial begin
clk = 0;
rst = 1;
en = 0;
#10;

rst = 0;
en = 1;

#100;
$finish;

end


endmodule
