`timescale 1ns / 1ps

module adder_pc(
    input  logic [31:0] a,
    output logic [31:0] y
);
    assign y = a + 32'd4;
endmodule