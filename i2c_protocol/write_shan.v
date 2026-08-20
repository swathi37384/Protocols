`timescale 1ns/1ps

module I2C_protocol #(
    parameter CLK_DIV = 50
)(
    input        clk,
    input        rst_n,
    input        start,

    input  [6:0] addr,
    input  [7:0] data,

    inout        scl,
    inout        sda,

    output reg   busy,
    output reg   ack_error
);

    //========================================================
    // STATE DECLARATION
    //========================================================
    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;

    localparam ADDR_LOW   = 4'd2;
    localparam ADDR_HIGH  = 4'd3;

    localparam ACK1_LOW   = 4'd4;
    localparam ACK1_HIGH  = 4'd5;

    localparam DATA_LOW   = 4'd6;
    localparam DATA_HIGH  = 4'd7;

    localparam ACK2_LOW   = 4'd8;
    localparam ACK2_HIGH  = 4'd9;

    localparam STOP_LOW   = 4'd10;
    localparam STOP_HIGH  = 4'd11;

    reg [3:0] state;

    //========================================================
    // REGISTERS
    //========================================================

    reg [7:0] addr_reg;
    reg [7:0] data_reg;

    reg [3:0] bit_cnt;

    // SDA control
    reg sda_oe;
    reg sda_out;

    // SCL control
    reg scl_oe;

    // Clock divider
    reg [15:0] clk_count;

    wire tick;

    assign tick = (clk_count == CLK_DIV-1);


    //========================================================
    // I2C OPEN-DRAIN OUTPUTS
    //========================================================

    /*
        SDA:
        sda_oe = 1 and sda_out = 0 -> drive LOW
        otherwise                    -> release

        Pull-up makes released SDA HIGH.
    */

    assign sda = (sda_oe && (sda_out == 1'b0))
                 ? 1'b0
                 : 1'bz;


    /*
        SCL:
        scl_oe = 1 -> drive LOW
        scl_oe = 0 -> release

        Pull-up makes released SCL HIGH.
    */

    assign scl = scl_oe ? 1'b0 : 1'bz;


    //========================================================
    // CLOCK DIVIDER
    //========================================================

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            clk_count <= 16'd0;
        end

        else
        begin
            if (clk_count == CLK_DIV-1)
                clk_count <= 16'd0;
            else
                clk_count <= clk_count + 1'b1;
        end

    end


    //========================================================
    // MAIN FSM
    //========================================================

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin

            state     <= IDLE;

            addr_reg  <= 8'd0;
            data_reg  <= 8'd0;

            bit_cnt   <= 4'd7;

            sda_oe    <= 1'b0;
            sda_out   <= 1'b1;

            scl_oe    <= 1'b0;

            busy      <= 1'b0;
            ack_error <= 1'b0;
        end

        else if (tick)
        begin

            case (state)

                //================================================
                // IDLE
                //================================================
                IDLE:
                begin

                    // Release both lines
                    scl_oe <= 1'b0;
                    sda_oe <= 1'b0;

                    busy <= 1'b0;

                    if (start)
                    begin

                        busy <= 1'b1;

                        addr_reg <= {addr,1'b0};

                        data_reg <= data;

                        bit_cnt <= 4'd7;

                        ack_error <= 1'b0;

                        state <= START;

                    end

                end


                //================================================
                // START
                //
                // SDA HIGH -> LOW
                // while SCL HIGH
                //================================================
                START:
                begin

                    // SCL released -> HIGH
                    scl_oe <= 1'b0;

                    // SDA driven LOW
                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;

                    bit_cnt <= 4'd7;

                    state <= ADDR_LOW;

                end


                //================================================
                // ADDRESS LOW
                //
                // SCL LOW
                // Change SDA here
                //================================================
                ADDR_LOW:
                begin

                    // Drive SCL LOW
                    scl_oe <= 1'b1;

                    // Put address bit on SDA
                    sda_out <= addr_reg[bit_cnt];

                    // Enable SDA control
                    sda_oe <= 1'b1;

                    state <= ADDR_HIGH;

                end


                //================================================
                // ADDRESS HIGH
                //
                // SCL HIGH
                // Slave samples SDA
                //================================================
                ADDR_HIGH:
                begin

                    // Release SCL -> HIGH
                    scl_oe <= 1'b0;

                    if (bit_cnt == 0)
                    begin
                        state <= ACK1_LOW;
                    end

                    else
                    begin

                        bit_cnt <= bit_cnt - 1'b1;

                        state <= ADDR_LOW;

                    end

                end


                //================================================
                // ADDRESS ACK LOW
                //
                // SCL LOW
                // Master releases SDA
                //================================================
                ACK1_LOW:
                begin

                    // SCL LOW
                    scl_oe <= 1'b1;

                    // Release SDA
                    sda_oe <= 1'b0;

                    state <= ACK1_HIGH;

                end


                //================================================
                // ADDRESS ACK HIGH
                //
                // SCL HIGH
                // Master samples ACK
                //================================================
                ACK1_HIGH:
                begin

                    // Release SCL -> HIGH
                    scl_oe <= 1'b0;

                    if (sda == 1'b0)
                    begin

                        // ACK received
                        bit_cnt <= 4'd7;

                        state <= DATA_LOW;

                    end

                    else
                    begin

                        // NACK
                        ack_error <= 1'b1;

                        state <= STOP_LOW;

                    end

                end


                //================================================
                // DATA LOW
                //
                // SCL LOW
                // Change SDA here
                //================================================
                DATA_LOW:
                begin

                    // SCL LOW
                    scl_oe <= 1'b1;

                    // Put data bit on SDA
                    sda_out <= data_reg[bit_cnt];

                    sda_oe <= 1'b1;

                    state <= DATA_HIGH;

                end


                //================================================
                // DATA HIGH
                //
                // SCL HIGH
                // Slave samples data
                //================================================
                DATA_HIGH:
                begin

                    // Release SCL -> HIGH
                    scl_oe <= 1'b0;

                    if (bit_cnt == 0)
                    begin

                        state <= ACK2_LOW;

                    end

                    else
                    begin

                        bit_cnt <= bit_cnt - 1'b1;

                        state <= DATA_LOW;

                    end

                end


                //================================================
                // DATA ACK LOW
                //
                // SCL LOW
                // Release SDA
                //================================================
                ACK2_LOW:
                begin

                    // SCL LOW
                    scl_oe <= 1'b1;

                    // Release SDA
                    sda_oe <= 1'b0;

                    state <= ACK2_HIGH;

                end


                //================================================
                // DATA ACK HIGH
                //
                // SCL HIGH
                // Check ACK
                //================================================
                ACK2_HIGH:
                begin

                    // Release SCL -> HIGH
                    scl_oe <= 1'b0;

                    if (sda == 1'b0)
                    begin

                        // ACK received
                        state <= STOP_LOW;

                    end

                    else
                    begin

                        // NACK
                        ack_error <= 1'b1;

                        state <= STOP_LOW;

                    end

                end


                //================================================
                // STOP LOW
                //
                // SCL LOW
                // SDA LOW
                //================================================
                STOP_LOW:
                begin

                    // Drive SCL LOW
                    scl_oe <= 1'b1;

                    // Drive SDA LOW
                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;

                    state <= STOP_HIGH;

                end


                //================================================
                // STOP HIGH
                //
                // First release SCL
                // Then release SDA
                //
                // SDA LOW -> HIGH while SCL HIGH
                //================================================
                STOP_HIGH:
                begin

                    // Release SCL
                    scl_oe <= 1'b0;

                    // Release SDA
                    sda_oe <= 1'b0;

                    busy <= 1'b0;

                    state <= IDLE;

                end


                //================================================
                // DEFAULT
                //================================================
                default:
                begin

                    state <= IDLE;

                    bit_cnt <= 4'd7;

                    sda_oe <= 1'b0;
                    scl_oe <= 1'b0;

                    busy <= 1'b0;
                    ack_error <= 1'b0;

                end

            endcase

        end

    end

endmodule
