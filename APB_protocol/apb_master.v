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
output [7:0]rdata,
output reg pwrite,
output reg penable);

parameter idle =2'd0,
	setup=2'd1,
	access=2'd2;
reg [1:0]state,next_state;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		state<=idle;
		psel<=0;
		paddr<=8'd0;
		pwdata<=8'd0;
		pwrite<=0;
		penable<=0;
		
	end
	else begin
		state<=next_state;
	end
end
always@(*)begin
		case(state)
			idle:begin
				psel=0;
				penable=0;
			end

			setup :begin
			       psel=1;
		               penable=0;
			       paddr=addr;
                               pwdata=wdata;
                               pwrite=write;
		       end

		       access:begin
			       psel=1;
			       penable=1;
		       end

		       default:begin
			       psel=0;
			       penable=0;
		       end
	       endcase
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

assign rdata = (!pwrite && psel && penable) ? prdata : 8'h00;

endmodule
