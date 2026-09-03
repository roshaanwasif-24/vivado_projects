`timescale 1ns / 1ps

module priority_encoder_4to1(
input [3:0] In_a,
output reg [1:0] Out_y
    );
    
  always@(In_a)
  begin
  if(In_a[3] == 1'b1)
  Out_y = 2'b11;
  
 else if(In_a[2] ==1'b1)
  Out_y = 2'b10;
  
 else if(In_a[1] ==1'b1)
    Out_y = 2'b01;
    
  else
      Out_y = 2'b00;
  end
endmodule
