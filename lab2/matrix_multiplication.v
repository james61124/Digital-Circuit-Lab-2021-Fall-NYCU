//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/19 11:25:45
// Design Name: 
// Module Name: mmult
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

module mmult(
  input  clk,                      // Clock signal
  input  reset_n,                  // Reset signal (negative logic)
  input  enable,                   // Activation signal for matrix multiplication
  input  unsigned [0:9*8-1] A_mat, // A matrix
  input  unsigned [0:9*8-1] B_mat, // B matrix
  output valid,                    // Signals that the output is valid to read
  output reg [0:9*17-1] C_mat      // The result of A x B
);

reg [15:0] counter;
reg [0:23] col = {8'd0, 8'd17, 8'd34}; // Matrix column offsets
// 0000_0000_0001_0001_0010_0010
assign valid = (counter > 16)? 1 : 0;

always @(posedge clk)
  if (~reset_n || enable == 0)
    counter <= 0;
  else if (enable == 1)
    counter <= counter + 8;

always @(posedge clk)
  if (~reset_n)
    C_mat <= {9{17'h0}};
  else if (enable && counter <= 16) begin
    C_mat[(col[counter+:8]+  0)+:17] <=
      A_mat[ 0+:8] * B_mat[(counter +  0)+:8] +
      A_mat[ 8+:8] * B_mat[(counter + 24)+:8] +
      A_mat[16+:8] * B_mat[(counter + 48)+:8];
    C_mat[(col[counter+:8]+ 51)+:17] <=
      A_mat[24+:8] * B_mat[(counter +  0)+:8] +
      A_mat[32+:8] * B_mat[(counter + 24)+:8] +
      A_mat[40+:8] * B_mat[(counter + 48)+:8];
    C_mat[(col[counter+:8]+102)+:17] <=
      A_mat[48+:8] * B_mat[(counter +  0)+:8] +
      A_mat[56+:8] * B_mat[(counter + 24)+:8] +
      A_mat[64+:8] * B_mat[(counter + 48)+:8];
  end else
    C_mat <= C_mat;

endmodule
//    0~16     17~33      34~50  
//  51~67     68~84      85~101  
//102~118  119~135  136~152
