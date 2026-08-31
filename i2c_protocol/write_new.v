`timescale 1ns/1ps

module write (
    input        clk_50mhz,
    input        reset,
    input        start,
    input        more_data,
    input  [6:0]  slave_addr,
    input  [7:0]  pointer_addr,
    input  [7:0]  data_in,
    output reg   busy,
    output reg   done,
    inout        scl,
    inout        sda
);

    reg [7:0] clk_count;
    reg       timing_tick;

    reg       sda_oe;
    reg       scl_oe;

    reg [7:0] data_reg;
    reg [7:0] pointer_reg;
    reg [7:0] addr_reg;

    reg [3:0] bit_count;

    reg       scl_phase;

    // SDA setup delay flag
    reg       sda_setup_done;

    parameter IDLE           = 4'd0;
    parameter START          = 4'd1;
    parameter SLAVE_ADDR     = 4'd2;
    parameter SLAVE_ACK      = 4'd3;
    parameter POINTER_ADDR   = 4'd4;
    parameter POINTER_ACK    = 4'd5;
    parameter DATA           = 4'd6;
    parameter DATA_ACK       = 4'd7;
    parameter REPEATED_START = 4'd8;
    parameter STOP           = 4'd9;

    reg [3:0] state;
    reg [3:0] next_state;


    //========================================================
    // 50 MHz CLOCK DIVIDER
    // 50 MHz = 20 ns
    // 250 clocks = 5 us
    //========================================================

    always @(posedge clk_50mhz or posedge reset)
    begin
        if (reset) begin
            clk_count   <= 8'd0;
            timing_tick <= 1'b0;
        end
        else begin

            timing_tick <= 1'b0;

            if (clk_count == 8'd249) begin
                clk_count   <= 8'd0;
                timing_tick <= 1'b1;
            end
            else begin
                clk_count <= clk_count + 1'b1;
            end

        end
    end


    //========================================================
    // OPEN DRAIN I2C
    //========================================================

    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;


    //========================================================
    // STATE REGISTER + DATA PATH
    //========================================================

    always @(posedge clk_50mhz or posedge reset)
    begin

        if (reset) begin

            state          <= IDLE;

            addr_reg       <= 8'd0;
            pointer_reg    <= 8'd0;
            data_reg       <= 8'd0;

            bit_count      <= 4'd7;

            scl_phase      <= 1'b0;

            sda_setup_done <= 1'b0;

            busy           <= 1'b0;
            done           <= 1'b0;

        end

        else begin

            if (timing_tick) begin

                // State changes according to next_state
                state <= next_state;

                case (state)

                    //================================================
                    // IDLE
                    //================================================

                    IDLE:
                    begin

                        scl_phase      <= 1'b0;
                        sda_setup_done <= 1'b0;

                        busy <= 1'b0;
                        done <= 1'b0;

                        if (start) begin

                            addr_reg    <= {slave_addr,1'b0};
                            pointer_reg <= pointer_addr;
                            data_reg    <= data_in;

                            bit_count <= 4'd7;

                            busy <= 1'b1;
                            done <= 1'b0;

                        end

                    end


                    //================================================
                    // START
                    //================================================

                    START:
                    begin

                        scl_phase      <= 1'b0;
                        sda_setup_done <= 1'b0;

                        bit_count <= 4'd7;

                    end


                    //================================================
                    // SLAVE ADDRESS
                    //================================================

                    SLAVE_ADDR:
                    begin

                        if (scl_phase == 1'b0) begin

                            // SCL is LOW
                            // First wait for SDA setup delay

                            if (!sda_setup_done) begin
                                sda_setup_done <= 1'b1;
                            end
                            else begin
                                scl_phase <= 1'b1;
                            end

                        end

                        else begin

                            // SCL HIGH
                            // Complete one bit

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                            if (bit_count != 0)
                                bit_count <= bit_count - 1'b1;
                            else
                                bit_count <= 4'd7;

                        end

                    end


                    //================================================
                    // SLAVE ACK
                    //================================================

                    SLAVE_ACK:
                    begin

                        if (scl_phase == 1'b0) begin

                            scl_phase <= 1'b1;

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                        end

                    end


                    //================================================
                    // POINTER ADDRESS
                    //================================================

                    POINTER_ADDR:
                    begin

                        if (scl_phase == 1'b0) begin

                            if (!sda_setup_done) begin
                                sda_setup_done <= 1'b1;
                            end
                            else begin
                                scl_phase <= 1'b1;
                            end

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                            if (bit_count != 0)
                                bit_count <= bit_count - 1'b1;
                            else
                                bit_count <= 4'd7;

                        end

                    end


                    //================================================
                    // POINTER ACK
                    //================================================

                    POINTER_ACK:
                    begin

                        if (scl_phase == 1'b0) begin

                            scl_phase <= 1'b1;

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                        end

                    end


                    //================================================
                    // DATA
                    //================================================

                    DATA:
                    begin

                        if (scl_phase == 1'b0) begin

                            if (!sda_setup_done) begin
                                sda_setup_done <= 1'b1;
                            end
                            else begin
                                scl_phase <= 1'b1;
                            end

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                            if (bit_count != 0)
                                bit_count <= bit_count - 1'b1;
                            else
                                bit_count <= 4'd7;

                        end

                    end


                    //================================================
                    // DATA ACK
                    //================================================

                    DATA_ACK:
                    begin

                        if (scl_phase == 1'b0) begin

                            scl_phase <= 1'b1;

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                            if (more_data) begin

                                data_reg    <= data_in;
                                pointer_reg <= pointer_addr;
                                bit_count   <= 4'd7;

                            end

                        end

                    end


                    //================================================
                    // REPEATED START
                    //================================================

                    REPEATED_START:
                    begin

                        if (scl_phase == 1'b0) begin

                            scl_phase <= 1'b1;

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;
                            bit_count      <= 4'd7;

                        end

                    end


                    //================================================
                    // STOP
                    //================================================

                    STOP:
                    begin

                        if (scl_phase == 1'b0) begin

                            scl_phase <= 1'b1;

                        end

                        else begin

                            scl_phase      <= 1'b0;
                            sda_setup_done <= 1'b0;

                            busy <= 1'b0;
                            done <= 1'b1;

                        end

                    end


                    default:
                    begin

                        state <= IDLE;

                        scl_phase      <= 1'b0;
                        sda_setup_done <= 1'b0;

                        busy <= 1'b0;
                        done <= 1'b0;

                    end

                endcase

            end

        end

    end


    //========================================================
    // NEXT STATE LOGIC
    //========================================================

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

                next_state = SLAVE_ADDR;

            end


            SLAVE_ADDR:
            begin

                if ((scl_phase == 1'b1) &&
                    (bit_count == 4'd0))

                    next_state = SLAVE_ACK;

                else
                    next_state = SLAVE_ADDR;

            end


            SLAVE_ACK:
            begin

                if (scl_phase == 1'b1) begin

                    if (sda == 1'b0)
                        next_state = POINTER_ADDR;
                    else
                        next_state = STOP;

                end

                else begin

                    next_state = SLAVE_ACK;

                end

            end


            POINTER_ADDR:
            begin

                if ((scl_phase == 1'b1) &&
                    (bit_count == 4'd0))

                    next_state = POINTER_ACK;

                else
                    next_state = POINTER_ADDR;

            end


            POINTER_ACK:
            begin

                if (scl_phase == 1'b1) begin

                    if (sda == 1'b0)
                        next_state = DATA;
                    else
                        next_state = STOP;

                end

                else begin

                    next_state = POINTER_ACK;

                end

            end


            DATA:
            begin

                if ((scl_phase == 1'b1) &&
                    (bit_count == 4'd0))

                    next_state = DATA_ACK;

                else
                    next_state = DATA;

            end


            DATA_ACK:
            begin

                if (scl_phase == 1'b1) begin

                    if (more_data)
                        next_state = REPEATED_START;
                    else
                        next_state = STOP;

                end

                else begin

                    next_state = DATA_ACK;

                end

            end


            REPEATED_START:
            begin

                if (scl_phase == 1'b1)
                    next_state = SLAVE_ADDR;
                else
                    next_state = REPEATED_START;

            end


            STOP:
            begin

                if (scl_phase == 1'b1)
                    next_state = IDLE;
                else
                    next_state = STOP;

            end


            default:
            begin

                next_state = IDLE;

            end

        endcase

    end


    //========================================================
    // SDA / SCL OUTPUT CONTROL
    //========================================================

    always @(*)
    begin

        scl_oe = 1'b0;
        sda_oe = 1'b0;

        case (state)

            //================================================
            // IDLE
            //================================================

            IDLE:
            begin

                scl_oe = 1'b0;
                sda_oe = 1'b0;

            end


            //================================================
            // START
            //================================================

            START:
            begin

                // SCL HIGH
                // SDA LOW

                scl_oe = 1'b0;
                sda_oe = 1'b1;

            end


            //================================================
            // SLAVE ADDRESS
            //================================================

            SLAVE_ADDR:
            begin

                // SCL control

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;


                // SDA setup delay

                if (sda_setup_done) begin

                    if (addr_reg[bit_count] == 1'b0)
                        sda_oe = 1'b1;
                    else
                        sda_oe = 1'b0;

                end

                else begin

                    // SDA remains released during setup delay

                    sda_oe = 1'b0;

                end

            end


            //================================================
            // SLAVE ACK
            //================================================

            SLAVE_ACK:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                // Release SDA

                sda_oe = 1'b0;

            end


            //================================================
            // POINTER ADDRESS
            //================================================

            POINTER_ADDR:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;


                if (sda_setup_done) begin

                    if (pointer_reg[bit_count] == 1'b0)
                        sda_oe = 1'b1;
                    else
                        sda_oe = 1'b0;

                end

                else begin

                    sda_oe = 1'b0;

                end

            end


            //================================================
            // POINTER ACK
            //================================================

            POINTER_ACK:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                sda_oe = 1'b0;

            end


            //================================================
            // DATA
            //================================================

            DATA:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;


                if (sda_setup_done) begin

                    if (data_reg[bit_count] == 1'b0)
                        sda_oe = 1'b1;
                    else
                        sda_oe = 1'b0;

                end

                else begin

                    sda_oe = 1'b0;

                end

            end


            //================================================
            // DATA ACK
            //================================================

            DATA_ACK:
            begin

                if (scl_phase == 1'b0)
                    scl_oe = 1'b1;
                else
                    scl_oe = 1'b0;

                sda_oe = 1'b0;

            end


            //================================================
            // REPEATED START
            //================================================

            REPEATED_START:
            begin

                if (scl_phase == 1'b0) begin

                    // SCL LOW
                    scl_oe = 1'b1;

                    // SDA released
                    sda_oe = 1'b0;

                end

                else begin

                    // SCL HIGH
                    // SDA LOW

                    scl_oe = 1'b0;
                    sda_oe = 1'b1;

                end

            end


            //================================================
            // STOP
            //================================================

            STOP:
            begin

                if (scl_phase == 1'b0) begin

                    // SCL LOW
                    // SDA LOW

                    scl_oe = 1'b1;
                    sda_oe = 1'b1;

                end

                else begin

                    // SCL HIGH
                    // SDA LOW

                    scl_oe = 1'b0;
                    sda_oe = 1'b1;

                end

            end


            default:
            begin

                scl_oe = 1'b0;
                sda_oe = 1'b0;

            end

        endcase

    end

endmodule
