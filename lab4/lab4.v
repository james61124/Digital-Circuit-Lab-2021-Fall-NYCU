`timescale 1ns / 1ps

module lab4(
  input  clk,            
  input  reset_n,        
  input  [3:0] usr_btn,  // pushbuttons
  output [3:0] usr_led   // LED
);

wire [3:0]   btn_level, btn_pressed;
reg  [3:0]   prev_btn_level;
reg  [127:0] row_A, row_B;
reg  [2:0]   pwm_dc = 3'b010; //  5%, 25%, 50%, 75% 100%
reg  [21:0]  period;
reg  [21:0]  period_on [0:4];
reg  [21:0]  pwm_counte  r;
reg signed [3:0]   counter;
wire switch;

assign usr_led = {4{switch}} & counter;
assign switch = (pwm_counter < period_on[pwm_dc])? 1 : 0;

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

initial begin
  period       = 22'd1_000_000;  // 
  period_on[0] = 22'd___50_000;  //  5%
  period_on[1] = 22'd__250_000;  //  25%
  period_on[2] = 22'd__500_000;  //  50%
  period_on[3] = 22'd__750_000;  //  75%
  period_on[4] = 22'd1_000_000;  //  100%
end


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
if (~reset_n)
  pwm_dc <= 3'b010;
else if (btn_pressed[3] && pwm_dc != 3'b100)
  pwm_dc <= pwm_dc + 1;
else if (btn_pressed[2] && pwm_dc != 3'b000)
  pwm_dc <= pwm_dc - 1;
end


always@ (posedge clk) begin
if (~reset_n)
  counter <= 4'd0;
else if (btn_pressed[1] && counter != 4'b0111)
  counter <= counter + 1;
else if (btn_pressed[0] && counter != 4'b1000)
    counter <= counter - 1;
end


always@ (posedge clk) begin
if (~reset_n)
  pwm_counter <= 22'd0;
else
  pwm_counter <= (pwm_counter < period)? pwm_counter + 1 : 0;
end


endmodule
