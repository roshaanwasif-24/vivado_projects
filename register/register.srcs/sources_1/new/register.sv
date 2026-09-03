module register (
    input  logic [7:0] data,
    input  logic       enable,
    input  logic       clk,
    input  logic       rst_,
    output logic [7:0] out
);

  // Trigger on rising edge of clock or falling edge of reset
  always_ff @(posedge clk or negedge rst_) begin
    if (!rst_) begin
      out <= 8'b0;      // Asynchronous active-low reset
    end else if (enable) begin
      out <= data;      // Pass data to output when enabled
    end
  end

endmodule