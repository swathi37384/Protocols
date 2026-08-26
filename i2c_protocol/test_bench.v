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

	reg slave_sda_oe;
	assign sda=slave_sda_oe?1'b0:1'bz;

	initial begin
		slave_sda_oe=1'b0;
		rx_byte = 8'h00;
    slave_data = 8'hB6;

	end

	reg [7:0] rx_byte;
	reg [7:0] slave_data;
	integer i;
	task receive_byte;
		begin
			for(i=7;i>=0;i=i-1)begin
				wait(scl==1'b0);
				wait(scl==1'b1);
				rx_byte[i]=sda;
			end
				wait(scl==1'b0);
			
		end
	endtask

	task ack;
		begin
			slave_sda_oe=1'b1;
			wait(scl==1'b1);
			wait(scl==1'b0);
			slave_sda_oe=1'b0;
		end
	endtask

	task send_byte;
begin
    for(i=7; i>=0; i=i-1) begin
        wait(scl == 1'b0);
		if(slave_data[i]==1'b0)
			slave_sda_oe=1'b1;
		else
			slave_sda_oe=1'b0;
		#100;
	end

    wait(scl == 1'b0);
    slave_sda_oe = 1'b0;
end
endtask

	initial begin
	/* WRITE */
wait(scl == 1'b1);
wait(sda == 1'b0);       // START

receive_byte;
ack;

receive_byte;
ack;

receive_byte;
ack;


/* REPEATED START */
wait(scl == 1'b1);
wait(sda == 1'b0);

receive_byte;
ack;

slave_data = 8'hB6;
send_byte;
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
	wait(busy==1'b1);
	start=1'b0;
	wait(done==1'b1);
	$display("WRITE DONE");
	#1000;

	$display("START READ");
	rw=1'b1;
	slave_addr=7'h50;
	pointer_addr=8'h30;
	start=1'b1;

	wait(busy==1'b1);
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
	initial begin
		forever begin
			#1000;
		$display("time=%0t | SCL=%b |SDA=%b |RW=%b |START =%b |BUSY =%b |DONE =%b |DATA=%h",$time,scl,sda,rw,start,busy,done,data_out);
	end
	end
	endmodule





