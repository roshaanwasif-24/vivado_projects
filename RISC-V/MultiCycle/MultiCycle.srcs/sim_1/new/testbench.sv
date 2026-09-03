`timescale 1ns/1ps

module testbench;
  logic clk, reset;

  top dut (
    .clk(clk), 
    .reset(reset)
  );

  always #5 clk = ~clk;

  initial begin
    dut.dp.mem.RAM[0]  = 32'h00500093; 
    dut.dp.mem.RAM[4]  = 32'h00300113; 
    dut.dp.mem.RAM[8]  = 32'h002081b3; 
    dut.dp.mem.RAM[12] = 32'h02302023; 
    dut.dp.mem.RAM[16] = 32'h02002203; 
    dut.dp.mem.RAM[20] = 32'h00208463; 
    dut.dp.mem.RAM[24] = 32'h00100293; 
    dut.dp.mem.RAM[28] = 32'h00000013; 

    clk   = 0;
    reset = 1;
    #12;
    reset = 0;
    
    #450;
    $display("=== Simulation Complete ===");
    $display("x1 = %0d (expected 5)",  dut.dp.rf.rf[1]);
    $display("x2 = %0d (expected 3)",  dut.dp.rf.rf[2]);
    $display("x3 = %0d (expected 8)",  dut.dp.rf.rf[3]);
    $display("x4 = %0d (expected 8)",  dut.dp.rf.rf[4]);
    $display("x5 = %0d (expected 1)",  dut.dp.rf.rf[5]);

    if (dut.dp.rf.rf[1] === 32'd5  &&
        dut.dp.rf.rf[2] === 32'd3  &&
        dut.dp.rf.rf[3] === 32'd8  &&
        dut.dp.rf.rf[4] === 32'd8  &&
        dut.dp.rf.rf[5] === 32'd1)
      $display("PASS: all register values correct");
    else
      $display("FAIL: one or more register values wrong");

    $finish;
  end

  initial begin
    @(posedge dut.dp.MemWrite);
    if (dut.dp.Adr === 32'd32 && dut.dp.B === 32'd8)
      $display("PASS: sw wrote 8 to address 32 (word 8)");
    else
      $display("FAIL: unexpected store Adr=%0d WriteData=%0d", dut.dp.Adr, dut.dp.B);
  end

endmodule