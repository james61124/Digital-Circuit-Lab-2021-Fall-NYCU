`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish_clock;
reg  [31:0] fish_clock2;
reg  [31:0] fish_clock3;
reg  [31:0] fish_clock4;
wire [9:0]  pos;
wire [9:0]  pos1;
wire [9:0]  pos2;
wire [9:0]  pos3;
wire [9:0]  pos4;
wire fish_region;
wire fish_region1;
wire fish_region2;
wire fish_region3;
wire fish_region4;
wire [1:0]  fish_number;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [16:0] sram_addr_fish1;
wire [16:0] sram_addr_fish2;
wire [16:0] sram_addr_fish3;
wire [16:0] sram_addr_fish4;
wire [11:0] data_in;
wire [11:0] data_out, data_out_fish1,data_out_fish2,data_out_fish3,data_out_fish4;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)

  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;
reg  [17:0] pixel_addr1;
reg  [17:0] pixel_addr2;
reg  [17:0] pixel_addr3;
reg  [17:0] pixel_addr4;

reg [3:0] v1;
reg [3:0] v2;
reg [3:0] v3;
reg [3:0] v4;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH_VPOS1   = 64; // Vertical location of the fish in the sea image.
localparam FISH_VPOS2   = 128;
localparam FISH_VPOS3   = 200;
localparam FISH_VPOS4   = 150;
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_W2      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam FISH_H2      = 44; // Height of the fish.
localparam FISH_W3      = 64; // Width of the fish.
localparam FISH_H3      = 32; // Height of the fish.
localparam FISH_W4      = 64; // Width of the fish.
localparam FISH_H4     = 32; // Height of the fish.
reg [17:0] fish_addr[0:2];   // Address array for up to 8 fish images.
reg [17:0] fish_addr2[0:2];   // Address array for up to 8 fish images.
reg [17:0] fish_addr3[0:2];   // Address array for up to 8 fish images.
reg [17:0] fish_addr4[0:2];   // Address array for up to 8 fish images.

wire [3:0]   btn_level, btn_pressed;
reg  [3:0]   prev_btn_level;
reg  [2:0]   pwm_dc = 3'b010; //  5%, 25%, 50%, 75% 100%
reg  [21:0]  pwm_counter;
reg signed [3:0]   counter;
wire switch;

//assign usr_led = {4{switch}} & counter;
//assign switch = (pwm_counter < period_on[pwm_dc])? 1 : 0;


debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);

debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);

always @(posedge clk) begin
  if (~reset_n) begin
    prev_btn_level <= 4'b1111;
  end
  else begin
    prev_btn_level <= btn_level;
  end
end

assign btn_pressed = (btn_level & ~prev_btn_level);

always@ (posedge clk) begin
if (~reset_n)begin
  v1 <=2;
  v2 <=3;
end
else if (btn_pressed[1] && v2<=10 )
  v2<=v2+1;
else if (btn_pressed[2] && v2>0 )
  v2<=v2-1;
end

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 🙁
initial begin
  fish_addr[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr[1] = FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] = FISH_W*FISH_H*2;
  fish_addr[3] = FISH_W*FISH_H*3;
  fish_addr[4] = FISH_W*FISH_H*4;
  fish_addr[5] = FISH_W*FISH_H*5;
  fish_addr[6] = FISH_W*FISH_H*6;
  fish_addr[7] = FISH_W*FISH_H*7;

  fish_addr2[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr2[1] = FISH_W2*FISH_H2; /* Addr for fish image #2 */
  fish_addr2[2] = FISH_W2*FISH_H2*2;
  fish_addr2[3] = FISH_W2*FISH_H2*3;
  fish_addr2[4] = FISH_W2*FISH_H2*4;
  fish_addr2[5] = FISH_W2*FISH_H2*5;
  fish_addr2[6] = FISH_W2*FISH_H2*6;
  fish_addr2[7] = FISH_W2*FISH_H2*7;

  fish_addr3[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr3[1] = FISH_W3*FISH_H3; /* Addr for fish image #2 */
  fish_addr3[2] = FISH_W3*FISH_H3*2;
  fish_addr3[3] = FISH_W3*FISH_H3*3;
  fish_addr3[4] = FISH_W3*FISH_H3*4;
  fish_addr3[5] = FISH_W3*FISH_H3*5;
  fish_addr3[6] = FISH_W3*FISH_H3*6;
  fish_addr3[7] = FISH_W3*FISH_H3*7;

  fish_addr4[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr4[1] = FISH_W4*FISH_H4; /* Addr for fish image #2 */
  fish_addr4[2] = FISH_W4*FISH_H4*2;
  fish_addr4[3] = FISH_W4*FISH_H4*3;
  fish_addr4[4] = FISH_W4*FISH_H4*4;
  fish_addr4[5] = FISH_W4*FISH_H4*5;
  fish_addr4[6] = FISH_W4*FISH_H4*6;
  fish_addr4[7] = FISH_W4*FISH_H4*7;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);



// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram_fish1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish1), .data_i(data_in), .data_o(data_out_fish1));
sram_fish2 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W2*FISH_H2*8))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish2), .data_i(data_in), .data_o(data_out_fish2));
sram_fish3 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W3*FISH_H3*8))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish3), .data_i(data_in), .data_o(data_out_fish3));
sram_fish4 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W4*FISH_H4*8))
  ram4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish4), .data_i(data_in), .data_o(data_out_fish4));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr_fish1 = pixel_addr1;
assign sram_addr_fish2 = pixel_addr2;
assign sram_addr_fish3 = pixel_addr3;
assign sram_addr_fish4 = pixel_addr4;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; // the x position of the right edge of the fish image
assign pos1 = fish_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos2 = fish_clock2[30:19];
assign pos3 = fish_clock3[31:20];
assign pos4 = fish_clock4[31:20];



always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)
    fish_clock <= 0;
  else
    fish_clock <= fish_clock + v1;
end

always @(posedge clk) begin
  if (~reset_n || pos2 > 2*(VBUF_W + FISH_W2)+250)
    fish_clock2 <= 0;
  else
    fish_clock2 <= fish_clock2 + v2;
end

always @(posedge clk) begin
  if (~reset_n || pos3 > 2*(VBUF_W + FISH_W3)+250)
    fish_clock3 <= 0;
  else
    fish_clock3 <= fish_clock3 + 1;
end

always @(posedge clk) begin
  if (~reset_n || pos4 > 2*(VBUF_W + FISH_W4)+250)
    fish_clock4 <= 0;
  else
    fish_clock4 <= fish_clock4 + 5;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region =
           pixel_y >= (FISH_VPOS<<1) && pixel_y < (FISH_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1;
assign fish_region1 =
           pixel_y >= (FISH_VPOS1<<1) && pixel_y < (FISH_VPOS1+FISH_H)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1;
assign fish_region2 =
           pixel_y >= (FISH_VPOS2<<1) && pixel_y < (FISH_VPOS2+FISH_H2)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
assign fish_region3 =
           pixel_y >= (FISH_VPOS3<<1) && pixel_y < (FISH_VPOS3+FISH_H3)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;
assign fish_region4 =
           pixel_y >= (FISH_VPOS4<<1) && pixel_y < (FISH_VPOS4+FISH_H4)<<1 &&
           (pixel_x + 127) >= pos4 && pixel_x < pos4 + 1;
assign fish_number = (fish_region1==1) ? 1 : (fish_region2==1) ? 2 : (fish_region3==1) ? 3 : (fish_region4==1) ? 4 : 0;

always @ (posedge clk) begin
  if (~reset_n)begin
    pixel_addr <= 0;
    pixel_addr1 <= 0;
    pixel_addr2 <= 0;
    pixel_addr3 <= 0;
    pixel_addr4 <= 0;
  // else if (fish_region1 && data_out_fish1!=12'h0f0)
  //   pixel_addr <= fish_addr[fish_clock[25:23]] +
  //                 ((pixel_y>>1)-FISH_VPOS)*FISH_W +
  //                 ((pixel_x +(FISH_W*2-1)-pos)>>1);
  //   // Scale up a 320x240 image for the 640x480 display.
  //   // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
  end
  else begin
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    pixel_addr1 <= fish_addr[fish_clock[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS)*FISH_W +
                  ((pixel_x +(FISH_W*2-1)-pos)>>1);
    pixel_addr2 <= fish_addr2[fish_clock2[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS2)*FISH_W2 +
                  ((pixel_x +(FISH_W2*2-1)-pos2)>>1);
    pixel_addr3 <= fish_addr3[fish_clock3[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 +
                  ((pixel_x +(FISH_W3*2-1)-pos3)>>1);
    pixel_addr4 <= fish_addr4[fish_clock4[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS4)*FISH_W4 +
                  ((pixel_x +(FISH_W4*2-1)-pos4)>>1);

  end
end

// always @ (posedge clk) begin
//   if (~reset_n)
//     pixel_addr2 <= 0;
//   else if (fish_region2 && data_out_fish2!=12'h0f0)
//     pixel_addr2 <= fish_addr2[fish_clock2[25:23]] +
//                   ((pixel_y>>1)-FISH_VPOS2)*FISH_W2 +
//                   ((pixel_x +(FISH_W2*2-1)-pos2)>>1);
//     // Scale up a 320x240 image for the 640x480 display.
//     // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
//   else pixel_addr2 <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
// end

// always @ (posedge clk) begin
//   if (~reset_n)
//     pixel_addr3 <= 0;
//   else if (fish_region3 && data_out_fish3!=12'h0f0)
//     pixel_addr3 <= fish_addr3[fish_clock3[25:23]] +
//                   ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 +
//                   ((pixel_x +(FISH_W3*2-1)-pos3)>>1);
//     // Scale up a 320x240 image for the 640x480 display.
//     // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
//   else pixel_addr3 <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
// end



// always @ (posedge clk) begin
//   if (~reset_n)
//     sram_addr_fish1 <= 0;
//   else if (fish_region1==1 && data_out_fish1!=12'h0f0)
//     sram_addr_fish1 <= fish_addr[fish_clock[25:23]] +
//                   ((pixel_y>>1)-FISH_VPOS1)*FISH_W +
//                   ((pixel_x +(FISH_W*2-1)-pos1)>>1);
//   else
//     // Scale up a 320x240 image for the 640x480 display.
//     // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
//     sram_addr_fish1 <= 0;
// end

// always @ (posedge clk) begin
//   if (~reset_n)
//     sram_addr_fish2 <= 0;
//   else if (fish_region2==1 && data_out_fish2!=12'h0f0)
//     sram_addr_fish2 <= fish_addr2[fish_clock2[25:23]] +
//                   ((pixel_y>>1)-FISH_VPOS2)*FISH_W2 +
//                   ((pixel_x +(FISH_W2*2-1)-pos2)>>1);
//   else
//     // Scale up a 320x240 image for the 640x480 display.
//     // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
//     sram_addr_fish2 <= 0;
// end

// always @ (posedge clk) begin
//   if (~reset_n)
//     sram_addr_fish3 <= 0;
//   else if (fish_region3==1 && data_out_fish3!=12'h0f0)
//     sram_addr_fish3 <= fish_addr3[fish_clock3[25:23]] +
//                   ((pixel_y>>1)-FISH_VPOS3)*FISH_W3 +
//                   ((pixel_x +(FISH_W3*2-1)-pos3)>>1);
//   else
//     // Scale up a 320x240 image for the 640x480 display.
//     // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
//     sram_addr_fish3 <= 0;
// end

// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end


always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if (fish_number==0)
    rgb_next = data_out;
  if(fish_region1==1)begin
    //rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    if (data_out_fish1==12'h0f0)
      rgb_next = data_out;
    else
      rgb_next = data_out_fish1;
  end
  if(fish_region4 && !fish_region2)begin
    //rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    if (data_out_fish4==12'h0f0)
      rgb_next = data_out;
    else
      rgb_next = data_out_fish4;
  end
  if(fish_region2 && fish_region4)begin
    if (data_out_fish2==12'h0f0 && data_out_fish4==12'h0f0) rgb_next = data_out;
    else if(data_out_fish4==12'h0f0) rgb_next = data_out_fish2;
    else rgb_next = data_out_fish4;
  end
  if(fish_region2 && !fish_region4)begin
    //rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    if (data_out_fish2==12'h0f0)
      rgb_next = data_out;
    else
      rgb_next = data_out_fish2;
  end
  if(fish_region3==1 && !fish_region4)begin
    //rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
    if (data_out_fish3==12'h0f0)
      rgb_next = data_out;
    else
      rgb_next = data_out_fish3;
  end
  
  
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule