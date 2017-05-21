module part3_mac(clk, reset, a, b, valid_in, f,valid_out);
 input clk, reset, valid_in;
 input signed [7:0] a, b;
 output logic signed [15:0] f;
 output logic valid_out;
 logic En_in,En_f,En_pp_ff;
logic signed [7:0]a_wire,b_wire;
logic signed[15:0]sum,prod,prod_ff;


always_ff @(posedge clk)
begin
if (valid_in == 1)
begin
	En_pp_ff<=1;	
end
else
begin
	En_pp_ff<=0;
end
end


always_ff @(posedge clk)
begin
if (En_pp_ff == 1)
En_f <=1;
else 
En_f <=0;
end

always_comb 
begin
if (valid_in == 1)
	En_in = 1;
else 
	En_in = 0;
end


always_ff @(posedge clk)
begin
if (En_in == 1 && reset == 0)
begin
a_wire<=a;
b_wire<=b;
end
else if (En_in == 0 && reset == 0)
begin
a_wire <=a_wire;
b_wire <=b_wire;
end
else 
begin
a_wire<=0;
b_wire<=0;
end
end

always_ff @(posedge clk)
begin
if(En_f == 1 && reset == 0)
begin
f<=f+prod_ff;
valid_out<=1;

end
else if (En_f == 0 && reset == 0)
begin
f<=f;
valid_out<=0;
end
else if (reset == 1 )
begin 
f<=0;
valid_out<=0;
end
end
//mac1 add_mac(.input1(a_wire),.input2(b_wire),.input3(f),.mac_out(sum));


always_ff @(posedge clk)
begin
if (reset == 0 && En_pp_ff ==0)
prod_ff<=prod_ff;
else if (reset == 0 && En_pp_ff ==1)
prod_ff<=a_wire*b_wire;
else 
prod_ff <=0;
end


//always_comb
//begin
//prod = a_wire*b_wire;
//end
endmodule


