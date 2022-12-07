`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/10 22:22:12
// Design Name: 
// Module Name: alu_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    output reg [7:0] alu_out, 
    input  [7:0] accum, data, 
    input [2:0] opcode, 
    output zero, 
    input clk, reset
);
assign zero=(accum == 8'b0) ? 1'b1 : 1'b0 ;
always @(posedge clk)begin
    if(reset)
       alu_out<=0;
    //else 
    case(opcode)
        3'b000 : assign alu_out = accum;
        3'b001 : assign alu_out = accum+data;
        3'b010 : assign alu_out = accum-data;
        3'b011 : assign alu_out = accum&data;
        3'b100 : assign alu_out = accum^data;
        3'b101 : assign alu_out = (accum[7]==0)?accum:-accum;
        3'b110 : assign alu_out = accum*data;
        3'b111 : assign alu_out = data;
        default alu_out<=8'b00000000;
    endcase
end
endmodule
