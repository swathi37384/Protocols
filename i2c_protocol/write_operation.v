module i2c_write (
    input clk_50mhz,
    input reset,
    input start,
    input [6:0] slave_addr,
    input [7:0] pointer_addr,
    input [7:0] data_in,
    output reg busy,
    output reg done,
    inout scl,
    inout sda
);

    reg [7:0] clk_count;
    reg timing_tick;
    reg sda_oe;
    reg scl_oe;
    reg [7:0] data_reg;
    reg [7:0] pointer_reg;
    reg [7:0] addr_reg;
    reg [3:0] bit_count;

    parameter IDLE = 5'd0;
    parameter START = 5'd1;
    parameter ADDR_LOW = 5'd2;
    parameter ADDR_HIGH = 5'd3;
    parameter ADDR_ACK_LOW = 5'd4;
    parameter ADDR_ACK_HIGH = 5'd5;
    parameter POINTER_LOW = 5'd6;
    parameter POINTER_HIGH = 5'd7;
    parameter POINTER_ACK_LOW = 5'd8;
    parameter POINTER_ACK_HIGH = 5'd9;
    parameter DATA_LOW = 5'd10;
    parameter DATA_HIGH = 5'd11;
    parameter DATA_ACK_LOW = 5'd12;
    parameter DATA_ACK_HIGH = 5'd13;
    parameter STOP_LOW = 5'd14;
    parameter STOP_HIGH = 5'd15;

    reg [4:0] state;
    reg [4:0] next_state;

    always @(posedge clk_50mhz or posedge reset)
    begin
        if (reset) begin
            clk_count <= 8'd0;
            timing_tick <= 1'b0;
        end
        else begin
            timing_tick <= 1'b0;

            if (clk_count == 8'd249) begin
                clk_count <= 8'd0;
                timing_tick <= 1'b1;
            end
            else begin
                clk_count <= clk_count + 1'b1;
            end
        end
    end

    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    always @(posedge clk_50mhz or posedge reset)
    begin
        if (reset) begin
            state <= IDLE;
            addr_reg <= 7'd0;
            pointer_reg <= 8'd0;
            data_reg <= 8'd0;
            bit_count <= 4'd7;
            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            if (timing_tick) begin

                state <= next_state;

                if ((state == IDLE) && start) begin
                    addr_reg <= {slave_addr,1'b0};
                    pointer_reg <= pointer_addr;
                    data_reg <= data_in;
                    bit_count <= 4'd7;
                    busy <= 1'b1;
                    done <= 1'b0;
                end

                else if (state == ADDR_HIGH) begin
                    if (bit_count != 0)
                        bit_count <= bit_count - 1'b1;
                    else
                        bit_count <= 4'd7;
                end

                else if (state == POINTER_HIGH) begin
                    if (bit_count != 0)
                        bit_count <= bit_count - 1'b1;
                    else
                        bit_count <= 4'd7;
                end

                else if (state == DATA_HIGH) begin
                    if (bit_count != 0)
                        bit_count <= bit_count - 1'b1;
                    else
                        bit_count <= 4'd7;
                end

                else if (state == STOP_HIGH) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

    always @(*)
    begin
        next_state = state;

        case (state)

            IDLE:
            begin
                if (start)
                    next_state = START;
                else
                    next_state = IDLE;
            end

            START:
            begin
                next_state = ADDR_LOW;
            end

            ADDR_LOW:
            begin
                next_state = ADDR_HIGH;
            end

            ADDR_HIGH:
            begin
                if (bit_count == 4'd0)
                    next_state = ADDR_ACK_LOW;
                else
                    next_state = ADDR_LOW;
            end

            ADDR_ACK_LOW:
            begin
                next_state = ADDR_ACK_HIGH;
            end

            ADDR_ACK_HIGH:
            begin
                if (sda == 1'b0)
                    next_state = POINTER_LOW;
                else
                    next_state = STOP_LOW;
            end

            POINTER_LOW:
            begin
                next_state = POINTER_HIGH;
            end

            POINTER_HIGH:
            begin
                if (bit_count == 4'd0)
                    next_state = POINTER_ACK_LOW;
                else
                    next_state = POINTER_LOW;
            end

            POINTER_ACK_LOW:
            begin
                next_state = POINTER_ACK_HIGH;
            end

            POINTER_ACK_HIGH:
            begin
                if (sda == 1'b0)
                    next_state = DATA_LOW;
                else
                    next_state = STOP_LOW;
            end

            DATA_LOW:
            begin
                next_state = DATA_HIGH;
            end

            DATA_HIGH:
            begin
                if (bit_count == 4'd0)
                    next_state = DATA_ACK_LOW;
                else
                    next_state = DATA_LOW;
            end

            DATA_ACK_LOW:
            begin
                next_state = DATA_ACK_HIGH;
            end

            DATA_ACK_HIGH:
            begin
                next_state = STOP_LOW;
            end

            STOP_LOW:
            begin
                next_state = STOP_HIGH;
            end

            STOP_HIGH:
            begin
                next_state = IDLE;
            end

            default:
            begin
                next_state = IDLE;
            end

        endcase
    end

    always @(*)
    begin
        scl_oe = 1'b0;
        sda_oe = 1'b0;

        case (state)

            IDLE:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            START:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b1;
            end

            ADDR_LOW:
            begin
                scl_oe = 1'b1;

                if (bit_count == 4'd0)
                    sda_oe = 1'b1;
                else if (addr_reg[bit_count ] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            ADDR_HIGH:
            begin
                scl_oe = 1'b0;

                if (bit_count == 4'd0)
                    sda_oe = 1'b1;
                else if (addr_reg[bit_count ] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            ADDR_ACK_LOW:
            begin
                scl_oe = 1'b1;
                sda_oe = 1'b0;
            end

            ADDR_ACK_HIGH:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            POINTER_LOW:
            begin
                scl_oe = 1'b1;

                if (pointer_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            POINTER_HIGH:
            begin
                scl_oe = 1'b0;

                if (pointer_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            POINTER_ACK_LOW:
            begin
                scl_oe = 1'b1;
                sda_oe = 1'b0;
            end

            POINTER_ACK_HIGH:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            DATA_LOW:
            begin
                scl_oe = 1'b1;

                if (data_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            DATA_HIGH:
            begin
                scl_oe = 1'b0;

                if (data_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;
            end

            DATA_ACK_LOW:
            begin
                scl_oe = 1'b1;
                sda_oe = 1'b0;
            end

            DATA_ACK_HIGH:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            STOP_LOW:
            begin
                scl_oe = 1'b1;
                sda_oe = 1'b1;
            end

            STOP_HIGH:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

            default:
            begin
                scl_oe = 1'b0;
                sda_oe = 1'b0;
            end

        endcase
    end

endmodule
