`timescale 1ns / 1ps

// ==========================================
// Module: Top-Level SoC Testbench
// Description: Comprehensive verification testbench 
//              simulating UART packet transmission and 
//              capturing the 32-bit FIR filtered response.
// ==========================================
module tb_top();

    logic        clk;
    logic        reset;
    logic        uart_rx;
    logic        uart_tx;

    always #5 clk = ~clk;

    top uut (
        .clk(clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 1'b0;
            #(8680);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(8680);
            end

            uart_rx = 1'b1;
            #(8680);
            
            #(1000);
        end
    endtask

    task receive_uart_packet(output [31:0] packet);
        logic [7:0] fetched_bytes [3:0];
        integer b, i;
        begin
            packet = 32'b0;
            
            for (b = 0; b < 4; b = b + 1) begin
                @(negedge uart_tx);
                
                #(4340);
                
                fetched_bytes[b] = 8'b0;
                for (i = 0; i < 8; i = i + 1) begin
                    #(8680);
                    fetched_bytes[b][i] = uart_tx;
                end
                
                #(8680);
            end
            
            packet = {fetched_bytes[3], fetched_bytes[2], fetched_bytes[1], fetched_bytes[0]};
            $display("[%0t ns] Received 32-bit FIR Output Packet: 0x%08X", $time, packet);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        uart_rx = 1'b1; 

        #100;
        reset = 1'b0;   
        
        #500;

        $display("[$] Starting SoC FIR Verification Testbench...");

        $display("[$] Sending Byte 1: 0x48");
        send_uart_byte(8'h48);

        $display("[$] Sending Byte 2: 0x69");
        send_uart_byte(8'h69);

        begin
            logic [31:0] result_packet;
            receive_uart_packet(result_packet);
        end

        #50000;
        $display("[$] Testbench sequence completed successfully.");
        $finish;
    end

endmodule