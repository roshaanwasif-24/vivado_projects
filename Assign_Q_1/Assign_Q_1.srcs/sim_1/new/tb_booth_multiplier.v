`timescale 1ns / 1ps

module tb_booth_multiplier;

    // --- Parameters ---
    localparam CLK_PERIOD = 20; // 50 MHz clock

    // --- TB Registers ---
    reg clk_50mhz;
    reg reset;
    reg start;
    reg signed [15:0] Multiplicand_in;
    reg signed [15:0] Multiplier_in;

    // --- DUT Wires ---
    wire done;
    wire signed [31:0] Product;

    // --- Instantiate the DUT ---
    booth_multiplier_16bit dut (
        .clk_50mhz(clk_50mhz),
        .reset(reset),
        .start(start),
        .Multiplicand_in(Multiplicand_in),
        .Multiplier_in(Multiplier_in),
        .done(done),
        .Product(Product)
    );

    // --- Clock Generator ---
    always begin
        clk_50mhz = 1'b0;
        #(CLK_PERIOD / 2);
        clk_50mhz = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // --- Test Task ---
    task run_test;
        input signed [15:0] m_in;
        input signed [15:0] q_in;
        input signed [31:0] p_expected;
        begin
            $display("-----------------------------------------------");
            $display("[TEST] %0d * %0d", m_in, q_in);
            
            Multiplicand_in = m_in;
            Multiplier_in = q_in;
            
            start = 1'b1;
            repeat(50) @(posedge clk_50mhz);
            start = 1'b0;
            
            @(posedge done);
            #1; // wait for Product to stabilize
            
            if (Product === p_expected)
                $display("  [PASS] Result: %0d", Product);
            else
                $error("  [FAIL] Result: %0d, Expected: %0d", Product, p_expected);
            
            #(10 * CLK_PERIOD);
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // 1. Initialize and Reset
        reset = 1'b1;
        start = 1'b0;
        Multiplicand_in = 0;
        Multiplier_in = 0;
        
        #(10 * CLK_PERIOD);
        reset = 1'b0;
        #(10 * CLK_PERIOD);
        
        // --- Test Cases ---
        run_test(16'sd2507, 16'sd2435, 32'sd40650867);
        run_test(16'sd1234, 16'sd5678, 32'sd7006652);
        run_test(16'sd32767, 16'sd32767, 32'sd1073676289);
        run_test(-16'sd32768, -16'sd32768, 32'sd1073741824);
        run_test(16'sd32767, -16'sd32768, -32'sd1073709056);
        run_test(-16'sd12345, 16'sd6789, -32'sd83810205);
        run_test(-16'sd27000, 16'sd0, 32'sd0);
        run_test(16'sd30000, -16'sd1, -32'sd30000);
        
        $display("-----------------------------------------------");
        $display("All tests completed.");
       $stop;
    end

endmodule
