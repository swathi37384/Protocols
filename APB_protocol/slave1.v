module slave1(input clk,rst,
input psel,
input [7:0]paddr,
input [7:0]pwdata,
input penable,
input pwrite,
output reg pready,
output reg [7:0]prdata);

reg [7:0]mem[0:255];
always@(posedge clk or posedge rst)begin
	if(!rst)begin
		pready<=0;
		prdata<=8'd0;
	end
	else begin
		pready<=0;
		if(psel && penable)begin
			pready<=1;
			if(pwrite)begin
				mem[paddr]<=pwdata;
			end
			else begin
				prdata<=mem[paddr];
			end
		end
	end
end
endmodule

