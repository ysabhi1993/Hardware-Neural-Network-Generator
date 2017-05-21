module layer_4_4_1_16(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready, data_out);
   parameter T=16;
   input clk, reset, s_valid, m_ready;
   input signed [T-1:0] data_in;
   output logic signed [T-1:0] data_out;
   output logic m_valid, s_ready;
   logic Wr_en_X, accum_src, en_f, en_check;
   logic [1:0] Addr_X;
   logic [2:0] Addr_B;
   logic unsigned [4:0] Addr_W;


   controlpath ctrl(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, en_check, Addr_W, Addr_X, Addr_B, Wr_en_X, accum_src);
   datapath data(clk, reset, data_in, Addr_X, Addr_W, Addr_B, Wr_en_X, data_out, en_f, en_check, accum_src);

endmodule

module controlpath(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, en_check, Addr_W, Addr_X, Addr_B, Wr_en_X, accum_src);

	input clk, reset, s_valid, m_ready;
	output logic Wr_en_X;
	output logic s_ready, m_valid, en_f, en_check, accum_src;
	output logic [1:0] Addr_X;	
	output logic [2:0] Addr_B;	
	output logic unsigned [4:0] Addr_W;


	logic [1:0] Count_X;
	logic [3:0] Count_M;
	logic [2:0] state;

   parameter [3:0]W_limit = 15;
   parameter [1:0]B_limit = 3;
   parameter [1:0]X_limit = 3;

	parameter [1:0] INITIAL = 2'b00, WRITE_X = 2'b01, MAC = 2'b10, OUTPUT = 2'b11;


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
    parameter T =16; 
	   input unsigned [4:0] Addr_W;
	   input [1:0] Addr_X;
	   input [2:0] Addr_B;
    input clk, reset, Wr_en_X, accum_src, en_f, en_check;
	   input [T-1:0] data_in;
	   output signed [T-1:0] data_out;

	logic signed [T-1:0] mem_x_out, mem_m_out, mem_b_out;

	part2_mac M(clk, reset, mem_m_out, mem_x_out, mem_b_out, data_out, en_f, en_check, accum_src);

         memory #(16,4,2) mem_x(clk, data_in, mem_x_out, Addr_X, Wr_en_X);
		layer_4_4_1_16_B_rom rom_b(clk, Addr_B, mem_b_out);
		layer_4_4_1_16_W_rom rom_w(clk, Addr_W, mem_m_out);

endmodule

module part2_mac(clk, reset, a, b, c, f, en_f, en_check, accum_src);
   parameter T = 16;
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

module layer_4_4_1_16_W_rom(clk, addr, z);
   input clk;
   input [4:0] addr;
   output logic signed [15:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= -16'd32;
        1: z <= -16'd112;
        2: z <= 16'd52;
        3: z <= 16'd105;
        4: z <= -16'd17;
        5: z <= -16'd40;
        6: z <= -16'd77;
        7: z <= -16'd38;
        8: z <= -16'd69;
        9: z <= -16'd106;
        10: z <= -16'd47;
        11: z <= 16'd68;
        12: z <= 16'd77;
        13: z <= -16'd13;
        14: z <= 16'd37;
        15: z <= 16'd68;
      endcase
   end
endmodule

module layer_4_4_1_16_B_rom(clk, addr, z);
   input clk;
   input [2:0] addr;
   output logic signed [15:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= 16'd2;
        1: z <= -16'd60;
        2: z <= 16'd67;
        3: z <= 16'd15;
      endcase
   end
endmodule

