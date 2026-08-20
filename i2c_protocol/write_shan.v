module I2C_protocol(
    input clk,
    input rst_n,
    input start,
    input [6:0] addr,
    input [7:0] data,

    inout scl,
    inout sda,

    output reg busy,
    output reg ack_error
);

    //========================================================
    // Registers
    //========================================================
    reg [3:0] state;
    reg [3:0] bit_cnt;

    reg sda_out;
    reg sda_oe;

    reg scl_out;
    reg scl_oe;

    reg [7:0] addr_reg;
    reg [7:0] data_reg;


    //========================================================
    // Open-drain SDA and SCL
    //========================================================
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;


    //========================================================
    // State declarations
    //========================================================
    localparam IDLE      = 4'd0;
    localparam START     = 4'd1;

    localparam ADDR_LOW  = 4'd2;
    localparam ADDR_HIGH = 4'd3;

    localparam ACK1_LOW  = 4'd4;
    localparam ACK1_HIGH = 4'd5;

    localparam DATA_LOW  = 4'd6;
    localparam DATA_HIGH = 4'd7;

    localparam ACK2_LOW  = 4'd8;
    localparam ACK2_HIGH = 4'd9;

    localparam STOP_LOW  = 4'd10;
    localparam STOP_HIGH = 4'd11;


    //========================================================
    // FSM
    //========================================================
    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            state     <= IDLE;

            bit_cnt   <= 4'd0;

            addr_reg  <= 8'd0;
            data_reg  <= 8'd0;

            sda_out   <= 1'b1;
            sda_oe    <= 1'b0;

            scl_out   <= 1'b1;
            scl_oe    <= 1'b1;

            busy      <= 1'b0;
            ack_error <= 1'b0;
        end

        else
        begin

            case (state)

                //================================================
                // IDLE
                //================================================
                IDLE:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

                    sda_out <= 1'b1;
                    sda_oe  <= 1'b0;

                    busy <= 1'b0;

                    if (start)
                    begin
                        busy      <= 1'b1;

                        addr_reg  <= {addr, 1'b0};
                        data_reg  <= data;

                        bit_cnt   <= 4'd7;

                        ack_error <= 1'b0;

                        state <= START;
                    end
                end


                //================================================
                // START CONDITION
                // SDA : 1 -> 0
                // while SCL = 1
                //================================================
                START:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;

                    bit_cnt <= 4'd7;

                    state <= ADDR_LOW;
                end


                //================================================
                // ADDRESS LOW
                // Put address bit on SDA while SCL is LOW
                //================================================
                ADDR_LOW:
                begin
                    scl_out <= 1'b0;
                    scl_oe  <= 1'b1;

                    sda_out <= addr_reg[bit_cnt];
                    sda_oe  <= 1'b1;

                    state <= ADDR_HIGH;
                end


                //================================================
                // ADDRESS HIGH
                // Slave samples address when SCL is HIGH
                //================================================
                ADDR_HIGH:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

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
                // Release SDA so slave can ACK
                //================================================
                ACK1_LOW:
                begin
                    scl_out <= 1'b0;
                    scl_oe  <= 1'b1;

                    sda_oe <= 1'b0;

                    state <= ACK1_HIGH;
                end


                //================================================
                // ADDRESS ACK HIGH
                // Slave drives SDA = 0 for ACK
                //================================================
                ACK1_HIGH:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

                    if (sda == 1'b0)
                    begin
                        bit_cnt <= 4'd7;

                        state <= DATA_LOW;
                    end

                    else
                    begin
                        ack_error <= 1'b1;

                        state <= STOP_LOW;
                    end
                end


                //================================================
                // DATA LOW
                // Put data bit on SDA while SCL is LOW
                //================================================
                DATA_LOW:
                begin
                    scl_out <= 1'b0;
                    scl_oe  <= 1'b1;

                    sda_out <= data_reg[bit_cnt];
                    sda_oe  <= 1'b1;

                    state <= DATA_HIGH;
                end


                //================================================
                // DATA HIGH
                // Slave samples data when SCL is HIGH
                //================================================
                DATA_HIGH:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

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
                // Release SDA for slave ACK
                //================================================
                ACK2_LOW:
                begin
                    scl_out <= 1'b0;
                    scl_oe  <= 1'b1;

                    sda_oe <= 1'b0;

                    state <= ACK2_HIGH;
                end


                //================================================
                // DATA ACK HIGH
                //================================================
                ACK2_HIGH:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

                    if (sda == 1'b0)
                    begin
                        state <= STOP_LOW;
                    end

                    else
                    begin
                        ack_error <= 1'b1;

                        state <= STOP_LOW;
                    end
                end


                //================================================
                // STOP LOW
                // Keep SDA LOW while SCL LOW
                //================================================
                STOP_LOW:
                begin
                    scl_out <= 1'b0;
                    scl_oe  <= 1'b1;

                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;

                    state <= STOP_HIGH;
                end


                //================================================
                // STOP HIGH
                // SDA : 0 -> 1 while SCL = 1
                //================================================
                STOP_HIGH:
                begin
                    scl_out <= 1'b1;
                    scl_oe  <= 1'b1;

                    sda_out <= 1'b1;
                    sda_oe  <= 1'b0;

                    busy <= 1'b0;

                    state <= IDLE;
                end


                //================================================
                // DEFAULT
                //================================================
                default:
                begin
                    state     <= IDLE;

                    bit_cnt   <= 4'd0;

                    addr_reg  <= 8'd0;
                    data_reg  <= 8'd0;

                    sda_out   <= 1'b1;
                    sda_oe    <= 1'b0;

                    scl_out   <= 1'b1;
                    scl_oe    <= 1'b1;

                    busy      <= 1'b0;
                    ack_error <= 1'b0;
                end

            endcase
        end
    end

endmodule
