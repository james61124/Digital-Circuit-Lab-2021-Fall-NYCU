//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/22 17:23:12
// Design Name: 
// Module Name: Fulladder
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

/*
// ------------- A four-bit full adder ------------------------------
// ------------- A four-bit full adder ------------------------------
// ------------- A four-bit full adder ------------------------------
module half_adder(S,C,x,y);
    input x,y;
    output S,C;
    xor(S,x,y);
    and(C,x,y);
endmodule

module full_adder(S,C,x,y,z);
    output S,C;
    input x,y,z;
    wire S1,C1,C2;
    half_adder HA1(S1,C1,x,y);
    half_adder HA2(S, C2, S1, z);
    or (C, C2, C1);
endmodule 
*/

module SeqMultiplier(input wire clk, input wire enable,
input wire [7:0] A, input wire [7:0] B,
output wire [15:0] C);
    reg [15:0] prod;
    reg [7:0] mult;
    reg [3:0] counter;
    wire shift;
    assign C = prod;
    assign shift = |(counter^7);
    always @(posedge clk) begin
    if (!enable) begin
    mult <= B;
    prod <= 0;
    counter <= 0;
    end
else begin
mult <= mult << 1;
prod <= (prod + (A & {8{mult[7]}})) << shift;
counter <= counter + shift;
end
end
endmodule