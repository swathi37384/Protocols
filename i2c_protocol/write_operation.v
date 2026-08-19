module write
(input clk,rst,s,rw,
input [6:0]slave_add,
input [7:0]pointer_add,
input [7:0]tx_data,
output reg busy,done,ack_error,
inout sda,
inout scl);


//parameter declaration
parameter idle=4'd0,
start=4'd1,
send_addr=4'd2,
ack_addr=4'd3,
pointer_addr=4'd5,
pointer_ack=4'd6,
send_data=4'd7,
data_ack=4'd8,
stop=4'd9;

reg[3:0]state,next_state;
reg [7:0] addr_reg;
reg [7:0]data_reg;
reg [7:0] pointer_reg;
reg[2:0] bit_count;

reg sda_out,scl_out;
assign sda=(sda_out==1'b0)?1'b0:1'bz;
assign scl=(scl_out==1'b0)?1'b0:1'bz;

//main fsm
reg [7:0]clk_div;
reg scl_en;

always@(posedge clk)begin
if(rst)begin
	state<=idle;
	sda_out<=0;
	scl_out<=0;
	addr_reg<=8'd0;
	bit_count<=3'd0;
	clk_div<=8'd0;
	scl_en<=1'b0;
	
end
else begin
if (scl_en) begin

                if (clk_div == 8'd124) begin

                    clk_div <= 8'd0;
                    scl_out <= ~scl_out;

                end

                else begin

                    clk_div <= clk_div + 1'b1;

                end

            end

            else begin

                clk_div <= 8'd0;

            end
state<=next_state;
case(state)

idle: begin
	scl_en<=1'b0;
	sda_out<=1'b1;
	scl_out<=1'b1;

	if(s)begin
	addr_reg<={slave_add,rw};
	bit_count<=3'd7;
	next_state<=start;
	end
end

start: begin
	scl_out<=1'b1;
	sda_out<=1'b0;
	scl_en<=1'b1;
	next_state<=send_addr;
	
end
	
send_addr:begin
	if((scl_out==1'b0)&&(clk_div==8'd62))begin
	sda_out<=addr_reg[7];
	end
	if((scl_out==1'b1)&&(clk_div==8'd124))begin
		if(bit_count==3'd0)begin
		next_state<=ack_addr;
		end
		else begin
		addr_reg<={addr_reg[6:0],1'b0};
		bit_count<=bit_count-1'b1;
		end
	end
end

ack_addr:begin
	if((scl_out == 1'b0) &&(clk_div == 8'd62)) begin
		sda_out<=1'b1;
	end
	if ((scl_out == 1'b1) &&(clk_div == 8'd124)) begin

       	 if (sda == 1'b0) begin
			data_reg<=tx_data;
			bit_count<=3'd7;
			next_state<=send_data;
	end
	else begin
		next_state<=stop;
	end
	end
end

send_data:begin
	if((scl_out==1'b0)&&(clk_div==8'd62))begin
	sda_out<=data_reg[7];
	end
	if((scl_out==1'b1)&&(clk_div==8'd124))begin
		if(bit_count==3'd0)begin
		next_state<=data_ack;
		end
		else begin
		data_reg<={data_reg[6:0],1'b0};
		bit_count<=bit_count-1'b1;
		end
	end
end		

data_ack:begin
	if((scl_out == 1'b0) &&(clk_div == 8'd62)) begin
		sda_out<=1'b1;
	end
	if ((scl_out == 1'b1) &&(clk_div == 8'd124)) begin

       	 if (sda == 1'b0) begin
			next_state<=stop;
	end
	else begin
		next_state<=stop;
	end
	end
end

stop:begin
if ((scl_out == 1'b0) && (clk_div == 8'd62)) begin
                        sda_out <= 1'b0;

                    end
                    if (scl_out == 1'b1) begin

                        scl_en  <= 1'b0;
                        sda_out <= 1'b1;

                        next_state <= idle;

                    end

                end

default:next_state<=idle;
endcase
end
endmodule
