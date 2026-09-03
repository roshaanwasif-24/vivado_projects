`timescale 1ns / 1ps

module TOP_TB();

    // Testbench signals
    logic clk;
    logic rst_n;

    // Instantiate the Top-Level Processor
    TOP dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus and Monitoring
    initial begin
        // 1. Initialize Reset
        rst_n = 0;
        
        // 2. Load the Program into Instruction Memory (IMEM)
        // We are using hierarchical references to bypass the need for an external .mem file in Vivado.
        
        // Address 0: addi x1, x0, 3      (Initialize loop counter x1 = 3)
        dut.IF_stage.instrmem.RAM[0] = 32'h00300093;
        
        // Address 4: addi x2, x0, 1      (Decrement value x2 = 1)
        dut.IF_stage.instrmem.RAM[1] = 32'h00100113;
        
        // Address 8: sub x1, x1, x2      (LOOP START: x1 = x1 - 1)
        dut.IF_stage.instrmem.RAM[2] = 32'h402080b3;
        
        // Address 12: beq x1, x0, 8      (If x1 == 0, break out of loop -> Jump to PC 20)
        dut.IF_stage.instrmem.RAM[3] = 32'h00008463;
        
        // Address 16: beq x0, x0, -8     (Unconditional branch back to LOOP START at PC 8)
        dut.IF_stage.instrmem.RAM[4] = 32'hfe000ce3;
        
        // Address 20: addi x3, x0, 99    (END OF PROGRAM: x3 = 99)
        dut.IF_stage.instrmem.RAM[5] = 32'h06300193;

        // Fill the rest with NOPs (addi x0, x0, 0) to prevent undefined behavior
        for (int i = 6; i < 256; i++) begin
            dut.IF_stage.instrmem.RAM[i] = 32'h00000013;
        end

        // 3. Release Reset
        #15 rst_n = 1;

        // 4. Monitor the execution
        $display("      -----------------------------------------------------------------------------------------");
        $display("           Time |   PC   | Instruction | Pred Taken | Actual Taken | EX Flush |   x1   |   x3   |");
        $display("      -----------------------------------------------------------------------------------------");
        
        // Run for enough cycles to see the loop finish
        for (int i = 0; i < 35; i++) begin
            @(posedge clk);
            #1; // Delay slightly to sample updated values
            
            $display("%5t|%6h|%8h|        %b     |     %b    |       %b      |  %6d   |%6d |",
                     $time,
                     dut.IF_stage.pc_out,
                     dut.IF_stage.instr_out,
                     dut.IF_stage.predict_taken_out,
                     dut.EX_stage.ex_actual_taken,
                     dut.EX_stage.ex_flush,
                     dut.ID_stage.rf.rf[1],   // Monitor register x1 (Loop Counter)
                     dut.ID_stage.rf.rf[3]);  // Monitor register x3 (End of program flag)
        end
        
        $display("-----------------------------------------------------------------------------------------");
        $display("Simulation Finished.");
        $display("Observe 'EX Flush': It should trigger on the first 'beq x0, x0, -8' as the predictor learns.");
        $display("Subsequent loop iterations should have 'Pred Taken' = 1 and 'EX Flush' = 0.");
        
        $finish;
    end

endmodule