`timescale 1ns/1ps

module tb_I2C_protocol;

    //========================================================
    // CLOCK / RESET
    //========================================================

    reg clk;
    reg rst_n;

    //========================================================
    // MASTER INPUTS
    //========================================================

    reg start;

    reg [6:0] addr;
    reg [7:0] data;

    //========================================================
    // I2C BUS
    //========================================================

    wire scl;
    wire sda;

    //========================================================
    // MASTER OUTPUTS
    //========================================================

    wire busy;
    wire ack_error;


    //========================================================
    // PULL-UP RESISTORS
    //========================================================

    pullup(scl);
    pullup(sda);


    //========================================================
    // MASTER
    //========================================================

    I2C_protocol #(
        .CLK_DIV(50)
    )
    master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .addr(addr),
        .data(data),
        .scl(scl),
        .sda(sda),
        .busy(busy),
        .ack_error(ack_error)
    );


    //========================================================
    // SIMPLE SLAVE
    //========================================================

    reg slave_sda_drive;

    reg [7:0] slave_shift;

    reg [3:0] slave_bit_count;

    reg [7:0] received_data;

    reg [6:0] received_addr;

    reg slave_ack_phase;


    // Slave drives LOW when ACK is required
    assign sda = slave_sda_drive ? 1'b0 : 1'bz;


    //========================================================
    // SLAVE INITIALIZATION
    //========================================================

    initial
    begin

        slave_sda_drive = 1'b0;

        slave_shift = 8'd0;

        slave_bit_count = 4'd0;

        received_data = 8'd0;

        received_addr = 7'd0;

        slave_ack_phase = 1'b0;

    end


    //========================================================
    // SLAVE RECEIVES DATA
    //
    // SDA is sampled on SCL rising edge
    //========================================================

    always @(posedge scl)
    begin

        if (rst_n)
        begin

            slave_shift[slave_bit_count] <= sda;

            slave_bit_count <= slave_bit_count + 1'b1;

        end

    end


    //========================================================
    // SLAVE ACK CONTROL
    //
    // ACK is driven LOW during the ACK clock
    //========================================================

    always @(negedge scl)
    begin

        if (rst_n)
        begin

            if (slave_bit_count == 8)
            begin

                // First byte = address + R/W
                if (!slave_ack_phase)
                begin

                    received_addr <= slave_shift[7:1];

                    if ((slave_shift[7:1] == 7'h50) &&
                        (slave_shift[0] == 1'b0))
                    begin

                        // ACK address
                        slave_sda_drive <= 1'b1;

                    end

                    else
                    begin

                        // NACK wrong address
                        slave_sda_drive <= 1'b0;

                    end

                    slave_ack_phase <= 1'b1;

                end

                // Second byte = DATA
                else
                begin

                    received_data <= slave_shift;

                    // ACK data
                    slave_sda_drive <= 1'b1;

                end

                slave_bit_count <= 4'd0;

            end

            else
            begin

                // Release SDA after ACK
                slave_sda_drive <= 1'b0;

            end

        end

    end


    //========================================================
    // CLOCK GENERATION
    //========================================================

    initial
    begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //========================================================
    // TEST SEQUENCE
    //========================================================

    initial
    begin

        rst_n = 1'b0;

        start = 1'b0;

        addr = 7'h50;

        data = 8'hA5;

        #100;

        rst_n = 1'b1;

        #100;

        // Start I2C transaction
        start = 1'b1;

        #20;

        start = 1'b0;

        // Wait for transaction
        wait(busy == 1'b1);

        wait(busy == 1'b0);

        #100;

        $display("--------------------------------------");
        $display("I2C TRANSACTION FINISHED");
        $display("Slave Address = %h", received_addr);
        $display("Received Data  = %h", received_data);
        $display("ACK Error      = %b", ack_error);
        $display("--------------------------------------");

        #100;

        $finish;

    end


    //========================================================
    // WAVEFORM
    //========================================================

    initial
    begin

        $dumpfile("i2.vcd");

        $dumpvars(0, tb_I2C_protocol);

    end

endmodule
