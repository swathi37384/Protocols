`timescale 1ns/1ps

module write(
    input        clk_50mhz,
    input        reset,
    input        start,
    input        more_data,
    input  [6:0] slave_addr,
    input  [7:0] pointer_addr,
    input  [7:0] data_in,
    output reg   busy,
    output reg   done,
    inout        scl,
    inout        sda
);

localparam IDLE          = 4'd0;
localparam START         = 4'd1;
localparam SLAVE_ADDR    = 4'd2;
localparam SLAVE_ACK     = 4'd3;
localparam POINTER_ADDR   = 4'd4;
localparam POINTER_ACK    = 4'd5;
localparam DATA           = 4'd6;
localparam DATA_ACK       = 4'd7;
localparam STOP           = 4'd8;

reg [3:0] state;

reg [6:0] addr_reg;
reg [7:0] pointer_reg;
reg [7:0] data_reg;

reg [3:0] bit_count;

reg [7:0] clk_count;
reg [2:0] phase_count;
reg       scl_phase;

reg       sda_delay_done;

reg       scl_oe;
reg       sda_oe;

assign scl = scl_oe ? 1'b0 : 1'bz;
assign sda = sda_oe ? 1'b0 : 1'bz;

always @(posedge clk_50mhz or posedge reset) begin

    if (reset) begin
        clk_count <= 8'd0;
    end
    else begin
        if (clk_count == 8'd49)
            clk_count <= 8'd0;
        else
            clk_count <= clk_count + 1'b1;
    end

end

wire timing_tick = (clk_count == 8'd49);

always @(posedge clk_50mhz or posedge reset) begin

    if (reset) begin

        state           <= IDLE;
        busy            <= 1'b0;
        done            <= 1'b0;

        addr_reg        <= 7'd0;
        pointer_reg     <= 8'd0;
        data_reg        <= 8'd0;

        bit_count       <= 4'd7;

        phase_count     <= 3'd0;
        scl_phase       <= 1'b0;
        sda_delay_done  <= 1'b0;

    end

    else if (timing_tick) begin

        case (state)

            IDLE:
            begin
                busy <= 1'b0;
                done <= 1'b0;

                phase_count    <= 3'd0;
                scl_phase      <= 1'b0;
                sda_delay_done <= 1'b0;

                if (start) begin

                    busy <= 1'b1;

                    addr_reg    <= slave_addr;
                    pointer_reg <= pointer_addr;
                    data_reg    <= data_in;

                    bit_count <= 4'd7;

                    state <= START;

                end
            end


            START:
            begin

                busy <= 1'b1;

                if (phase_count < 3'd4) begin
                    phase_count <= phase_count + 1'b1;
                end
                else begin

                    phase_count    <= 3'd0;
                    scl_phase      <= 1'b0;
                    sda_delay_done <= 1'b0;

                    bit_count <= 4'd7;

                    state <= SLAVE_ADDR;

                end

            end


            SLAVE_ADDR:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (!sda_delay_done) begin
                        sda_delay_done <= 1'b1;
                    end

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end
                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;

                        if (bit_count == 0) begin

                            bit_count <= 4'd7;
                            state <= SLAVE_ACK;

                        end
                        else begin

                            bit_count <= bit_count - 1'b1;

                        end

                    end

                end

            end


            SLAVE_ACK:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;
                        bit_count      <= 4'd7;

                        state <= POINTER_ADDR;

                    end

                end

            end


            POINTER_ADDR:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (!sda_delay_done) begin
                        sda_delay_done <= 1'b1;
                    end

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;

                        if (bit_count == 0) begin

                            bit_count <= 4'd7;
                            state <= POINTER_ACK;

                        end
                        else begin

                            bit_count <= bit_count - 1'b1;

                        end

                    end

                end

            end


            POINTER_ACK:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;
                        bit_count      <= 4'd7;

                        state <= DATA;

                    end

                end

            end


            DATA:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (!sda_delay_done) begin
                        sda_delay_done <= 1'b1;
                    end

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;

                        if (bit_count == 0) begin

                            bit_count <= 4'd7;
                            state <= DATA_ACK;

                        end
                        else begin

                            bit_count <= bit_count - 1'b1;

                        end

                    end

                end

            end


            DATA_ACK:
            begin

                busy <= 1'b1;

                if (scl_phase == 1'b0) begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count <= 3'd0;
                        scl_phase  <= 1'b1;

                    end

                end

                else begin

                    if (phase_count < 3'd4) begin
                        phase_count <= phase_count + 1'b1;
                    end

                    else begin

                        phase_count    <= 3'd0;
                        scl_phase      <= 1'b0;
                        sda_delay_done <= 1'b0;

                        state <= STOP;

                    end

                end

            end


            STOP:
            begin

                busy <= 1'b1;

                if (phase_count < 3'd4) begin

                    phase_count <= phase_count + 1'b1;

                end

                else begin

                    phase_count <= 3'd0;

                    busy <= 1'b0;
                    done <= 1'b1;

                    state <= IDLE;

                end

            end


            default:
            begin

                state <= IDLE;
                busy  <= 1'b0;
                done  <= 1'b0;
            end

        endcase

    end

end


always @(*) begin

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


        SLAVE_ADDR:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            if (sda_delay_done) begin

                if (addr_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;

            end
            else begin

                sda_oe = 1'b0;

            end

        end


        SLAVE_ACK:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            sda_oe = 1'b0;

        end


        POINTER_ADDR:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            if (sda_delay_done) begin

                if (pointer_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;

            end
            else begin

                sda_oe = 1'b0;

            end

        end


        POINTER_ACK:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            sda_oe = 1'b0;

        end


        DATA:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            if (sda_delay_done) begin

                if (data_reg[bit_count] == 1'b0)
                    sda_oe = 1'b1;
                else
                    sda_oe = 1'b0;

            end
            else begin

                sda_oe = 1'b0;

            end

        end


        DATA_ACK:
        begin

            if (scl_phase == 1'b0)
                scl_oe = 1'b1;
            else
                scl_oe = 1'b0;

            sda_oe = 1'b0;

        end


        STOP:
        begin

            scl_oe = 1'b0;
            sda_oe = 1'b1;
        end


        default:
        begin
            scl_oe = 1'b0;
            sda_oe = 1'b0;
        end

    endcase

end

endmodule
