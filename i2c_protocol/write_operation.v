module write(input clk,rst,s,rw,
input [6:0]slave_add,
input [7:0]pointer_add,
input [7:0]tx_data,
output reg busy,done,ack_error,
inout sda,
inout scl);

//parameter declaration
parameter idle=4'd0,
start=4'd1,
slave_addr=4'd2,
ack_add=4'd3,
pointer_addr=4'd4,
pointer_ack=4'd5,
data=4'd6,
data_ack=4'd7,
stop=4'd8;

reg[3:0]state,next_state;
reg pointer_enable;
reg more_data;



