`timescale 1ns / 1ps

module mux_2to1_tb();
reg X,Y,S;
wire M;

mux_2to1 UUT(
    .x(X),
    .y(Y),
    .s(S)
);

initial begin
X = 0; Y = 0;  S = 0;
X = 0; Y = 1;  S = 0;
X = 1; Y = 0;  S = 0;
X = 1; Y = 1;  S = 0;
#10

X = 0; Y = 0;  S = 1;
X = 0; Y = 1;  S = 1;
X = 1; Y = 0;  S = 1;
X = 1; Y = 1;  S = 1;
#10

$stop;
end

endmodule
