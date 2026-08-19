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

//state logic
always@(posedge clk or posedge rst)begin
if(rst)begin
	state<=idle;
	
end
else begin
	state<=next_state;
end
end

//scl clk
always@(posedge clk or posedge rst)begin
	if(rst)begin
		clk_div<=0;
		scl_out<=1'b1;
	end
	else if (scl_en) begin

                if (clk_div == 8'd49) begin

                    clk_div <= 8'd0;
                    scl_out <= ~scl_out;

                end

                else begin

                    clk_div <= clk_div + 1'b1;

                end

            end

          else begin 

                clk_div <= 8'd0;
		scl_out<=1'b1;

            end
    end

//next state logic
always@(*)begin
next_state=state;
case(state)

idle:begin
if(s)
next_state=start;
end

start:begin
if(scl_fall)
next_state=send_addr;
end

send_addr:begin
if(scl_rise && bit_count==3'd0)
next_state=ack_addr;
end

ack_addr:begin
if(scl_rise)begin
if(sda==1'b0)
next_state=pointer_addr;
else
next_state=stop;
end
end

pointer_addr:begin
if(scl_rise && bit_count==3'd0)
next_state=pointer_ack;
end

pointer_ack:begin
if(scl_rise)begin
if(sda==1'b0)
next_state=send_data;
else
next_state=stop;
end
end

send_data:begin
if(scl_rise&&bit_count==3'd0)
next_state=data_ack;
end

data_ack:begin
if(scl_rise)
next_state=stop;
end

stop:begin
next_state=idle;
end

default:next_state=idle;
endacase
end



//main control
always@(posedge clk or posedge rst)begin
if(rst)begin
	sda_ouut<=1'b1;
	scl_en<=1'b0;
	add_reg<=8'd0;
	pointer_reg<=8'd0;
	data_reg<=8'd0;
	bit_count<=3'd0;
	busy<=1'b0;
	done<=1'b0;
	ack_error<=1'b0;
end
else begin
done<=1'b0;
case(state)
idle: begin
	scl_en<=1'b0;
	sda_out<=1'b1;
	busy<=1'b0
	if(s)begin
	busy<=1'b1;
        ack_error<=1'b0;
	addr_reg<={slave_add,rw};
	pointer_reg<=pointer_add;
	data-reg<=tx_data;
	bit_count<=3'd7;
	end
end

start: begin
	sda_out<=1'b0;
	scl_en<=1'b1;
	
end
	
send_addr:begin
	if(scl_fall)begin
	sda_out<=addr_reg[7];
	end
	if(bit_count!=3'd0)begin
		addr_reg<={addr_reg[6:0],1'b0};
		bit_count<=bit_count-1'b1;
		end
	end
end
ack_addr:begin
	if(scl_fall) begin
		sda_out<=1'b1;
	end
	if(scl_rise)begin
       	 if (sda == 1'b0) begin
			bit_count<=3'd7;
	end
	else begin
		ack_error<=1'b1;
	end
	end
end
pointer_addr:begin
	if(scl_fall)begin
	sda_out<=pointer_reg[7];
	end
	if(bit_count!=3'd0)begin
		pointer_reg<={pointer_reg[6:0],1'b0};
		bit_count<=bit_count-1'b1;
		end
	end
end

pointer_ack:begin
	if(scl_fall) begin
		sda_out<=1'b1;
	end
	if (scl_rise)begin

       	 if (sda == 1'b0) begin
			bit_count<=3'd7;
	end
	else begin
		ack_error<=1'b1;
		
	end
	end
end

send_data:begin
	if(scl_fall)begin
	sda_out<=data_reg[7];
	end
	if(bit_count!=3'd0)begin
		data_reg<={data_reg[6:0],1'b0};
		bit_count<=bit_count-1'b1;
		end
	end
end		

data_ack:begin
	if(scl_fall) begin
		sda_out<=1'b1;
	end
	if (scl_rise) begin

       	 if (sda != 1'b0) begin
		ack_error<=1'b1;
	end
	end
end

stop:begin
sda_out<=1'b0;
                    if (scl_out == 1'b1) begin

                        scl_en  <= 1'b0;
                        sda_out <= 1'b1;
			busy<=1'b0;
			done<=1'b1;

                    end

                end
endcase
end
end
endmodule
