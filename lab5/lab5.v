`timescale 1ns / 1ps

module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [15:0]fibo[24:0];       //25 fibo numbers and each one 16 bit
reg [7:0]data[5:0];
integer counter=0;
integer timer;
reg btn_count=1;
reg [4:0]disp_counter=5'b1;      //5 bit disp_counter
reg [3:1] Q, Q_next;
//reg re_tri;
localparam [3:1] IDLE =3'b001, FIBO =3'b010, DISP=3'b100;

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
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

always@(posedge clk)begin
    if(~reset_n)Q<=IDLE;
    else Q<=Q_next;
end
always@(*)begin
    case(Q)
        IDLE: Q_next = (btn_pressed)?FIBO:IDLE;
        FIBO: Q_next = (counter < 25)? FIBO : DISP;
        DISP: Q_next = DISP;
        default: Q_next = Q_next;
    endcase
end
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always@(posedge clk)begin
    case(Q)
    IDLE:begin
        disp_counter=5'd25;
        row_A = "Press BTN3 to   ";
        row_B = "show a message..";

 //       re_tri=1'b1;
    end
    FIBO:begin
        if(counter==0)begin
            fibo[0]=16'd0;
            counter=counter+1;
        end
        else if(counter==1)begin
            fibo[1]=16'd1;
            counter=counter+1;
        end
        else begin
            fibo[counter]=fibo[counter-1]+fibo[counter-2];
            counter=counter+1;
        end
    end
    DISP:begin
        timer=timer+1;
        if(timer==70000000)begin
            data[0]=disp_counter[4]+48;
            data[1]=(disp_counter[3:0]<10)?disp_counter[3:0]+48:disp_counter[3:0]+55;
            data[2]=(fibo[disp_counter-1][15:12]<10)?fibo[disp_counter-1][15:12]+48:fibo[disp_counter-1][15:12]+55;
            data[3]=(fibo[disp_counter-1][11:8]<10)?fibo[disp_counter-1][11:8]+48:fibo[disp_counter-1][11:8]+55;
            data[4]=(fibo[disp_counter-1][7:4]<10)?fibo[disp_counter-1][7:4]+48:fibo[disp_counter-1][7:4]+55;
            data[5]=(fibo[disp_counter-1][3:0]<10)?fibo[disp_counter-1][3:0]+48:fibo[disp_counter-1][3:0]+55;
            row_A <={ "Fibo #",data[0],data[1]," is ",data[2],data[3],data[4],data[5]};
            if(btn_count)disp_counter=disp_counter+1;
            else disp_counter=disp_counter-1;
            if(disp_counter==0)disp_counter=5'd25;
            if(disp_counter>25)disp_counter=5'd1;
            data[0]=disp_counter[4]+48;
            data[1]=(disp_counter[3:0]<10)?disp_counter[3:0]+48:disp_counter[3:0]+55;
            data[2]=(fibo[disp_counter-1][15:12]<10)?fibo[disp_counter-1][15:12]+48:fibo[disp_counter-1][15:12]+55;
            data[3]=(fibo[disp_counter-1][11:8]<10)?fibo[disp_counter-1][11:8]+48:fibo[disp_counter-1][11:8]+55;
            data[4]=(fibo[disp_counter-1][7:4]<10)?fibo[disp_counter-1][7:4]+48:fibo[disp_counter-1][7:4]+55;
            data[5]=(fibo[disp_counter-1][3:0]<10)?fibo[disp_counter-1][3:0]+48:fibo[disp_counter-1][3:0]+55;
            row_B <= {"Fibo #",data[0],data[1]," is ",data[2],data[3],data[4],data[5]};
            timer=0;
        end
    end
   endcase
end

always @(posedge clk) begin
   if(~reset_n)btn_count=0;
  else if(btn_pressed) begin
    btn_count=~btn_count;
  end
end

endmodule
