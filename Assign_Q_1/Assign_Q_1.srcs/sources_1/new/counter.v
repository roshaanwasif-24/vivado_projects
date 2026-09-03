// 3-bit Binary Counter using T Flip-Flops
module tff_3bit_counter (
    input wire clk,
    input wire reset,
    output reg [2:0] q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 3'b000;
        else begin
            q[0] <= ~q[0];                        // T = 1 for LSB
            q[1] <= q[1] ^ q[0];                  // T = q0
            q[2] <= q[2] ^ (q[0] & q[1]);         // T = q0 & q1
        end
    end

endmodule
