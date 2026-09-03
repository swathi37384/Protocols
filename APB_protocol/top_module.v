module top_module(input clk,rst,
input transfer,
input write,
input [7:0]addr,
input [7:0]wdata,
output [7:0]rdata);

wire psel;
wire penable;
wire pwrite;
wire [7:0]paddr;
wire [7:0]pwdata;
wire pready;
wire [7:0]prdata;

master mst(.clk(clk),
	.rst(rst),
	.pready(pready),
	.transfer(transfer),
	.addr(addr),
	.wdata(wdata),
	.write(write),
	.psel(psel),
	.paddr(paddr),
	.pwdata(pwdata),
	.prdata(prdata),
	.pwrite(pwrite),
	.rdata(rdata),
	.penable(penable));

slave1 s1(.clk(clk),
	.rst(rst),
	.psel(psel),
	.paddr(paddr),
	.pwdata(pwdata),
	.penable(penable),
	.pwrite(pwrite),
	.pready(pready),
	.prdata(prdata));

endmodule

