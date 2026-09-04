module slave1(input clk,rst,
input psel,
input [7:0]paddr,
input [7:0]pwdata,
input penable,
input pwrite,
output  pready,
output  [7:0]prdata);

reg [7:0]mem[0:255];
assign pready=psel && penable;
assign prdata = (!pwrite && psel && penable) ?mem[paddr] : 8'h00;
always@(posedge clk or negedge rst)begin
	if(!rst)begin

	end
	else begin
		if(psel && penable&& pwrite)begin
				mem[paddr]<=pwdata;
		end
			
	end
end
endmodule

