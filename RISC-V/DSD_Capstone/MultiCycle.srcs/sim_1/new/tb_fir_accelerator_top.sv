`timescale 1ns / 1ps

module tb_fir_accelerator_top();

    logic        clk;
    logic        rst_n;
    logic [7:0]  bus_addr;
    logic [31:0] bus_wdata;
    logic        bus_we;
    logic        bus_re;
    logic [31:0] bus_rdata;
    logic        bus_ready;

    always #5 clk = ~clk;

    fir_accelerator_top #(
        .ADDR_WIDTH(8),
        .BUS_WIDTH(32)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_we(bus_we),
        .bus_re(bus_re),
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready)
    );

    task write_fir_sample(input [15:0] sample);
        begin
            @(posedge clk);
            bus_addr  = 8'h00;
            bus_wdata = {16'b0, sample};
            bus_we    = 1'b1;
            bus_re    = 1'b0;
            
            @(posedge clk);
            bus_we    = 1'b0; 
            bus_wdata = 32'b0;
            
            $display("[%0t ns] Sent Input Sample: 0x%04X to FIR Coprocessor", $time, sample);
        end
    endtask

    task wait_for_fir_done();
        begin
            logic [31:0] status = 32'b0;
            
            while (status[0] == 1'b0) begin
                @(posedge clk);
                bus_addr = 8'h08; 
                bus_we   = 1'b0;
                bus_re   = 1'b1;
                
                @(posedge clk);
                status   = bus_rdata;
                bus_re   = 1'b0;
                
                repeat(2) @(posedge clk);
            end
            
            $display("[%0t ns] FIR Filter processing complete! Status Ready.", $time);
        end
    endtask

    task read_fir_result(output [31:0] result);
        begin
            @(posedge clk);
            bus_addr = 8'h04; 
            bus_we   = 1'b0;
            bus_re   = 1'b1;
            
            @(posedge clk);
            result   = bus_rdata;
            bus_re   = 1'b0; 
            
            $display("[%0t ns] Read Filtered Output Result: 0x%08X", $time, result);
        end
    endtask

    initial begin
        clk       = 1'b0;
        rst_n     = 1'b0; 
        bus_addr  = 8'h00;
        bus_wdata = 32'b0;
        bus_we    = 1'b0;
        bus_re    = 1'b0;

        #100;
        rst_n = 1'b1;   
        
        #50;

        $display("[$] Starting Isolated FIR Accelerator Verification...");

        write_fir_sample(16'h03E8); 
        
        wait_for_fir_done();
        
        begin
            logic [31:0] filtered_val;
            read_fir_result(filtered_val);
        end

        #100;
        write_fir_sample(16'h07D0); 
        
        wait_for_fir_done();
        
        begin
            logic [31:0] filtered_val2;
            read_fir_result(filtered_val2);
        end

        #500;
        $display("[$] Isolated FIR Testbench Completed Successfully.");
        $finish;
    end

endmodule