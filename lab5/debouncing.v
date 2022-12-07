`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/02 01:27:02
// Design Name: 
// Module Name: debouncing
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


`timescale 1ns / 1ps

module debounce(input clk, input btn_input, output btn_output);

parameter DEBOUNCE_PERIOD = 2_000_000; /* 20 msec = (100,000,000*0.2) ticks @100MHz */

reg [$clog2(DEBOUNCE_PERIOD):0] counter;

assign btn_output = (counter == DEBOUNCE_PERIOD);

always@(posedge clk) begin
  if (btn_input == 0)
    counter <= 0;
  else
    counter <= counter + (counter != DEBOUNCE_PERIOD);
end

endmodule


