module master(input clk,rst,
input pready,
input [7:0]prdata,
input transfer,
input [7:0]addr,
input [7:0]wdata,
input write,
output reg psel,
output reg [7:0]paddr,
output reg [7:0]pwdata,
output reg [7:0]rdata,
output reg pwrite,
output reg penable);

parameter idle =2'd0,
	setup=2'd1,
	access=2'd2;
reg [1:0]state,next_state;

reg write_reg;
reg [7:0]wdata_reg;
reg [7:0]waddr_reg;
always@(posedge clk)begin
	if(!rst)begin
		state<=idle;
		pselx<=0;
		paddr<=8'd0;
		pwdata<=8'd0;
		pwrite<=0;
		penable<=0;
	end
	else begin
		state<=next_state;
		if(state==idle&&transfer)begin
			waddr_reg<=addr;
			wdata_reg<=wdata;
			write_reg<=write;
		end
		if(state==access && pready && !write_reg)begin
			rdata<=prdata;
		end
	end
end

always@(*)begin
	case(state)
		idle :next_state=(transfer)?setup:idle;
		setup:next_state=access;
		access:begin
			if(pready)begin
				if(transfer)begin
					next_state=setup;
				end
				else
					next_state=idle;
			end
			else
				next_state=access;
		end
		default:next_state=idle;
	endcase
end

always@(*)begin
	psel=0;
	penable=0;
	pwrite=write_reg;
	pwdata=wdate_reg;
	paddr=waddr_reg;

	case(state)
		idle:begin
			psel=0;
			penable=0;
		end

		setup:begin
			psel=1;
			penable=0;
		end

		access:begin
			psel=1;
			penable=1;
		end
	endcase
end
endmodule




