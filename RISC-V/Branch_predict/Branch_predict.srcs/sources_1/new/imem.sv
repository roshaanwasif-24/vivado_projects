`timescale 1ns / 1ps

module imem(
    input  logic [31:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM[0:255];
    assign rd = RAM[a[9:2]];
endmodule