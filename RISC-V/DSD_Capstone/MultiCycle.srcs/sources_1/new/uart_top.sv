`timescale 1ns / 1ps

module uart_top (
    input  logic clk, rst_n, rx_pin,
    output logic tx_pin,
    input  logic [7:0]  bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic bus_we, bus_re,
    output logic [31:0] bus_rdata
);
    logic tx_start, tx_busy, rx_valid, data_ready;
    logic [7:0] rx_data;

    uart_tx u_tx (.clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(bus_wdata[7:0]), .tx_busy(tx_busy), .tx_out(tx_pin));
    uart_rx u_rx (.clk(clk), .rst_n(rst_n), .rx_in(rx_pin), .rx_data(rx_data), .rx_valid(rx_valid));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_ready <= 1'b0;
        else if (rx_valid) data_ready <= 1'b1;  
        else if (bus_re && (bus_addr == 8'h00)) data_ready <= 1'b0; 
    end

    always_comb begin
        tx_start = (bus_we && (bus_addr == 8'h00)) ? 1'b1 : 1'b0;
        bus_rdata = 32'b0;
        if (bus_re) begin
            if (bus_addr[2] == 1'b1) bus_rdata = {30'b0, data_ready, tx_busy}; 
            else                     bus_rdata = {24'b0, rx_data};              
        end
    end
endmodule