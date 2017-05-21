module tb_part3_mac();

   logic clk, reset, valid_in, valid_out;
   logic signed [7:0] a, b;
   logic signed [15:0] f;

 int i,j;

   part3_mac dut(clk, reset, a, b, valid_in, f, valid_out);

   initial clk = 0;
   always #5 clk = ~clk;

initial begin

// Before first clock edge, initialize
      reset = 1;
      {a, b} = {8'b0,8'b0};
      valid_in = 0;
      
      
$monitor ($time,"\tinput1=%d\t,input2=%d\t,output=%d\t, valid_out=%b\t",a,b,f,valid_out);

@(posedge clk);			
      #1; // After 1 posedge
      reset = 0; 	//at the posedge reset is applied. outputs: a=0;b=0;f=0;
      valid_in = 1;

// the for loop checks for all values of a from -127 to 0 and for all values of j from -127 to 128) 
// the input changes on every clock edge
for (i=-4;i<=0;i++)
begin
    for (j=-2;j<=1;j++)
    begin
    @(posedge clk)
      #1 a=i;b=j;
    end
end


      @(posedge clk);
      #1; 
      a = 4; b = 4; valid_in = 0; // at this posedge after one unit the valid_in goes low. 
      @(posedge clk);
      #1; 
      a = 5; b = 5; valid_in = 0;// at this posedge after one unit the valid_in remains low.
      @(posedge clk);
      #1; 
      valid_in = 1;		
	
// the for loop checks for all values of a from 1 to 127 and for all values of j from -127 to 128) 
// the input changes on every clock edge

for (i=1;i<=2;i++)
begin
    for (j=-3;j<=0;j++)
    begin
    @(posedge clk)
    #1 a=i;b=j;
    end
end
  

#20
$finish;
end

endmodule
	
