`timescale 1ns/1ps

module tb_write;

    //================================================
    // 1. TESTBENCH SIGNALS
    //================================================

    reg clk;
    reg rst;
    reg s;
    reg rw;

    reg [6:0] slave_add;
    reg [7:0] pointer_add;
    reg [7:0] tx_data;

    wire busy;
    wire done;
    wire ack_error;

    wire sda;
    wire scl;


    //================================================
    // 2. SLAVE ACK CONTROL
    //================================================

    reg slave_sda;

    // Slave can only pull SDA LOW.
    // When slave_sda = 1, slave releases SDA.

    assign sda = (slave_sda == 1'b0) ? 1'b0 : 1'bz;

    // Slave does not control SCL in this simple testbench
    assign scl = 1'bz;


    //================================================
    // 3. DUT INSTANTIATION
    //================================================

    write dut (

        .clk        (clk),
        .rst        (rst),
        .s          (s),
        .rw         (rw),

        .slave_add  (slave_add),
        .pointer_add(pointer_add),
        .tx_data    (tx_data),

        .busy       (busy),
        .done       (done),
        .ack_error  (ack_error),

        .sda        (sda),
        .scl        (scl)

    );


    //================================================
    // 4. CLOCK GENERATION
    //================================================

    // 10 ns clock period
    // Frequency = 100 MHz

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    //================================================
    // 5. I2C PULL-UP
    //================================================

    // I2C lines need pull-up resistors.

    pullup(sda);
    pullup(scl);


    //================================================
    // 6. TEST SEQUENCE
    //================================================

    initial begin

        // Initial values

        rst        = 1'b1;
        s          = 1'b0;
        rw         = 1'b0;       // 0 = WRITE

        slave_add  = 7'b1010000;
        pointer_add = 8'h10;
        tx_data     = 8'hA5;

        slave_sda  = 1'b1;       // Slave releases SDA


        // Reset
        #100;

        rst = 1'b0;


        // Wait a little
        #100;


        // Start write transaction
        s = 1'b1;


        // Keep start request active for one clock
        #10;

        s = 1'b0;


        // Wait until transaction finishes
        wait(done == 1'b1);


        #100;

        $finish;

    end


    //================================================
    // 7. SIMPLE SLAVE ACK GENERATION
    //================================================


    reg [3:0] ack_count;


    initial begin

        ack_count = 4'd0;

        forever begin

            // Wait for SCL rising edge

            @(posedge scl);


            /*
               Master releases SDA during ACK.

               If SDA is released, slave pulls it LOW.
            */

            if (dut.state == dut.ACK_ADDR ||
                dut.state == dut.ACK_POINTER ||
                dut.state == dut.ACK_DATA) begin

                slave_sda = 1'b0;

            end

            else begin

                slave_sda = 1'b1;

            end


            // Wait for SCL falling edge

            @(negedge scl);


            // Release SDA after ACK

            slave_sda = 1'b1;

        end

    end


    //================================================
    // 8. MONITOR
    //================================================

    initial begin

        $monitor(
            "TIME=%0t | CLK=%b | SCL=%b | SDA=%b | STATE=%0d | BUSY=%b | DONE=%b | ACK_ERR=%b",
            $time,
            clk,
            scl,
            sda,
            dut.state,
            busy,
            done,
            ack_error
        );

    end


    //================================================
    // 9. WAVEFORM DUMP
    //================================================

    initial begin

        $dumpfile("i2c_write.vcd");

        $dumpvars(0, tb_write);

    end

endmodule
