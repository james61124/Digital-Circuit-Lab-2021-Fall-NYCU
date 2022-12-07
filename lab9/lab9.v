module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

reg prev_btn_level;
wire btn_level, btn_pressed;
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
// Enable one cycle of btn_pressed per each button hit
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end
assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
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

localparam [2:0] INIT=0, INC=1, MSG=2, W=3, DO=4, END=5, CHECKANS=6;
reg  [2:0] P, P_next;
always @ (posedge clk) begin
	if(!reset_n) P=INIT;
	else P=P_next;
end
// 0:   counter = 64 => pnext INC
// 1:   <=inc (p =DO)
// 1.5: pnext msg
// 2:   p = msg +1
always @ (*) begin
	case (P)
		INIT: // press btn3
			if(btn_pressed) P_next=MSG;
			else P_next=INIT;
		INC: // idx=idx+1
			P_next=MSG;
		MSG: // msg=idx
			P_next=CHECKANS;
        CHECKANS: // if(passwd_hash==hash) check=1
            P_next=W;
		W: // w=msg
		    if(check) P_next=END;
			else P_next=DO;
		DO: // crack password
			if(counter==64) P_next=INC;
			else P_next=DO;
		END: // print answer
			P_next=END;
		default:
		  P_next=P_next;
	endcase
end

reg [0:127] passwd_hash = 128'h7d47dfe997ab64d66df5bfcebc582c61; // the given answer : 31415926  hE9982EC5CA981BD365603623CF4B2277
reg	[7:0] idx [0:7];
reg check;
always @(posedge clk) begin
    if(!reset_n) check<=0;
    else if(P==CHECKANS) begin
        if(passwd_hash[0:7]==hash[0]&&passwd_hash[8:15]==hash[1]&&passwd_hash[16:23]==hash[2]&&passwd_hash[24:31]==hash[3]
         &&passwd_hash[32:39]==hash[4]&&passwd_hash[40:47]==hash[5]&&passwd_hash[48:55]==hash[6]&&passwd_hash[56:63]==hash[7]
         &&passwd_hash[64:71]==hash[8]&&passwd_hash[72:79]==hash[9]&&passwd_hash[80:87]==hash[10]&&passwd_hash[88:95]==hash[11]
         &&passwd_hash[96:103]==hash[12]&&passwd_hash[104:111]==hash[13]&&passwd_hash[112:119]==hash[14]&&passwd_hash[120:127]==hash[15]
		) 
		begin
            check<=1;
        end
    end else check<=check;
end

reg [31:0] r [0:63];
reg [31:0] k [0:63];
always @(posedge clk) begin
    if(!reset_n) begin
       r[0]<=7; r[1]<=12; r[2]<= 17; r[3]<=22; r[4]<= 7; r[5]<=12; r[6]<=17; r[7]<=22; r[8]<=7; r[9]<=12; r[10]<=17; r[11]<=22; r[12]<= 7; r[13]<=12; r[14]<=17; r[15]<=22;
       r[16]<=5; r[17]<=9; r[18]<=14; r[19]<=20; r[20]<=5; r[21]<=9; r[22]<=14; r[23]<=20; r[24]<=5; r[25]<=9; r[26]<=14; r[27]<=20; r[28]<=5; r[29]<=9; r[30]<=14; r[31]<= 20;
       r[32]<=4; r[33]<=11; r[34]<=16; r[35]<=23; r[36]<= 4; r[37]<=11; r[38]<=16; r[39]<=23; r[40]<=4; r[41]<=11; r[42]<=16; r[43]<=23; r[44]<=4; r[45]<=11; r[46]<=16; r[47]<=23;
       r[48]<=6; r[49]<=10; r[50]<=15; r[51]<=21; r[52]<=6; r[53]<=10; r[54]<=15; r[55]<=21; r[56]<=6; r[57]<=10; r[58]<=15; r[59]<=21; r[60]<=6; r[61]<=10; r[62]<=15; r[63]<=21;
       
       k[0]<=32'hD76AA478; k[1]<=32'hE8C7B756; k[2]<=32'h242070DB; k[3]<=32'hC1BDCEEE;
       k[4]<=32'hf57c0faf; k[5]<=32'h4787c62a; k[6]<=32'ha8304613; k[7]<=32'hfd469501;
       k[8]<=32'h698098d8; k[9]<=32'h8b44f7af; k[10]<=32'hffff5bb1; k[11]<=32'h895cd7be;
       k[12]<=32'h6b901122; k[13]<=32'hfd987193; k[14]<=32'ha679438e; k[15]<=32'h49b40821;
       k[16]<=32'hf61e2562; k[17]<=32'hc040b340; k[18]<=32'h265e5a51; k[19]<=32'he9b6c7aa;
       k[20]<=32'hd62f105d; k[21]<=32'h02441453; k[22]<=32'hd8a1e681; k[23]<=32'he7d3fbc8;
       k[24]<=32'h21e1cde6; k[25]<=32'hc33707d6; k[26]<=32'hf4d50d87; k[27]<=32'h455a14ed;
       k[28]<=32'ha9e3e905; k[29]<=32'hfcefa3f8; k[30]<=32'h676f02d9; k[31]<=32'h8d2a4c8a;
       k[32]<=32'hfffa3942; k[33]<=32'h8771f681; k[34]<=32'h6d9d6122; k[35]<=32'hfde5380c;
       k[36]<=32'ha4beea44; k[37]<=32'h4bdecfa9; k[38]<=32'hf6bb4b60; k[39]<=32'hbebfbc70;
       k[40]<=32'h289b7ec6; k[41]<=32'heaa127fa; k[42]<=32'hd4ef3085; k[43]<=32'h04881d05;
       k[44]<=32'hd9d4d039; k[45]<=32'he6db99e5; k[46]<=32'h1fa27cf8; k[47]<=32'hc4ac5665;
       k[48]<=32'hf4292244; k[49]<=32'h432aff97; k[50]<=32'hab9423a7; k[51]<=32'hfc93a039;
       k[52]<=32'h655b59c3; k[53]<=32'h8f0ccc92; k[54]<=32'hffeff47d; k[55]<=32'h85845dd1;
       k[56]<=32'h6fa87e4f; k[57]<=32'hfe2ce6e0; k[58]<=32'ha3014314; k[59]<=32'h4e0811a1;
       k[60]<=32'hf7537e82; k[61]<=32'hbd3af235; k[62]<=32'h2ad7d2bb; k[63]<=32'heb86d391;
    end
end

reg [7:0] hash [0:15]; // output of MD5 (ans)
reg [7:0] msg [0:63]; // '8'+56
reg [31:0] w [0:15]; // group msg buffer

reg [31:0] h0;
reg [31:0] h1;
reg [31:0] h2;
reg [31:0] h3;

reg [31:0] a;
reg [31:0] b;
reg [31:0] c;
reg [31:0] d;
reg [31:0] f;
reg [31:0] g;
reg [31:0] temp;

reg [6:0] counter = 0; // count to 64
reg [6:0] i=0;
reg [6:0] j1=0;
reg [6:0] j2=1;
reg [6:0] j3=2;
reg [6:0] j4=3;


always @(posedge clk) begin
	if(!reset_n) begin
		for(i=0;i<16;i=i+1)begin
		  hash[i]<=0;
		end
	end else if(P==MSG) begin
		// give answer
		hash[0]<=h0[7:0];  hash[1]<=h0[15:8];  hash[2]<=h0[23:16];  hash[3]<=h0[31:24];
		hash[4]<=h1[7:0];  hash[5]<=h1[15:8];  hash[6]<=h1[23:16];  hash[7]<=h1[31:24];
		hash[8]<=h2[7:0];  hash[9]<=h2[15:8];  hash[10]<=h2[23:16]; hash[11]<=h2[31:24];
		hash[12]<=h3[7:0]; hash[13]<=h3[15:8]; hash[14]<=h3[23:16]; hash[15]<=h3[31:24];
	end
end

always @(posedge clk) begin
	if(!reset_n) begin
		for(i=0;i<8;i=i+1)begin
		  idx[i]<=0;
		end
	end
	else if(P==W&&check) begin // ans idx is idx-1
	   if(idx[0]>0) idx[0]<=idx[0]-1;
	   else begin
            idx[0]<=9;
            if(idx[1] > 0) idx[1] <= idx[1] -1;
            else begin
                idx[1]<=9;
                if(idx[2] > 0) idx[2] <= idx[2] -1;
                else begin
                    idx[2]<=9;
                    if(idx[3] > 0) idx[3] <= idx[3] -1;
                    else begin
                        idx[3]<=9;
                        if(idx[4] > 0) idx[4]<=idx[4]-1;
                        else begin
                            idx[4]<=9;
                            if(idx[5] > 0) idx[5]<=idx[5]-1;
                            else begin
                                idx[5]<=9;
                                if(idx[6] > 0) idx[6]<=idx[6]-1;
                                else begin
                                    idx[6]<=9;
                                    if(idx[7] > 0) idx[7]<=idx[7]-1;
                                    //
                                end
                            end
                        end
                    end
                end
            end
       end
	end
	else if(P==INC) begin
		// idx+1
		if(idx[0]==9) begin
                idx[0]<=0;
                if(idx[1]==9) begin
                    idx[1]<=0;
                    if(idx[2]==9) begin
                        idx[2]<=0;
                        if(idx[3]==9) begin
                            idx[3]<=0;
                            if(idx[4]==9) begin
                                idx[4]<=0;
                                if(idx[5]==9) begin
                                    idx[5]<=0;
                                    if(idx[6]==9) begin
                                        idx[6]<=0;
                                        idx[7]<=idx[7]+1;
                                    end
                                    else begin
                                        idx[6]<=idx[6]+1;
                                    end
                                end
                                else begin
                                    idx[5]<=idx[5]+1;
                                end
                            end
                            else begin
                                idx[4]<=idx[4]+1;
                            end
                        end
                        else begin
                            idx[3]<=idx[3]+1;
                        end
                    end
                    else begin
                        idx[2]<=idx[2]+1;
                    end
                end
                else begin
                    idx[1]<=idx[1]+1;
                end
            end
            else begin
                idx[0]<=idx[0]+1;
            end     
	end else begin
		for(i=0;i<8;i=i+1)begin
		  idx[i]<=idx[i];
		end
	end
end

always @(posedge clk) begin
	if(!reset_n) begin
		// password
		msg[0]<=0;   msg[1]<=0;  msg[2]<=0;  msg[3]<=0; 
		msg[4]<=0;   msg[5]<=0;  msg[6]<=0;  msg[7]<=0;
		msg[8]<=128; msg[9]<=0;  msg[10]<=0; msg[11]<=0;
		for(i=12;i<56;i=i+1)begin
		  msg[i]<=0;
		end
		msg[56]<=64; msg[57]<=0; msg[58]<=0; msg[59]<=0;
		msg[60]<=0;	 msg[61]<=0; msg[62]<=0; msg[63]<=0;
	end else if(P==MSG) begin
	   for(i=0;i<=7;i=i+1)begin
		  msg[i]<=idx[i]+48;
		end
	end else begin
	   for(i=0;i<=7;i=i+1)begin
		  msg[i]<=msg[i];
		end
	end
end

always @(posedge clk) begin
	if(!reset_n) begin
		for(i=0;i<16;i=i+1)begin
		  w[i]<=0;
		end
	end else if(P==W) begin
		// order should be 3 2 1 0 ....
		w[0] <={msg[3],  msg[2],  msg[1],  msg[0]};   
		w[1] <={msg[7],  msg[6],  msg[5],  msg[4]};   
		w[2] <={msg[11], msg[10], msg[9],  msg[8]};
		w[3] <={msg[12], msg[13], msg[14], msg[15]};   
		w[4] <={msg[16], msg[17], msg[18], msg[19]};   
		w[5] <={msg[20], msg[21], msg[22], msg[23]};   
		w[6] <={msg[24], msg[25], msg[26], msg[27]};   
		w[7] <={msg[28], msg[29], msg[30], msg[31]}; 
		w[8] <={msg[32], msg[33], msg[34], msg[35]};   
		w[9] <={msg[36], msg[37], msg[38], msg[39]};   
		w[10]<={msg[40], msg[41], msg[42], msg[43]}; 
		w[11]<={msg[44], msg[45], msg[46], msg[47]}; 
		w[12]<={msg[48], msg[49], msg[50], msg[51]}; 
		w[13]<={msg[52], msg[53], msg[54], msg[55]};
		w[14]<={msg[59], msg[58], msg[57], msg[56]}; 
		w[15]<={msg[60], msg[61], msg[62], msg[63]};
	end else begin
		for(i=0;i<16;i=i+1)begin
		  w[i]<=w[i];
		end
	end
end

// idx is pattern (input of MD5)
always @(posedge clk) begin
	if(!reset_n) begin
        //
	end else if(P==DO && P_next != INC) begin
        if(counter==0) begin
            a=h0;
            b=h1;
            c=h2;
            d=h3;               
        end   
        if(counter<64) begin
            if(counter<16) begin
                f = (b & c) | (~b & d);
                g = counter;
            end else if(counter<32) begin
                f = (d & b) | ((~d) & c);
                g = (5*counter + 1) & (16-1); // % 16			
            end else if(counter<48) begin
                f = b ^ c ^ d;
                g = (3*counter + 5) & (16-1); // % 16			
            end else begin
                f = c ^ (b | (~d));
                g = (7*counter) & (16-1); // % 16		
            end
            
            temp = d;
            d=c;
            c=b;
            b=b+(((a + f + k[counter] + w[g])<<r[counter]) | ((a + f + k[counter] + w[g])>>(32-r[counter])));
            a=temp;
        end
    end
end

always @(posedge clk) begin
    if(!reset_n) begin
        counter<=0;
    end else if(P==DO&&counter<64) begin
		// counter == 63 is doing 64
        counter<=counter+1;
    end else if(counter==64) begin
		// counter == 64 is doing 65 => NO NEED
        counter<=0;
    end else counter<=0;
end

always @(posedge clk) begin
    if(!reset_n||P==MSG) begin
    	h0 <= {8'h67, 8'h45, 8'h23, 8'h01};
        h1 <= {8'hEF, 8'hCD, 8'hAB, 8'h89};
        h2 <= {8'h98, 8'hBA, 8'hDC, 8'hFE};
        h3 <= {8'h10, 8'h32, 8'h54, 8'h76};
    end
    else if(counter==64) begin
        h0<=h0+a;
        h1<=h1+b;
        h2<=h2+c;
        h3<=h3+d;
		// counter == 64
		// h0 h1 h2 h3 is set to correct value
		// p = inc
		// p = msg, check ans!
    end
end

//reg modified;
reg [20:0] timer;
reg [3:0] ms [0:6];
always @(posedge clk) begin
    if(btn_pressed||!reset_n) begin
        timer<=0;
        //modified<=0;
        ms[0]<=0; ms[1]<=0; ms[2]<=0; ms[3]<=0;
        ms[4]<=0; ms[5]<=0; ms[6]<=0;
    end else if(!check) begin
        timer<=timer+1;
        if(timer==100000) begin // 1ms
            timer<=0;
           //--
            if(ms[0]==9) begin
                ms[0]<=0;
                if(ms[1]==9) begin
                    ms[1]<=0;
                    if(ms[2]==9) begin
                        ms[2]<=0;
                        if(ms[3]==9) begin
                            ms[3]<=0;
                            if(ms[4]==9) begin
                                ms[4]<=0;
                                if(ms[5]==9) begin
                                    ms[5]<=0;
                                    ms[6]<=ms[6]+1;
                                    // 
                                end
                                else begin
                                    ms[5]<=ms[5]+1;
                                end
                            end
                            else begin
                                ms[4]<=ms[4]+1;
                            end
                        end
                        else begin
                            ms[3]<=ms[3]+1;
                        end
                    end
                    else begin
                        ms[2]<=ms[2]+1;
                    end
                end
                else begin
                    ms[1]<=ms[1]+1;
                end
            end
            else begin
                ms[0]<=ms[0]+1;
            end       
        //--
        end
    end else begin
        timer<=timer;
    end
end

always @ (posedge clk) begin
	if(!reset_n) begin
		row_A = "SD card cannot  ";
		row_B = "be initialized! ";	
    end
    else if(P==INIT) begin
        row_A<="Hit BTN3 to read";
        row_B<="Hit BTN3 to read";
    end
	else if(P==END) begin
		// print row_A and row_B
        // 31415926
		row_A[127:64]<="Passwd: "; 
		row_A[63:56]<=idx[0][3:0]+"0";
		row_A[55:48]<=idx[1][3:0]+"0"; 
		row_A[47:40]<=idx[2][3:0]+"0";
		row_A[39:32]<=idx[3][3:0]+"0";
		row_A[31:24]<=idx[4][3:0]+"0";
		row_A[23:16]<=idx[5][3:0]+"0";
		row_A[15: 8]<=idx[6][3:0]+"0"; 
		row_A[7 : 0]<=idx[7][3:0]+"0";
        
        row_B[127:80]<="Time: ";
        row_B[79:72]<=ms[6]+"0";
        row_B[71:64]<=ms[5]+"0";
        row_B[63:56]<=ms[4]+"0";
        row_B[55:48]<=ms[3]+"0";
		row_B[47:40]<=ms[2]+"0";
		row_B[39:32]<=ms[1]+"0";
		row_B[31:24]<=ms[0]+"0";
        row_B[23: 0]<=" ms";
	end
end

endmodule