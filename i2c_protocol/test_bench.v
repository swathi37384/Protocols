`timescale 1ns/1ps

module top;
reg clk_50mhz;
reg reset;
reg start;
reg rw;
reg more_data;
reg [6:0]slave_addr;
reg [7:0]pointer_addr;
reg [7:0]data_in;
wire [7:0]data_out;
wire busy;
wire done;
wire scl;
wire sda;

pullup(scl);
pullup(sda);

top_module uut(.clk_50mhz(clk_50mhz),
	.reset(reset),
	.start(start),
	.rw(rw),
	.more_data(more_data),
	.slave_addr(slave_addr),
	.pointer_addr(pointer_addr),
	.data_in(data_in),
	.data_out(data_out),
	.busy(busy),
	.done(done),
	.scl(scl),
	.sda(sda)
);

initial begin
	clk_50mhz=1'b0;
	forever #10 clk_50mhz=~clk_50mhz;
end

initial begin
	$dumpfile("i2c_top.vcd");
	$dumpvars;

	reset=1'b1;
	start=1'b0;
	rw=1'b0;
	more_data=1'b0;
	slave_addr=7'h50;
	pointer_addr=8'h30;
	data_in=8'hB6;

	#100;
	reset=1'b0;
	#100;

	$display("START WRITE");

	rw=1'b0;
	slave_addr=7'h50;
	pointer_addr=8'h30;
	data_in=8'hB6;
	start=1'b1;

	#20;
	start=1'b0;
	wait(done==1'b1);

	$display("WRITE DONE");
	#100;

	$display("START READ");
	rw=1'b1;
	slave_addr=7'h50;
	pointer_addr=8'h30;
	start=1'b1;
	#20;
	start=1'b0;

	wait(done==1'b1);
	$display("READ DATA");
	$display("DATA READ=%h",data_out);

	if(data_out==8'hB6)begin
		$display("TEST PASSED");
	end

	else begin
		$display("TEST FAILED");
	end
	
	#1000;
	$finish;
	end
	always@(posedge scl or negedge scl)begin
		$display("time=%0t | SCL=%b |SDA=%b |RW=%b |START =%b |BUSY =%b |DONE =%b |DATA=%h",$time,scl,sda,rw,start,busy,done,data_out);
	end
	endmodule





