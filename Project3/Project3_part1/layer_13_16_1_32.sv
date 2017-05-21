module layer_13_16_1_32(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready, data_out);
   parameter T=32;
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

   parameter [7:0]W_limit = 207;
   parameter [3:0]B_limit = 12;
   parameter [3:0]X_limit = 15;

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
    parameter T =32; 
	   input unsigned [8:0] Addr_W;
	   input [3:0] Addr_X;
	   input [4:0] Addr_B;
    input clk, reset, Wr_en_X, accum_src, en_f, en_check;
	   input [T-1:0] data_in;
	   output signed [T-1:0] data_out;

	logic signed [T-1:0] mem_x_out, mem_m_out, mem_b_out;

	part2_mac M(clk, reset, mem_m_out, mem_x_out, mem_b_out, data_out, en_f, en_check, accum_src);

         memory #(32,16,4) mem_x(clk, data_in, mem_x_out, Addr_X, Wr_en_X);
		layer_13_16_1_32_B_rom rom_b(clk, Addr_B, mem_b_out);
		layer_13_16_1_32_W_rom rom_w(clk, Addr_W, mem_m_out);

endmodule

module part2_mac(clk, reset, a, b, c, f, en_f, en_check, accum_src);
   parameter T = 32;
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

module layer_13_16_1_32_W_rom(clk, addr, z);
   input clk;
   input [8:0] addr;
   output logic signed [31:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= 32'd4694;
        1: z <= 32'd9712;
        2: z <= -32'd841;
        3: z <= -32'd16666;
        4: z <= -32'd12675;
        5: z <= 32'd16189;
        6: z <= -32'd29701;
        7: z <= -32'd6474;
        8: z <= 32'd8010;
        9: z <= 32'd4014;
        10: z <= -32'd29844;
        11: z <= -32'd1273;
        12: z <= -32'd23044;
        13: z <= 32'd7570;
        14: z <= -32'd9480;
        15: z <= -32'd1419;
        16: z <= 32'd2553;
        17: z <= 32'd17312;
        18: z <= 32'd30520;
        19: z <= 32'd23394;
        20: z <= 32'd22380;
        21: z <= -32'd3692;
        22: z <= 32'd11438;
        23: z <= -32'd19610;
        24: z <= -32'd15678;
        25: z <= 32'd8921;
        26: z <= 32'd1678;
        27: z <= -32'd24644;
        28: z <= -32'd1699;
        29: z <= 32'd20971;
        30: z <= -32'd5189;
        31: z <= -32'd29773;
        32: z <= -32'd2085;
        33: z <= 32'd26739;
        34: z <= -32'd13670;
        35: z <= 32'd18008;
        36: z <= 32'd10160;
        37: z <= -32'd10603;
        38: z <= -32'd21234;
        39: z <= -32'd14598;
        40: z <= 32'd26180;
        41: z <= -32'd18309;
        42: z <= 32'd16898;
        43: z <= -32'd29632;
        44: z <= 32'd22029;
        45: z <= -32'd25350;
        46: z <= 32'd1718;
        47: z <= -32'd8185;
        48: z <= 32'd24730;
        49: z <= -32'd530;
        50: z <= -32'd17559;
        51: z <= 32'd14342;
        52: z <= 32'd28546;
        53: z <= 32'd26647;
        54: z <= 32'd27501;
        55: z <= -32'd19900;
        56: z <= 32'd2800;
        57: z <= -32'd3589;
        58: z <= -32'd11775;
        59: z <= -32'd31667;
        60: z <= -32'd15386;
        61: z <= 32'd15804;
        62: z <= -32'd28671;
        63: z <= 32'd15297;
        64: z <= 32'd9775;
        65: z <= -32'd9573;
        66: z <= 32'd538;
        67: z <= -32'd12832;
        68: z <= 32'd12592;
        69: z <= 32'd12072;
        70: z <= 32'd5338;
        71: z <= 32'd6004;
        72: z <= 32'd26531;
        73: z <= -32'd10532;
        74: z <= 32'd9141;
        75: z <= 32'd15793;
        76: z <= -32'd3114;
        77: z <= -32'd21909;
        78: z <= -32'd25160;
        79: z <= -32'd11152;
        80: z <= 32'd10329;
        81: z <= -32'd9951;
        82: z <= -32'd29577;
        83: z <= 32'd6107;
        84: z <= -32'd16071;
        85: z <= 32'd30692;
        86: z <= 32'd18976;
        87: z <= 32'd19497;
        88: z <= -32'd5665;
        89: z <= -32'd25567;
        90: z <= 32'd20599;
        91: z <= 32'd11718;
        92: z <= 32'd23005;
        93: z <= 32'd24696;
        94: z <= -32'd5753;
        95: z <= 32'd13;
        96: z <= -32'd17645;
        97: z <= 32'd27553;
        98: z <= 32'd19949;
        99: z <= 32'd27715;
        100: z <= 32'd6858;
        101: z <= -32'd7481;
        102: z <= 32'd952;
        103: z <= 32'd621;
        104: z <= 32'd14756;
        105: z <= -32'd22675;
        106: z <= -32'd16354;
        107: z <= -32'd21126;
        108: z <= -32'd11816;
        109: z <= -32'd8746;
        110: z <= 32'd491;
        111: z <= 32'd31281;
        112: z <= 32'd14072;
        113: z <= 32'd3682;
        114: z <= 32'd4620;
        115: z <= 32'd30769;
        116: z <= 32'd1606;
        117: z <= -32'd9172;
        118: z <= 32'd17498;
        119: z <= 32'd28709;
        120: z <= -32'd1971;
        121: z <= 32'd5329;
        122: z <= 32'd7659;
        123: z <= -32'd11733;
        124: z <= -32'd2743;
        125: z <= -32'd30861;
        126: z <= 32'd21048;
        127: z <= 32'd12380;
        128: z <= 32'd29460;
        129: z <= 32'd8229;
        130: z <= 32'd7328;
        131: z <= 32'd3550;
        132: z <= -32'd32020;
        133: z <= -32'd24488;
        134: z <= -32'd28596;
        135: z <= 32'd15504;
        136: z <= -32'd14395;
        137: z <= -32'd12182;
        138: z <= 32'd27147;
        139: z <= 32'd6557;
        140: z <= 32'd11841;
        141: z <= -32'd5130;
        142: z <= 32'd5070;
        143: z <= -32'd6855;
        144: z <= 32'd31320;
        145: z <= -32'd23078;
        146: z <= -32'd8854;
        147: z <= 32'd158;
        148: z <= 32'd519;
        149: z <= -32'd24124;
        150: z <= -32'd3901;
        151: z <= 32'd31316;
        152: z <= 32'd13974;
        153: z <= -32'd29009;
        154: z <= -32'd13185;
        155: z <= -32'd21537;
        156: z <= -32'd27102;
        157: z <= -32'd24905;
        158: z <= 32'd23612;
        159: z <= -32'd30410;
        160: z <= 32'd16092;
        161: z <= -32'd1828;
        162: z <= 32'd5909;
        163: z <= 32'd16841;
        164: z <= 32'd6452;
        165: z <= 32'd10081;
        166: z <= -32'd423;
        167: z <= 32'd24825;
        168: z <= 32'd30667;
        169: z <= -32'd6044;
        170: z <= -32'd1386;
        171: z <= 32'd9740;
        172: z <= 32'd21594;
        173: z <= -32'd29084;
        174: z <= -32'd29883;
        175: z <= 32'd20146;
        176: z <= -32'd19394;
        177: z <= -32'd5969;
        178: z <= -32'd12464;
        179: z <= 32'd13893;
        180: z <= 32'd2676;
        181: z <= 32'd16404;
        182: z <= 32'd12442;
        183: z <= -32'd16118;
        184: z <= 32'd20163;
        185: z <= 32'd32025;
        186: z <= -32'd4887;
        187: z <= 32'd25829;
        188: z <= -32'd25647;
        189: z <= -32'd14043;
        190: z <= 32'd28187;
        191: z <= 32'd23213;
        192: z <= 32'd16897;
        193: z <= 32'd1328;
        194: z <= 32'd7286;
        195: z <= -32'd9419;
        196: z <= -32'd21359;
        197: z <= -32'd25904;
        198: z <= -32'd17362;
        199: z <= -32'd23459;
        200: z <= 32'd820;
        201: z <= 32'd14020;
        202: z <= 32'd19049;
        203: z <= -32'd10353;
        204: z <= 32'd17704;
        205: z <= 32'd21935;
        206: z <= -32'd22975;
        207: z <= 32'd31079;
      endcase
   end
endmodule

module layer_13_16_1_32_B_rom(clk, addr, z);
   input clk;
   input [4:0] addr;
   output logic signed [31:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= -32'd16802;
        1: z <= -32'd2670;
        2: z <= 32'd12204;
        3: z <= 32'd18642;
        4: z <= -32'd19034;
        5: z <= -32'd8122;
        6: z <= -32'd30244;
        7: z <= -32'd31639;
        8: z <= -32'd8864;
        9: z <= -32'd2362;
        10: z <= 32'd26958;
        11: z <= -32'd1743;
        12: z <= 32'd16363;
      endcase
   end
endmodule

