`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/10/10 16:10:38
// Design Name: UART I/O example for Arty
// Module Name: lab6
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_READ = 1, S_MAIN_CAL = 2,
                 S_MAIN_REPLY = 3, S_MAIN_SHOW = 4, S_MAIN_END = 5;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam READ_DELAY = 64;
localparam CAL_DELAY = 4;
localparam REPLY_DELAY = 4;

localparam REPLY_STR  = 0; // starting index of the hello message
localparam REPLY_LEN  = 169; // length of the hello message
localparam MEM_SIZE = REPLY_LEN;
// declare system variables
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [$clog2(READ_DELAY):0] read_counter;
reg [$clog2(CAL_DELAY):0] cal_counter;
reg [$clog2(REPLY_DELAY):0] reply_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg [1:0] j = 0;

reg  [0:REPLY_LEN*8-1]  msg = { "\015\012The matrix multiplication result is:\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012", 8'h00 };

reg  [11:0] user_addr;
reg  [7:0]  user_data;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;

sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3];
assign sram_en = (P == S_MAIN_INIT || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.

reg [15:0] a [0:15];
reg [15:0] b [0:15];
reg [31:0] c [0:15];

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//


// Combinational I/O logics of the top-level system
assign usr_led = P;

// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".

always @(posedge clk) begin
  if (P == S_MAIN_INIT) 
    if (init_counter < REPLY_LEN)
      data[init_counter] = msg[init_counter * 8 +: 8]; 

  if (P == S_MAIN_REPLY) begin
    if (reply_counter < 4) begin
      
      data[42 + reply_counter * 32] = ((c[0 + reply_counter][19:16] > 9)? "7" : "0") + c[0 + reply_counter][19:16];
      data[43 + reply_counter * 32] = ((c[0 + reply_counter][15:12] > 9)? "7" : "0") + c[0 + reply_counter][15:12];
      data[44 + reply_counter * 32] = ((c[0 + reply_counter][11:8] > 9)? "7" : "0") + c[0 + reply_counter][11:8];
      data[45 + reply_counter * 32] = ((c[0 + reply_counter][7:4] > 9)? "7" : "0") + c[0 + reply_counter][7:4];
      data[46 + reply_counter * 32] = ((c[0 + reply_counter][3:0] > 9)? "7" : "0") + c[0 + reply_counter][3:0];
      
      data[49 + reply_counter * 32] = ((c[4 + reply_counter][19:16] > 9)? "7" : "0") + c[4 + reply_counter][19:16];
      data[50 + reply_counter * 32] = ((c[4 + reply_counter][15:12] > 9)? "7" : "0") + c[4 + reply_counter][15:12];
      data[51 + reply_counter * 32] = ((c[4 + reply_counter][11:8] > 9)? "7" : "0") + c[4 + reply_counter][11:8];
      data[52 + reply_counter * 32] = ((c[4 + reply_counter][7:4] > 9)? "7" : "0") + c[4 + reply_counter][7:4];
      data[53 + reply_counter * 32] = ((c[4 + reply_counter][3:0] > 9)? "7" : "0") + c[4 + reply_counter][3:0];

      data[56 + reply_counter * 32] = ((c[8 + reply_counter][19:16] > 9)? "7" : "0") + c[8 + reply_counter][19:16];
      data[57 + reply_counter * 32] = ((c[8 + reply_counter][15:12] > 9)? "7" : "0") + c[8 + reply_counter][15:12];
      data[58 + reply_counter * 32] = ((c[8 + reply_counter][11:8] > 9)? "7" : "0") + c[8 + reply_counter][11:8];
      data[59 + reply_counter * 32] = ((c[8 + reply_counter][7:4] > 9)? "7" : "0") + c[8 + reply_counter][7:4];
      data[60 + reply_counter * 32] = ((c[8 + reply_counter][3:0] > 9)? "7" : "0") + c[8 + reply_counter][3:0];

      data[63 + reply_counter * 32] = ((c[12 + reply_counter][19:16] > 9)? "7" : "0") + c[12 + reply_counter][19:16];
      data[64 + reply_counter * 32] = ((c[12 + reply_counter][15:12] > 9)? "7" : "0") + c[12 + reply_counter][15:12];
      data[65 + reply_counter * 32] = ((c[12 + reply_counter][11:8] > 9)? "7" : "0") + c[12 + reply_counter][11:8];
      data[66 + reply_counter * 32] = ((c[12 + reply_counter][7:4] > 9)? "7" : "0") + c[12 + reply_counter][7:4];
      data[67 + reply_counter * 32] = ((c[12 + reply_counter][3:0] > 9)? "7" : "0") + c[12 + reply_counter][3:0];
      
    end
      reply_counter <= reply_counter + 1;
  end
  else
    reply_counter <= 0;
end

always @(posedge clk) begin
  if (~reset_n) P = S_MAIN_INIT;
  else P = P_next;
end

always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
	   if (init_counter < INIT_DELAY) P_next = S_MAIN_INIT;
		else P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for <Enter> key.
      if (read_counter < READ_DELAY) P_next = S_MAIN_READ;
      else P_next = S_MAIN_CAL;
    S_MAIN_CAL:
      if (cal_counter < CAL_DELAY) P_next = S_MAIN_CAL;
      else P_next = S_MAIN_REPLY;
    S_MAIN_REPLY: // Print the hello message.
      if (reply_counter < REPLY_DELAY) P_next = S_MAIN_REPLY;
      else P_next = S_MAIN_SHOW;
    S_MAIN_SHOW:
      if (print_done) P_next = S_MAIN_END;
      else P_next = S_MAIN_SHOW;
    S_MAIN_END:
      P_next = S_MAIN_END;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable = (P == S_MAIN_REPLY && P_next == S_MAIN_SHOW);
assign print_done = (tx_byte == 8'h0);

// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;

  if (P == S_MAIN_READ) begin
    if (read_counter % 2 == 0) begin
      user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;
    end
    else begin
      if (read_counter < 32)
        a[read_counter / 2] <= user_data;
      else
        b[read_counter / 2 - 16] <= user_data;
    end
    read_counter <= read_counter + 1;
  end
  else begin
    read_counter <= 0;
    user_addr <= 0;
  end

  if (P == S_MAIN_CAL) begin
    if (cal_counter < CAL_DELAY) begin
      c[0 + cal_counter] =  a[0 + cal_counter] * b[0] + a[4 + cal_counter] * b[1] + a[8 + cal_counter] * b[2] + a[12 + cal_counter] * b[3];
      c[4 + cal_counter] =  a[0 + cal_counter] * b[4] + a[4 + cal_counter] * b[5] + a[8 + cal_counter] * b[6] + a[12 + cal_counter] * b[7];
      c[8 + cal_counter] =  a[0 + cal_counter] * b[8] + a[4 + cal_counter] * b[9] + a[8 + cal_counter] * b[10] + a[12 + cal_counter] * b[11];
      c[12 + cal_counter] = a[0 + cal_counter] * b[12] + a[4 + cal_counter] * b[13] + a[8 + cal_counter] * b[14] + a[12 + cal_counter] * b[15]; 
    end
    cal_counter <= cal_counter + 1;
  end
  else
    cal_counter <= 0;
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q = S_UART_IDLE;
  else Q = Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  = data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= REPLY_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end

always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end

endmodule
