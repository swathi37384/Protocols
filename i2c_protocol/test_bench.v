`timescale 1ns/1ps

module top;

    //==================================================
    // SIGNALS
    //==================================================

    reg clk_50mhz;
    reg reset;
    reg start;
    reg rw;
    reg more_data;

    reg [6:0] slave_addr;
    reg [7:0] pointer_addr;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire busy;
    wire done;

    wire scl;
    wire sda;


    //==================================================
    // I2C BUS
    //==================================================

    pullup(scl);
    pullup(sda);


    //==================================================
    // TOP MODULE
    //==================================================

    top_module uut (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start),
        .rw           (rw),
        .more_data    (more_data),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_in      (data_in),
        .data_out     (data_out),
        .busy         (busy),
        .done          (done),
        .scl          (scl),
        .sda          (sda)
    );


    //==================================================
    // 50 MHz CLOCK
    //==================================================

    initial begin
        clk_50mhz = 1'b0;

        forever #10 clk_50mhz = ~clk_50mhz;
    end


    //==================================================
    // SLAVE MODEL
    //==================================================

    reg slave_sda_oe;

    reg [7:0] rx_byte;
    reg [7:0] slave_data;

    integer i;


    // Slave can only pull SDA LOW
    assign sda = slave_sda_oe ? 1'b0 : 1'bz;


    //==================================================
    // INITIAL SLAVE VALUES
    //==================================================

    initial begin

        slave_sda_oe = 1'b0;

        rx_byte = 8'h00;

        // Data which slave will send during READ
        slave_data = 8'hB6;

    end


    //==================================================
    // RECEIVE ONE BYTE
    //==================================================

    task receive_byte;

        begin

            for(i = 7; i >= 0; i = i - 1) begin

                // SDA is stable while SCL is HIGH
                wait(scl == 1'b0);

                wait(scl == 1'b1);

                rx_byte[i] = sda;

            end

            wait(scl == 1'b0);

        end

    endtask


    //==================================================
    // SLAVE ACK
    //==================================================

    task slave_ack;

        begin

            // Slave pulls SDA LOW
            slave_sda_oe = 1'b1;

            // Wait for ACK clock
            wait(scl == 1'b1);

            wait(scl == 1'b0);

            // Release SDA
            slave_sda_oe = 1'b0;

        end

    endtask


    //==================================================
    // SLAVE SEND ONE BYTE
    //==================================================

    task send_byte;

        begin

            for(i = 7; i >= 0; i = i - 1) begin

                // Change SDA only when SCL is LOW
                wait(scl == 1'b0);

                if(slave_data[i] == 1'b0)
                    slave_sda_oe = 1'b1;
                else
                    slave_sda_oe = 1'b0;

                // Hold SDA while SCL is HIGH
                wait(scl == 1'b1);

            end

            // Release SDA after 8 bits
            wait(scl == 1'b0);

            slave_sda_oe = 1'b0;

        end

    endtask


    //==================================================
    // SLAVE OPERATION
    //==================================================

    initial begin

        //================================================
        // WAIT FOR WRITE START
        //================================================

        wait(scl == 1'b1);
        wait(sda == 1'b0);

        $display("");
        $display("==========================================");
        $display("SLAVE: WRITE START DETECTED");
        $display("==========================================");


        //================================================
        // WRITE ADDRESS + W
        //================================================

        receive_byte;

        $display("SLAVE: ADDRESS + W = %h", rx_byte);

        slave_ack;


        //================================================
        // WRITE POINTER
        //================================================

        receive_byte;

        $display("SLAVE: POINTER = %h", rx_byte);

        slave_ack;


        //================================================
        // WRITE DATA
        //================================================

        receive_byte;

        $display("SLAVE: DATA = %h", rx_byte);

        if(rx_byte == 8'hB6)
            $display("SLAVE: WRITE DATA CORRECT");
        else
            $display("SLAVE: WRITE DATA WRONG");

        slave_ack;


        //================================================
        // WAIT FOR WRITE STOP
        //================================================

        wait(scl == 1'b1);
        wait(sda == 1'b1);

        $display("");
        $display("==========================================");
        $display("SLAVE: WRITE COMPLETE");
        $display("==========================================");


        //================================================
        // WAIT FOR READ START
        //================================================

        wait(scl == 1'b1);
        wait(sda == 1'b0);

        $display("");
        $display("==========================================");
        $display("SLAVE: READ START DETECTED");
        $display("==========================================");


        //================================================
        // READ ADDRESS + W
        //================================================

        receive_byte;

        $display("SLAVE: READ ADDRESS + W = %h", rx_byte);

        slave_ack;


        //================================================
        // READ POINTER
        //================================================

        receive_byte;

        $display("SLAVE: READ POINTER = %h", rx_byte);

        slave_ack;


        //================================================
        // WAIT FOR REPEATED START
        //================================================

        wait(scl == 1'b1);
        wait(sda == 1'b0);

        $display("");
        $display("==========================================");
        $display("SLAVE: REPEATED START DETECTED");
        $display("==========================================");


        //================================================
        // READ ADDRESS + R
        //================================================

        receive_byte;

        $display("SLAVE: READ ADDRESS + R = %h", rx_byte);

        slave_ack;


        //================================================
        // SLAVE SEND DATA
        //================================================

        slave_data = 8'hB6;

        $display("SLAVE: SENDING DATA = %h", slave_data);

        send_byte;


        //================================================
        // MASTER NACK
        //================================================

        wait(scl == 1'b1);

        if(sda == 1'b1)
            $display("SLAVE: MASTER NACK");
        else
            $display("SLAVE: MASTER ACK");

        wait(scl == 1'b0);

        slave_sda_oe = 1'b0;


        //================================================
        // READ COMPLETE
        //================================================

        $display("");
        $display("==========================================");
        $display("SLAVE: READ COMPLETE");
        $display("==========================================");

    end


    //==================================================
    // MASTER TEST
    //==================================================

    initial begin

        //================================================
        // VCD
        //================================================

        $dumpfile("i2c_top.vcd");
        $dumpvars(0, top);


        //================================================
        // INITIAL VALUES
        //================================================

        reset = 1'b1;

        start = 1'b0;

        rw = 1'b0;

        more_data = 1'b0;

        slave_addr = 7'h50;

        pointer_addr = 8'h30;

        data_in = 8'hB6;


        //================================================
        // RESET
        //================================================

        #100;

        reset = 1'b0;

        #100;


        //================================================
        // WRITE OPERATION
        //================================================

        $display("");
        $display("==========================================");
        $display("MASTER: START WRITE");
        $display("==========================================");

        // rw = 0 means WRITE
        rw = 1'b0;

        slave_addr = 7'h50;

        pointer_addr = 8'h30;

        data_in = 8'hB6;

        more_data = 1'b0;


        // Start WRITE
        start = 1'b1;

        // Wait until write becomes busy
        wait(busy == 1'b1);

        // Remove start
        start = 1'b0;

        // Wait until WRITE is complete
        wait(done == 1'b1);

        $display("");
        $display("MASTER: WRITE DONE");


        //================================================
        // WAIT BETWEEN WRITE AND READ
        //================================================

        #1000;


        //================================================
        // READ OPERATION
        //================================================

        $display("");
        $display("==========================================");
        $display("MASTER: START READ");
        $display("==========================================");

        // rw = 1 means READ
        rw = 1'b1;

        slave_addr = 7'h50;

        pointer_addr = 8'h30;


        // Start READ
        start = 1'b1;

        // Wait until read becomes busy
        wait(busy == 1'b1);

        // Remove start
        start = 1'b0;

        // Wait until READ is complete
        wait(done == 1'b1);


        //================================================
        // READ RESULT
        //================================================

        $display("");
        $display("MASTER: READ DONE");

        $display("MASTER: DATA READ = %h", data_out);


        //================================================
        // CHECK RESULT
        //================================================

        if(data_out == 8'hB6) begin

            $display("");
            $display("==========================================");
            $display("             TEST PASSED");
            $display("==========================================");

            $display("WRITE DATA = B6");
            $display("READ DATA  = B6");

            $display("==========================================");

        end

        else begin

            $display("");
            $display("==========================================");
            $display("             TEST FAILED");
            $display("==========================================");

            $display("EXPECTED DATA = B6");
            $display("ACTUAL DATA   = %h", data_out);

            $display("==========================================");

        end


        #1000;

        $finish;

    end


    //==================================================
    // SIMPLE MONITOR
    //==================================================

    initial begin

        forever begin

            #1000;

            $display(
                "TIME=%0t | SCL=%b | SDA=%b | RW=%b | START=%b | BUSY=%b | DONE=%b | DATA=%h",
                $time,
                scl,
                sda,
                rw,
                start,
                busy,
                done,
                data_out
            );

        end

    end

endmodule
