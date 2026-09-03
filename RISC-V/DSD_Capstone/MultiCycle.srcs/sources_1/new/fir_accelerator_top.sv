`timescale 1ns / 1ps

module fir_accelerator_top #(
    parameter int ADDR_WIDTH = 8,
    parameter int BUS_WIDTH  = 32
)(
    input  logic clk, rst_n,
    input  logic [ADDR_WIDTH-1:0] bus_addr,
    input  logic [BUS_WIDTH-1:0]  bus_wdata,
    input  logic                  bus_we, bus_re,
    output logic [BUS_WIDTH-1:0]  bus_rdata,
    output logic                  bus_ready
);
    logic        s_axis_tvalid, s_axis_tready, m_axis_tvalid, status_done;
    logic [15:0] s_axis_tdata;
    logic [31:0] m_axis_tdata, result_reg; 

    fir_compiler_0 u_fir_ip (
        .aclk(clk), .s_axis_data_tvalid(s_axis_tvalid), .s_axis_data_tready(s_axis_tready),
        .s_axis_data_tdata(s_axis_tdata), .m_axis_data_tvalid(m_axis_tvalid), .m_axis_data_tdata(m_axis_tdata)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tvalid <= 1'b0; s_axis_tdata  <= 16'b0;
        end else begin
            if (bus_we && (bus_addr == 8'h00)) begin
                s_axis_tdata  <= bus_wdata[15:0];
                s_axis_tvalid <= 1'b1; 
            end else if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tvalid <= 1'b0; 
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0; status_done <= 1'b0;
        end else begin
            if (m_axis_tvalid) begin
                result_reg <= m_axis_tdata; status_done <= 1'b1; 
            end 
            else if (bus_re && (bus_addr == 8'h04)) begin
                status_done <= 1'b0;
            end
        end
    end

    always_comb begin
        bus_rdata = 32'b0; bus_ready = 1'b0;
        if (bus_re) begin
            bus_ready = 1'b1;
            case (bus_addr)
                8'h04: bus_rdata = result_reg;                  
                8'h08: bus_rdata = {31'b0, status_done};         
                default: bus_rdata = 32'b0;
            endcase
        end else if (bus_we) bus_ready = 1'b1;
    end
endmodule