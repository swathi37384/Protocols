`timescale 1ns / 1ps

module tb_I2C_protocol;

    reg clk;
    reg rst_n;
    reg start;

    reg [6:0] addr;
    reg [7:0] data;

    wire scl;
    wire sda;

    wire busy;
    wire ack_error;

    reg slave_ack;


    //========================================================
    // Slave pulls SDA LOW when slave_ack = 1
    //========================================================
    assign sda = slave_ack ? 1'b0 : 1'bz;


    //========================================================
    // DUT
    //========================================================
    I2C_protocol uut
    (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .addr      (addr),
        .data      (data),
        .scl       (scl),
        .sda       (sda),
        .busy      (busy),
        .ack_error (ack_error)
    );


    //========================================================
    // 100 MHz clock
    //========================================================
    always #5 clk = ~clk;


    //========================================================
    // Test
    //========================================================
    initial
    begin

        clk       = 1'b0;
        rst_n     = 1'b0;
        start     = 1'b0;

        addr      = 7'b1010000;
        data      = 8'b10101010;

        slave_ack = 1'b0;


        //====================================================
        // RESET
        //====================================================
        #20;

        rst_n = 1'b1;


        //====================================================
        // START TRANSACTION
        //====================================================
        #20;

        start = 1'b1;

        #10;

        start = 1'b0;


        //====================================================
        // Wait until address ACK
        //====================================================
        @(posedge scl);

        // Wait until master releases SDA
        wait (uut.state == uut.ACK1_HIGH);

        slave_ack = 1'b1;

        // Keep ACK active for complete ACK clock
        @(negedge scl);

        slave_ack = 1'b0;


        //====================================================
        // Wait until DATA ACK
        //====================================================
        wait (uut.state == uut.ACK2_HIGH);

        slave_ack = 1'b1;

        @(negedge scl);

        slave_ack = 1'b0;


        //====================================================
        // Wait for STOP
        //====================================================
        wait (uut.state == uut.IDLE);

        #20;

        $finish;

    end


    //========================================================
    // VCD
    //========================================================
    initial
    begin
        $dumpfile("i2c_write.vcd");
        $dumpvars(0, tb_I2C_protocol);
    end


    //========================================================
    // Monitor
    //========================================================
    initial
    begin

        $monitor(
            "Time=%0t | START=%b | SCL=%b | SDA=%b | BUSY=%b | ACK_ERROR=%b | STATE=%0d",
            $time,
            start,
            scl,
            sda,
            busy,
            ack_error,
            uut.state
        );

    end

endmodule
