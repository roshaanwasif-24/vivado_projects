`timescale 1ns / 1ps

module mux_2to1(m, x, y, s);
input x, y, s;
output m;
    
    assign m =(~s&x)|(s&y);
     
endmodule

