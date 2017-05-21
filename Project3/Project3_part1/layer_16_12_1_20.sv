module layer_16_12_1_20(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready, data_out);
   parameter T=20;
   input clk, reset, s_valid, m_ready;
   input signed [T-1:0] data_in;
   output logic signed [T-1:0] data_out;
   output logic m_valid, s_ready;
   logic Wr_en_X, accum_src, en_f, en_check;
   logic [3:0] Addr_X;
   logic [4:0] Addr_B;
   logic unsigned [8:0] Addr_W;


   controlpath ctrl(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, en_check, Addr_W, Addr_X, Addr_B, Wr_en_X, accum_src);
   datapath data(clk, reset, data_in, Addr_X, Addr_W, Addr_B, Wr_en_X, data_out, en_f, en_check, accum_src);

endmodule

module controlpath(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, en_check, Addr_W, Addr_X, Addr_B, Wr_en_X, accum_src);

	input clk, reset, s_valid, m_ready;
	output logic Wr_en_X;
	output logic s_ready, m_valid, en_f, en_check, accum_src;
	output logic [3:0] Addr_X;	
	output logic [4:0] Addr_B;	
	output logic unsigned [8:0] Addr_W;


	logic [3:0] Count_X;
	logic [7:0] Count_M;
	logic [2:0] state;

   parameter [7:0]W_limit = 191;
   parameter [3:0]B_limit = 15;
   parameter [3:0]X_limit = 11;

	parameter [2:0] INITIAL = 3'b000, WRITE_X = 3'b011, MAC = 3'b100, OUTPUT = 3'b101;


	always_comb begin
		if(s_valid==1 && s_ready==1 && state== WRITE_X) begin
			//Wr_en_M=0;
			Wr_en_X=1;
			//Wr_en_B=0;
		end
		else begin
			//Wr_en_M=0;
			Wr_en_X=0;
			//Wr_en_B=0;
		end
	end

	always_ff@(posedge clk) begin
		if(reset==1) begin
			Addr_W<=0;
			Addr_X<=0;
			Addr_B<=0;
			Count_M<=0;
			Count_X<=0;
			s_ready<=0;
			m_valid<=0;
			//clr_acc<=1;
			accum_src<=0;
			en_f<=0;
			state<=INITIAL;
		end

		case(state)
			INITIAL: begin
				Addr_W<=0;
				Addr_X<=0;
				Addr_B<=0;
				Count_M<=0;
				Count_X<=0;
				s_ready<=0;
				m_valid<=0;
				//clr_acc<=1;
			        accum_src<=1;
				state<=WRITE_X;
			end

			WRITE_X: begin					
				s_ready<=1;
				if(Wr_en_X==1) begin 
					Addr_X<=Addr_X+1;
					if(Count_X == X_limit) begin
						state<=MAC;
						Addr_X<=0;
						Count_X<=0;
						s_ready<=0;
					end
					else 
						Count_X<=Count_X+1;

				end		
			end

			MAC: begin
				m_valid<=0;
				en_check <=0;
				en_f<=1;
				//clr_acc<=0;
				accum_src<=0;

				if(Addr_X>= X_limit) begin
					state<=OUTPUT;
					en_check <= 1;
					Addr_X<=0;
					Addr_W<=Addr_W+1;
					Addr_B<=Addr_B+1;
				end
				else begin
					Addr_X<=Addr_X+1;
					Addr_W<=Addr_W+1;
				end
			end

			OUTPUT: begin
				m_valid<=1;
				en_f<=0;
				en_check <=0;
				if(m_ready==1 && m_valid==1) begin
					//clr_acc<=1;
					accum_src<=1;
					m_valid<=0;
					if( Addr_W >= W_limit) begin
						state<=INITIAL;
						Addr_W<=0;
					end
					else
						state<=MAC;
				end
				else begin
					state<=OUTPUT;
				end
			end
		endcase
	end
endmodule

module datapath(clk, reset, data_in, Addr_X, Addr_W, Addr_B, Wr_en_X, data_out, en_f, en_check, accum_src);
    parameter T =20; 
	   input unsigned [8:0] Addr_W;
	   input [3:0] Addr_X;
	   input [4:0] Addr_B;
    input clk, reset, Wr_en_X, accum_src, en_f, en_check;
	   input [T-1:0] data_in;
	   output signed [T-1:0] data_out;

	logic signed [T-1:0] mem_x_out, mem_m_out, mem_b_out;

	part2_mac M(clk, reset, mem_m_out, mem_x_out, mem_b_out, data_out, en_f, en_check, accum_src);

         memory #(20,12,4) mem_x(clk, data_in, mem_x_out, Addr_X, Wr_en_X);
		layer_16_12_1_20_B_rom rom_b(clk, Addr_B, mem_b_out);
		layer_16_12_1_20_W_rom rom_w(clk, Addr_W, mem_m_out);

endmodule

module part2_mac(clk, reset, a, b, c, f, en_f, en_check, accum_src);
   parameter T = 20;
   input                      clk, reset, accum_src, en_f, en_check;
   input signed [T-1:0]         a, b, c;
   output logic signed [T-1:0] f;

   // Internal connections
   logic                      clr_f, en_f;
   logic signed [T-1:0]        adderOut, adderOut_check;

   //Combinational multiplication and addition
   always_comb begin
      adderOut = f + (a * b);
   end

       // Registers
   always_ff @(posedge clk) begin
      if (reset == 1) begin
         f      <= 0;
      end
      else begin
	 if (en_check == 1 && adderOut < 0)
	     f <= 0;
	else 
         if (en_f) begin
 	    f <= adderOut;
	 end
	 else if (accum_src) begin
	   f <= c;
	 end

      end
   end

endmodule 



module memory(clk, data_in, data_out, addr, wr_en);

   parameter WIDTH=16, SIZE=64, LOGSIZE=6;
   input [WIDTH-1:0] data_in;
   output logic [WIDTH-1:0] data_out;
   input [LOGSIZE-1:0]      addr;
   input                    clk, wr_en;

   logic [SIZE-1:0][WIDTH-1:0] mem;

   always_ff @(posedge clk) begin
      data_out <= mem[addr];
	  if (wr_en)
	    mem[addr] <= data_in;
   end
endmodule

module layer_16_12_1_20_W_rom(clk, addr, z);
   input clk;
   input [8:0] addr;
   output logic signed [19:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= 20'd435;
        1: z <= 20'd481;
        2: z <= 20'd238;
        3: z <= -20'd376;
        4: z <= -20'd410;
        5: z <= 20'd510;
        6: z <= 20'd497;
        7: z <= 20'd297;
        8: z <= -20'd311;
        9: z <= 20'd331;
        10: z <= 20'd274;
        11: z <= 20'd71;
        12: z <= -20'd351;
        13: z <= 20'd504;
        14: z <= -20'd183;
        15: z <= 20'd95;
        16: z <= 20'd100;
        17: z <= 20'd366;
        18: z <= -20'd186;
        19: z <= -20'd274;
        20: z <= -20'd456;
        21: z <= -20'd99;
        22: z <= -20'd47;
        23: z <= -20'd237;
        24: z <= 20'd474;
        25: z <= 20'd261;
        26: z <= 20'd65;
        27: z <= 20'd441;
        28: z <= 20'd141;
        29: z <= 20'd64;
        30: z <= 20'd105;
        31: z <= 20'd64;
        32: z <= 20'd33;
        33: z <= -20'd168;
        34: z <= 20'd200;
        35: z <= 20'd135;
        36: z <= -20'd170;
        37: z <= 20'd185;
        38: z <= -20'd80;
        39: z <= 20'd31;
        40: z <= 20'd4;
        41: z <= -20'd317;
        42: z <= -20'd410;
        43: z <= 20'd166;
        44: z <= -20'd325;
        45: z <= -20'd81;
        46: z <= -20'd251;
        47: z <= 20'd287;
        48: z <= -20'd227;
        49: z <= 20'd75;
        50: z <= -20'd499;
        51: z <= -20'd170;
        52: z <= 20'd488;
        53: z <= -20'd34;
        54: z <= 20'd105;
        55: z <= 20'd450;
        56: z <= -20'd284;
        57: z <= -20'd341;
        58: z <= 20'd380;
        59: z <= 20'd369;
        60: z <= 20'd235;
        61: z <= -20'd27;
        62: z <= -20'd79;
        63: z <= -20'd244;
        64: z <= 20'd317;
        65: z <= -20'd390;
        66: z <= 20'd404;
        67: z <= -20'd365;
        68: z <= 20'd307;
        69: z <= -20'd188;
        70: z <= 20'd178;
        71: z <= -20'd200;
        72: z <= 20'd7;
        73: z <= 20'd281;
        74: z <= 20'd478;
        75: z <= 20'd195;
        76: z <= -20'd312;
        77: z <= -20'd285;
        78: z <= -20'd30;
        79: z <= -20'd26;
        80: z <= 20'd302;
        81: z <= -20'd16;
        82: z <= 20'd316;
        83: z <= 20'd278;
        84: z <= 20'd462;
        85: z <= -20'd91;
        86: z <= 20'd216;
        87: z <= -20'd334;
        88: z <= 20'd80;
        89: z <= 20'd84;
        90: z <= -20'd477;
        91: z <= -20'd197;
        92: z <= -20'd454;
        93: z <= -20'd43;
        94: z <= 20'd72;
        95: z <= 20'd375;
        96: z <= 20'd79;
        97: z <= -20'd36;
        98: z <= -20'd501;
        99: z <= -20'd126;
        100: z <= 20'd288;
        101: z <= 20'd189;
        102: z <= 20'd186;
        103: z <= -20'd216;
        104: z <= -20'd42;
        105: z <= 20'd152;
        106: z <= 20'd491;
        107: z <= 20'd159;
        108: z <= 20'd379;
        109: z <= -20'd51;
        110: z <= -20'd379;
        111: z <= 20'd169;
        112: z <= 20'd445;
        113: z <= 20'd449;
        114: z <= -20'd65;
        115: z <= 20'd396;
        116: z <= -20'd154;
        117: z <= -20'd360;
        118: z <= -20'd450;
        119: z <= 20'd439;
        120: z <= 20'd236;
        121: z <= -20'd414;
        122: z <= -20'd270;
        123: z <= 20'd294;
        124: z <= 20'd55;
        125: z <= 20'd314;
        126: z <= 20'd158;
        127: z <= -20'd378;
        128: z <= -20'd234;
        129: z <= 20'd169;
        130: z <= 20'd8;
        131: z <= -20'd457;
        132: z <= -20'd154;
        133: z <= -20'd317;
        134: z <= -20'd161;
        135: z <= 20'd317;
        136: z <= 20'd347;
        137: z <= -20'd182;
        138: z <= -20'd36;
        139: z <= 20'd215;
        140: z <= 20'd279;
        141: z <= 20'd97;
        142: z <= -20'd128;
        143: z <= 20'd213;
        144: z <= 20'd34;
        145: z <= 20'd320;
        146: z <= 20'd97;
        147: z <= 20'd392;
        148: z <= 20'd472;
        149: z <= 20'd159;
        150: z <= 20'd319;
        151: z <= 20'd196;
        152: z <= 20'd257;
        153: z <= -20'd462;
        154: z <= -20'd21;
        155: z <= -20'd200;
        156: z <= 20'd364;
        157: z <= -20'd375;
        158: z <= -20'd66;
        159: z <= -20'd381;
        160: z <= 20'd306;
        161: z <= 20'd455;
        162: z <= -20'd326;
        163: z <= -20'd360;
        164: z <= -20'd374;
        165: z <= 20'd25;
        166: z <= 20'd469;
        167: z <= 20'd485;
        168: z <= 20'd355;
        169: z <= -20'd79;
        170: z <= 20'd188;
        171: z <= 20'd122;
        172: z <= -20'd494;
        173: z <= -20'd451;
        174: z <= -20'd177;
        175: z <= 20'd52;
        176: z <= 20'd381;
        177: z <= 20'd432;
        178: z <= -20'd67;
        179: z <= 20'd341;
        180: z <= 20'd80;
        181: z <= -20'd260;
        182: z <= 20'd25;
        183: z <= -20'd175;
        184: z <= -20'd210;
        185: z <= -20'd508;
        186: z <= 20'd138;
        187: z <= -20'd357;
        188: z <= -20'd371;
        189: z <= -20'd440;
        190: z <= -20'd226;
        191: z <= 20'd447;
      endcase
   end
endmodule

module layer_16_12_1_20_B_rom(clk, addr, z);
   input clk;
   input [4:0] addr;
   output logic signed [19:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= -20'd497;
        1: z <= -20'd40;
        2: z <= -20'd424;
        3: z <= -20'd359;
        4: z <= 20'd497;
        5: z <= -20'd467;
        6: z <= -20'd385;
        7: z <= 20'd340;
        8: z <= -20'd33;
        9: z <= 20'd315;
        10: z <= -20'd50;
        11: z <= -20'd15;
        12: z <= 20'd376;
        13: z <= 20'd286;
        14: z <= -20'd474;
        15: z <= 20'd245;
      endcase
   end
endmodule

