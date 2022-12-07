`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: arty_sd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The sample top module of lab 7: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT = 3'b010, S_MAIN_READ = 3'b011,
                 S_MAIN_DELAY = 3'b100,
                 S_MAIN_TAG  = 3'b111, S_MAIN_SHOW = 3'b101,
				 S_MAIN_CMPR = 3'b110;

// Declare system variables
wire btn_pressed;
wire btn_level;
reg  prev_btn_level;
reg  [2:0] P;
reg  [2:0] P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;


//my singal
reg[63:0]DLAB_TAG = "DLAB_TAG";
reg[63:0]DLAB_END = "DLAB_END";
reg[63:0]compare_the_buf;
reg[15:0]cnt_the;
wire text_bigin;
wire text_end;
wire the_flag;
wire char1,char5;
reg find_tag;
reg [9:0]cmpr_cnt;
wire [7:0]one_digit,ten_digit;
reg ascii_punctuation_table[127:0];
reg [15:0]count;
wire char6,char2,char3,char4,char7;
assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
// assign usr_led = {find_tag,P};
//in_buf_char
assign text_bigin = (compare_the_buf == DLAB_TAG) ? 1 : 0;
assign text_end   = (compare_the_buf == DLAB_END) ? 1 : 0;
assign the_flag   = ( (char6 && char2 && char3 && char4 && char7 )&& (compare_the_buf[55:32] != "TAG")&& P == S_MAIN_CMPR) ? 1 : 0;

assign char6 = (compare_the_buf[62:56]<65 || (compare_the_buf[62:56]>90 && compare_the_buf[62:56]<97) || compare_the_buf[62:56]>122) ? 1 : 0;
assign char2 = ((compare_the_buf[54:48]>=65 && compare_the_buf[54:48]<=90) || (compare_the_buf[54:48]>=97 && compare_the_buf[54:48]<=122)) ?1:0;
assign char3 = ((compare_the_buf[46:40]>=65 && compare_the_buf[46:40]<=90) || (compare_the_buf[46:40]>=97 && compare_the_buf[46:40]<=122)) ?1:0;
assign char4 = ((compare_the_buf[38:32]>=65 && compare_the_buf[38:32]<=90) || (compare_the_buf[38:32]>=97 && compare_the_buf[38:32]<=122)) ?1:0;
assign char7 = (compare_the_buf[30:24]<65 || (compare_the_buf[30:24]>90 && compare_the_buf[30:24]<97) || compare_the_buf[30:24]>122) ? 1 : 0;

assign ten_digit = cnt_the/10;
assign one_digit = cnt_the - ten_digit*10;
//set up punctuation table
always@(posedge clk)begin
  ascii_punctuation_table[0  ] <= 0;   ascii_punctuation_table[1  ] <= 0;   ascii_punctuation_table[2  ] <= 0;   ascii_punctuation_table[3  ] <= 0;
  ascii_punctuation_table[4  ] <= 0;   ascii_punctuation_table[5  ] <= 0;   ascii_punctuation_table[6  ] <= 0;   ascii_punctuation_table[7  ] <= 0;
  ascii_punctuation_table[8  ] <= 0;   ascii_punctuation_table[9  ] <= 0;   ascii_punctuation_table[10 ] <= 1;   ascii_punctuation_table[11 ] <= 0;
  ascii_punctuation_table[12 ] <= 0;   ascii_punctuation_table[13 ] <= 1;	ascii_punctuation_table[14 ] <= 0;	 ascii_punctuation_table[15 ] <= 0;	
  ascii_punctuation_table[16 ] <= 0;   ascii_punctuation_table[17 ] <= 0;	ascii_punctuation_table[18 ] <= 0;	 ascii_punctuation_table[19 ] <= 0;	
  ascii_punctuation_table[20 ] <= 0;   ascii_punctuation_table[21 ] <= 0;	ascii_punctuation_table[22 ] <= 0;	 ascii_punctuation_table[23 ] <= 0;	
  ascii_punctuation_table[24 ] <= 0;   ascii_punctuation_table[25 ] <= 0;	ascii_punctuation_table[26 ] <= 0;	 ascii_punctuation_table[27 ] <= 0;	
  ascii_punctuation_table[28 ] <= 0;   ascii_punctuation_table[29 ] <= 0;	ascii_punctuation_table[30 ] <= 0;	 ascii_punctuation_table[31 ] <= 1;	
  ascii_punctuation_table[32 ] <= 1;   ascii_punctuation_table[33 ] <= 1;	ascii_punctuation_table[34 ] <= 1;	 ascii_punctuation_table[35 ] <= 1;	
  ascii_punctuation_table[36 ] <= 1;   ascii_punctuation_table[37 ] <= 1;	ascii_punctuation_table[38 ] <= 1;	 ascii_punctuation_table[39 ] <= 1;	
  ascii_punctuation_table[40 ] <= 1;   ascii_punctuation_table[41 ] <= 1;	ascii_punctuation_table[42 ] <= 1;	 ascii_punctuation_table[43 ] <= 1;	
  ascii_punctuation_table[44 ] <= 1;   ascii_punctuation_table[45 ] <= 1;	ascii_punctuation_table[46 ] <= 1;	 ascii_punctuation_table[47 ] <= 1;	
  ascii_punctuation_table[48 ] <= 0;   ascii_punctuation_table[49 ] <= 0;	ascii_punctuation_table[50 ] <= 0;	 ascii_punctuation_table[51 ] <= 0;	
  ascii_punctuation_table[52 ] <= 0;   ascii_punctuation_table[53 ] <= 0;	ascii_punctuation_table[54 ] <= 0;	 ascii_punctuation_table[55 ] <= 0;	
  ascii_punctuation_table[56 ] <= 0;   ascii_punctuation_table[57 ] <= 0;	ascii_punctuation_table[58 ] <= 0;	 ascii_punctuation_table[59 ] <= 1;	
  ascii_punctuation_table[60 ] <= 1;   ascii_punctuation_table[61 ] <= 1;	ascii_punctuation_table[62 ] <= 1;	 ascii_punctuation_table[63 ] <= 1;	
  ascii_punctuation_table[64 ] <= 1;   ascii_punctuation_table[65 ] <= 0;	ascii_punctuation_table[66 ] <= 0;	 ascii_punctuation_table[67 ] <= 0;	
  ascii_punctuation_table[68 ] <= 0;   ascii_punctuation_table[69 ] <= 0;	ascii_punctuation_table[70 ] <= 0;	 ascii_punctuation_table[71 ] <= 0;	
  ascii_punctuation_table[72 ] <= 0;   ascii_punctuation_table[73 ] <= 0;	ascii_punctuation_table[74 ] <= 0;	 ascii_punctuation_table[75 ] <= 0;	
  ascii_punctuation_table[76 ] <= 0;   ascii_punctuation_table[77 ] <= 0;	ascii_punctuation_table[78 ] <= 0;	 ascii_punctuation_table[79 ] <= 0;	
  ascii_punctuation_table[80 ] <= 0;   ascii_punctuation_table[81 ] <= 0;	ascii_punctuation_table[82 ] <= 0;	 ascii_punctuation_table[83 ] <= 0;	
  ascii_punctuation_table[84 ] <= 0;   ascii_punctuation_table[85 ] <= 0;	ascii_punctuation_table[86 ] <= 0;	 ascii_punctuation_table[87 ] <= 0;	
  ascii_punctuation_table[88 ] <= 0;   ascii_punctuation_table[89 ] <= 0;	ascii_punctuation_table[90 ] <= 0;	 ascii_punctuation_table[91 ] <= 1;	
  ascii_punctuation_table[92 ] <= 1;   ascii_punctuation_table[93 ] <= 1;	ascii_punctuation_table[94 ] <= 1;	 ascii_punctuation_table[95 ] <= 1;	
  ascii_punctuation_table[96 ] <= 1;   ascii_punctuation_table[97 ] <= 0;	ascii_punctuation_table[98 ] <= 0;	 ascii_punctuation_table[99 ] <= 0;	
  ascii_punctuation_table[100] <= 0;   ascii_punctuation_table[101] <= 0;	ascii_punctuation_table[102] <= 0;	 ascii_punctuation_table[103] <= 0;	
  ascii_punctuation_table[104] <= 0;   ascii_punctuation_table[105] <= 0;	ascii_punctuation_table[106] <= 0;	 ascii_punctuation_table[107] <= 0;	
  ascii_punctuation_table[108] <= 0;   ascii_punctuation_table[109] <= 0;	ascii_punctuation_table[110] <= 0;	 ascii_punctuation_table[111] <= 0;	
  ascii_punctuation_table[112] <= 0;   ascii_punctuation_table[113] <= 0;	ascii_punctuation_table[114] <= 0;	 ascii_punctuation_table[115] <= 0;	
  ascii_punctuation_table[116] <= 0;   ascii_punctuation_table[117] <= 0;	ascii_punctuation_table[118] <= 0;	 ascii_punctuation_table[119] <= 0;	
  ascii_punctuation_table[120] <= 0;   ascii_punctuation_table[121] <= 0;	ascii_punctuation_table[122] <= 0;	 ascii_punctuation_table[123] <= 1;	
  ascii_punctuation_table[124] <= 1;   ascii_punctuation_table[125] <= 1;	ascii_punctuation_table[126] <= 1;	 ascii_punctuation_table[127] <= 0;
end

always@(posedge clk)begin
	DLAB_TAG <= "DLAB_TAG";
	DLAB_END <= "DLAB_END";
end
always @(posedge clk)begin
	if(~reset_n)
		find_tag <= 0;
	else if(text_bigin == 1)
		find_tag <= 1;
	else if(P == S_MAIN_IDLE)
		find_tag <= 0;
end

always @(posedge clk)begin
	if(~reset_n)
		cmpr_cnt <= 0;
	else if(P == S_MAIN_CMPR || P == S_MAIN_TAG)
		cmpr_cnt <=  (cmpr_cnt == 512) ? 512 : cmpr_cnt+1;//(btn_pressed2) ? cmpr_cnt+1 : cmpr_cnt;
	else 
		cmpr_cnt <= 0;
end

always @(posedge clk)begin
	if(~reset_n) begin
		cnt_the <= 0;
	end
	else if(P == S_MAIN_CMPR && the_flag) begin
		cnt_the <= cnt_the+1;
	end
	else if(P == S_MAIN_IDLE)begin
		cnt_the <= 0;
	end
end

always @(posedge clk)begin
	if(~reset_n) begin
		count <=0;
	end
	else if(P == S_MAIN_CMPR && (compare_the_buf[7:0]<65 || (compare_the_buf[7:0]>90 && compare_the_buf[7:0]<97) || compare_the_buf[7:0]>122)) begin
		count<=0;
	end
	else begin
	   count<=count+1;
	end
end

wire [7:0]in_buf_char;
assign in_buf_char = data_out; //¤p¼gÅÜ¤j¼g
always @(posedge clk)begin
	if(~reset_n)
		compare_the_buf <= 0;
	else if(P == S_MAIN_CMPR || P == S_MAIN_TAG)
		compare_the_buf <= {compare_the_buf[55:0],in_buf_char};
	else if(P == S_MAIN_IDLE)
		compare_the_buf <= 0;
end

assign char1 =  ascii_punctuation_table[compare_the_buf[62:56]];
assign char5 =  ascii_punctuation_table[compare_the_buf[30:24]];

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = (P == S_MAIN_CMPR || P == S_MAIN_TAG) ? cmpr_cnt[8:0] : sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
      if(sd_counter == 512 && find_tag!=1) P_next = S_MAIN_TAG;
	  else if(sd_counter == 512 && find_tag == 1)P_next = S_MAIN_CMPR;
      else P_next = S_MAIN_READ;
	S_MAIN_TAG:
	  if(text_bigin)P_next = S_MAIN_CMPR;
	  else if(cmpr_cnt == 10)P_next = S_MAIN_WAIT;
	  else P_next = S_MAIN_TAG;
	S_MAIN_CMPR:
	  if(text_end)P_next = S_MAIN_SHOW;
	  else if(cmpr_cnt == 512)P_next = S_MAIN_WAIT;
	  else P_next = S_MAIN_CMPR;  	  
    S_MAIN_SHOW:
	  P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end
// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(posedge clk) begin
  rd_req <= (P == S_MAIN_WAIT);
  rd_addr <= blk_addr;
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if((P == S_MAIN_TAG && P_next == S_MAIN_WAIT) || (P == S_MAIN_CMPR && P_next == S_MAIN_WAIT))blk_addr <= blk_addr+1;  // In lab 6, change this line to scan all blocks
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n)
    sd_counter <= 0;
  else if (P == S_MAIN_READ && sd_valid)
    sd_counter <= sd_counter + 1;
  else if (P == S_MAIN_TAG || P == S_MAIN_CMPR)
    sd_counter <= 0;
  // else if (P == S_MAIN_WAIT)
    // sd_counter <= 0;
end

// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end else if (P == S_MAIN_TAG) begin
    row_A <= "SD block 8192:  ";
    row_B <= { "Byte ",
               sram_addr[8] + "0",
               ((sram_addr[7:4] > 9)? "7" : "0") + sram_addr[7:4],
               ((sram_addr[3:0] > 9)? "7" : "0") + sram_addr[3:0],
               "h = ",
               ((data_out[7:4] > 9)? "7" : "0") + data_out[7:4],
               ((data_out[3:0] > 9)? "7" : "0") + data_out[3:0], "h." };
  end
  else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end else if (P == S_MAIN_SHOW) begin
    row_A[127:80] <= "Found ";
    row_A[79:72] <= ((cnt_the[15:12] > 9)? "7" : "0") + cnt_the[15:12];
    row_A[71:64] <= ((cnt_the[11:8] > 9)? "7" : "0") + cnt_the[11:8];
    row_A[63:56] <= ((cnt_the[7:4] > 9)? "7" : "0") + cnt_the[7:4];
    row_A[55:48] <= ((cnt_the[3:0] > 9)? "7" : "0") + cnt_the[3:0];
    row_A[47:0] <= " words";
    row_B <= "in the test file";
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule

