`timescale 1ns/1ps
module tb;
reg clk;
reg rst;
reg transfer;
reg write;
reg [7:0]addr;
reg [7:0]wdata;
wire [7:0]rdata;

top_module uut(.clk(clk),
	.rst(rst),
	.transfer(transfer),
	.write(write),
	.addr(addr),
	.wdata(wdata),
	.rdata(rdata));

always #5 clk=~clk;

initial begin
	clk=0;
	rst=1;
	transfer=0;
	write=0;
	addr=0;
	wdata=0;

	#20;
	rst=1;
	#10;
	transfer=1;
	write=1;
	addr=8'h10;
	wdata=8'h55;

	#10;
	transfer=0;
	#30;
	transfer=1;
	write=0;
	addr=8'h10;
	#10;
	transfer=0;
	#30;
	$display("read data=%h",rdata);
	#20;
	$finish;
end

initial begin
	$monitor("time=%0t  transfer=%b  write=%b  addr=%h  wdata=%h  rdata=%h",$time,transfer,write,addr,wdata,rdata);
end

endmodule
