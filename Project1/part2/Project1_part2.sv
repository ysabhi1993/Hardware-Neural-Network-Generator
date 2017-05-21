module part2_mac(clk, reset, a, b, valid_in, f,valid_out);
 input clk, reset, valid_in;
 input signed [7:0] a, b;
 output logic signed [15:0] f;
 output logic valid_out;
 logic En_in,En_f;
logic signed [7:0]a_wire,b_wire;
logic signed[15:0]sum,prod;


always_ff @(posedge clk)
begin
if (valid_in == 1)
begin
	
	En_f<=1;	
end
else
begin
	
	En_f<=0;
end
end

always_comb
begin
if(valid_in == 1)
En_in=1;
else 
En_in=0;
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
f<=sum;
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


always_comb
begin
sum = f+prod;
end


always_comb
begin
prod = a_wire*b_wire;
end
endmodule


