`timescale 1ns / 1ps


`timescale 1ns/1ps

module TOP_TB;
  
  logic clk, rst;
  integer i;

  TOP dut (
    .clk(clk), 
    .rst(rst)
  );

  always #5 clk = ~clk;

  initial begin
    // Clear all registers to 0 to prevent 'x' states from propagating through pipeline
    for (i = 0; i < 32; i = i + 1) begin
        dut.stage_d.registers.rf[i] = 32'b0;
    end

    // Load the exact same test program
    
    // addi x1, x0, 20
    dut.stage_f.instruction_memory.ROM[0]  = 32'h01400093; 
    // addi x2, x0, 5
    dut.stage_f.instruction_memory.ROM[1]  = 32'h00500113; 
    // sub x3, x1, x2  (Tests forwarding from Memory AND Writeback stages simultaneously)
    dut.stage_f.instruction_memory.ROM[2]  = 32'h402081b3; 
    // and x4, x1, x3
    dut.stage_f.instruction_memory.ROM[3]  = 32'h0030f233; 
    // or x5, x4, x2
    dut.stage_f.instruction_memory.ROM[4]  = 32'h002262b3; 
    // sw x5, 40(x0)
    dut.stage_f.instruction_memory.ROM[5]  = 32'h02502423; 
    // lw x6, 40(x0)
    dut.stage_f.instruction_memory.ROM[6]  = 32'h02802303; 
    // beq x6, x5, 8   (Read x6 immediately after Load -> Triggers a Load-Use Stall!)
    dut.stage_f.instruction_memory.ROM[7]  = 32'h00530463; 
    // addi x7, x0, 99 (Should be flushed/skipped by branch)
    dut.stage_f.instruction_memory.ROM[8]  = 32'h06300393; 
    // jal x8, 8       (Triggers unconditional jump flush)
    dut.stage_f.instruction_memory.ROM[9]  = 32'h0080046f; 
    // addi x9, x0, 99 (Should be flushed/skipped by jump)
    dut.stage_f.instruction_memory.ROM[10] = 32'h06300493; 
    // slt x10, x2, x1
    dut.stage_f.instruction_memory.ROM[11] = 32'h00112533; 

    clk = 0;
    rst = 1;
    #12;
    rst = 0;
    
    // Increased simulation time from 450 to 600 to account for pipeline depth, stalls, and flushes
    #600;
    
    $display("=== Pipelined Simulation Complete ===");
    $display("x1  = %0d", dut.stage_d.registers.rf[1]);
    $display("x2  = %0d", dut.stage_d.registers.rf[2]);
    $display("x3  = %0d", dut.stage_d.registers.rf[3]);
    $display("x4  = %0d", dut.stage_d.registers.rf[4]);
    $display("x5  = %0d", dut.stage_d.registers.rf[5]);
    $display("x6  = %0d", dut.stage_d.registers.rf[6]);
    $display("x7  = %0d", dut.stage_d.registers.rf[7]);
    $display("x8  = %0d", dut.stage_d.registers.rf[8]);
    $display("x9  = %0d", dut.stage_d.registers.rf[9]);
    $display("x10 = %0d", dut.stage_d.registers.rf[10]);

    if (dut.stage_d.registers.rf[1]  === 32'd20 &&
        dut.stage_d.registers.rf[2]  === 32'd5  &&
        dut.stage_d.registers.rf[3]  === 32'd15 &&
        dut.stage_d.registers.rf[4]  === 32'd4  &&
        dut.stage_d.registers.rf[5]  === 32'd5  &&
        dut.stage_d.registers.rf[6]  === 32'd5  &&
        dut.stage_d.registers.rf[7]  === 32'd0  &&
        dut.stage_d.registers.rf[8]  === 32'd40 && // jal PC+4 link address
        dut.stage_d.registers.rf[9]  === 32'd0  &&
        dut.stage_d.registers.rf[10] === 32'd1)
      $display("PASS REGISTERS & HAZARDS");
    else
      $display("FAIL REGISTERS & HAZARDS");

    $finish;
  end

  // Independent check to ensure the memory stage writes correctly
  initial begin
    // Wait for the memory write signal in the M stage to go high
    @(posedge dut.mem_write_m);
    if (dut.alu_result_m === 32'd40 && dut.write_data_m === 32'd5)
      $display("PASS PIPELINED MEMORY");
    else
      $display("FAIL PIPELINED MEMORY");
  end

endmodule