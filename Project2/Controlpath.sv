module mvma4_part3(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready, data_out);
	input clk, reset, s_valid, m_ready;
	input signed [7:0] data_in;
	output logic signed [15:0] data_out;
	output logic m_valid, s_ready;


	logic unsigned [4:0] Addr_M;
	logic [1:0] Addr_X, Addr_B;
 	logic Wr_en_M, Wr_en_X, Wr_en_B, accum_src, en_f;
	//logic signed [7:0] mem_x_out, mem_m_out;

	
	//controlpath ctrl(clk, reset, s_valid, m_ready, data_in, m_valid, s_ready, clr_acc, en_f, Addr_M, Addr_X, Wr_en_M, Wr_en_X, next_state);
	controlpath ctrl(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, Addr_M, Addr_X, Addr_B, Wr_en_M, Wr_en_X, Wr_en_B, accum_src);
	datapath data(clk, reset, data_in, Wr_en_X, Wr_en_M, Addr_X, Addr_M, Addr_B, Wr_en_B, data_out, en_f, accum_src);
	
endmodule


module controlpath(clk, reset, s_valid, m_ready, m_valid, s_ready, en_f, Addr_M, Addr_X, Addr_B, Wr_en_M, Wr_en_X, Wr_en_B, accum_src);

	input clk, reset, s_valid, m_ready;
	output logic Wr_en_M, Wr_en_X, Wr_en_B;
	output logic s_ready, m_valid, en_f,accum_src;
	output logic [1:0] Addr_X, Addr_B;	
	output logic unsigned [4:0] Addr_M;
	
	
	logic [1:0]     Count_X;
	logic [3:0]	Count_M;
	logic [2:0]	state;
	

	parameter [2:0] INITIAL = 3'b000, WRITE_M = 3'b001, WRITE_B = 3'b010, WRITE_X = 3'b011, MAC = 3'b100, OUTPUT = 3'b101;
	


	//state register
//	always_ff @(posedge clk) begin
//		if (reset == 1)
//		   state <= INITIAL;
//		else
//		   state <= state;
//	end

	//Next State logic
//	always_comb begin
//		if ((state == INITIAL) &&  s_valid == 1 && s_ready == 1)
//		    state = WRITE_M;
//		else if ((state == WRITE_M) &&  s_valid == 1 && s_ready == 1 && Count_M == 8)
//		    state = WRITE_X;
//		else if ((state == WRITE_X) &&  s_ready == 0)
//		    state = MAC;
//		else if ((state == MAC) && m_valid == 1)
//		    state = OUTPUT;
//	end
	always_comb begin
		if(s_valid==1 && s_ready==1 && state==WRITE_M) begin
			Wr_en_M=1;
			Wr_en_X=0;
			Wr_en_B=0;
		end
		else if(s_valid==1 && s_ready==1 && state== WRITE_B) begin
			Wr_en_M=0;
			Wr_en_X=0;
			Wr_en_B=1;
		end
		else if(s_valid==1 && s_ready==1 && state== WRITE_X) begin
			Wr_en_M=0;
			Wr_en_X=1;
			Wr_en_B=0;
		end
		else begin
			Wr_en_M=0;
			Wr_en_X=0;
			Wr_en_B=0;
		end
	end
	
	always_ff@(posedge clk) begin
		if(reset==1) begin
			Addr_M<=0;
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
				Addr_M<=0;
				Addr_X<=0;
				Addr_B<=0;
				Count_M<=0;
				Count_X<=0;
				s_ready<=0;
				m_valid<=0;
				//clr_acc<=1;
			        accum_src<=1;
				state<=WRITE_M;
			end
			
			WRITE_M:	begin
				s_ready <= 1;
				if(Wr_en_M==1) begin
					Addr_M<=Addr_M+1;
					if(Count_M==15) begin
						state<=WRITE_B;
						Count_X<=0;
						Addr_M<=0;
						Count_M<=0;
						s_ready<=0;
					end
					else
						Count_M<=Count_M+1;
				end
			end
			
			WRITE_B:	begin
				s_ready<=1;
				if(Wr_en_B == 1) begin
					Addr_B<=Addr_B+1;
					if(Count_X==3) begin
						state<=WRITE_X;
						Count_X<=0;
						Addr_B<=0;
						s_ready<=0;
					end
					else
						Count_X<=Count_X+1;
				end
			end

			WRITE_X: begin					
				s_ready<=1;
				if(Wr_en_X==1) begin 
					Addr_X<=Addr_X+1;
					if(Count_X==3) begin
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
				en_f<=1;
				//clr_acc<=0;
				accum_src<=0;
				
				if(Addr_X>=3) begin
					state<=OUTPUT;
					Addr_X<=0;
					Addr_M<=Addr_M+1;
					Addr_B<=Addr_B+1;
				end
				else begin
					Addr_X<=Addr_X+1;
					Addr_M<=Addr_M+1;
				end
			end
			
			OUTPUT: begin
				m_valid<=1;
				en_f<=0;					
				if(m_ready==1 && m_valid==1) begin
					//clr_acc<=1;
					accum_src<=1;
					m_valid<=0;
					if( Addr_M >= 15) begin
						state<=INITIAL;
						Addr_M<=0;
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

module datapath(clk, reset, data_in, Wr_en_X, Wr_en_M, Addr_X, Addr_M, Addr_B, Wr_en_B, data_out, en_f, accum_src);
	
	input unsigned [4:0] Addr_M;
	input [1:0] Addr_X, Addr_B;
 	input clk, reset, Wr_en_M, Wr_en_X, Wr_en_B, accum_src, en_f;
	input [7:0] data_in;
	output signed [15:0] data_out;

	logic signed [7:0] mem_x_out, mem_m_out, mem_b_out;
	//logic signed [15:0] mux_out;


	part2_mac M(clk, reset, mem_m_out, mem_x_out, mem_b_out, data_out, en_f, accum_src);
	
        memory #(8, 4, 2) mem_x(clk, data_in, mem_x_out, Addr_X, Wr_en_X);
	memory #(8, 4, 2) mem_b(clk, data_in, mem_b_out, Addr_B, Wr_en_B);
	memory #(8, 16, 5) mem_m(clk, data_in, mem_m_out, Addr_M, Wr_en_M);

endmodule



module part2_mac(clk, reset, a, b, c, f, en_f, accum_src);
   input                      clk, reset, accum_src, en_f;;
   input signed [7:0]         a, b, c;
   output logic signed [15:0] f;
  
   // Internal connections
   logic                      clr_f, en_f;
   logic signed [15:0]        adderOut;
   //logic [7:0] mux_out;


   //always_comb begin
   	//if (accum_src == 0)
	 //   mux_out = f + (a*b);
	//else 
	    //mux_out =  f + c ;
   //end 

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