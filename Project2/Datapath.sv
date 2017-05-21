module Data_path(clk, reset, data_in, dout_M, dout_X, addr_M, addr_X, wren_M, wren_X, clr_acc, en_out, data_out);
input clk, reset, clr_acc, en_out, wren_M, wren_X;
input [7:0]data_in;
input [3:0]addr_M;
input [1:0]addr_X;

output logic [7:0]dout_M, dout_X;
output logic [15:0]data_out;


memory_M myMemInst_M(clk, data_in, dout_M, addr_M, wren_M);
memory_X myMemInst_X(clk, data_in, dout_X, addr_X, wren_X);

Mac dut_mac(clk, reset, dout_M, dout_X, clr_acc, data_out, en_out);

endmodule

module memory_M(clk, data_in, dout_M, addr_M, wren_M);

   parameter WIDTH=8, SIZE=9, LOGSIZE=4;
   input [WIDTH-1:0] data_in;
   output logic [WIDTH-1:0] dout_M;
   input [LOGSIZE-1:0]      addr_M;
   input                    clk, wren_M;

   logic [SIZE-1:0][WIDTH-1:0] mem;

   always_ff @(posedge clk) begin
      dout_M <= mem[addr_M];
          if (wren_M)
            mem[addr_M] <= data_in;
   end
endmodule

module memory_X(clk, data_in, dout_X, addr_X, wren_X);

   parameter WIDTH=8, SIZE=3, LOGSIZE=2;
   input [WIDTH-1:0] 	    data_in;
   output logic [WIDTH-1:0] dout_X;
   input [LOGSIZE-1:0]      addr_X;
   input                    clk, wren_X;

   logic [SIZE-1:0][WIDTH-1:0] mem;

   always_ff @(posedge clk) begin
      dout_X <= mem[addr_X];
          if (wren_X)
            mem[addr_X] <= data_in;
   end
endmodule

