`timescale 1ns/1ps

module top;

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
// MASTER
//==================================================

top_module uut (
    .clk_50mhz(clk_50mhz),
    .reset(reset),
    .start(start),
    .rw(rw),
    .more_data(more_data),
    .slave_addr(slave_addr),
    .pointer_addr(pointer_addr),
    .data_in(data_in),
    .data_out(data_out),
    .busy(busy),
    .done(done),
    .scl(scl),
    .sda(sda)
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


// Slave can only pull SDA LOW.
// Otherwise SDA is released.
assign sda = slave_sda_oe ? 1'b0 : 1'bz;


//==================================================
// INITIAL SLAVE VALUES
//==================================================

initial begin

    slave_sda_oe = 1'b0;
    rx_byte      = 8'h00;

    // Data returned by slave during READ
    slave_data   = 8'hB6;

end


//==================================================
// RECEIVE 8-BIT BYTE
//==================================================

task receive_byte;

begin

    for(i = 7; i >= 0; i = i - 1) begin

        // SDA changes while SCL LOW
        wait(scl == 1'b0);

        // Sample SDA while SCL HIGH
        wait(scl == 1'b1);

        rx_byte[i] = sda;

    end

    wait(scl == 1'b0);

end

endtask


//==================================================
// SLAVE ACK
//==================================================

task ack;

begin

    // Pull SDA LOW
    slave_sda_oe = 1'b1;

    // ACK bit
    wait(scl == 1'b1);

    wait(scl == 1'b0);

    // Release SDA
    slave_sda_oe = 1'b0;

end

endtask


//==================================================
// SLAVE SEND BYTE
//==================================================

task send_byte;

begin

    for(i = 7; i >= 0; i = i - 1) begin

        // Change SDA only when SCL LOW
        wait(scl == 1'b0);

        if(slave_data[i] == 1'b0)
            slave_sda_oe = 1'b1;
        else
            slave_sda_oe = 1'b0;

        // Hold SDA during SCL HIGH
        wait(scl == 1'b1);

    end

    // Release SDA after 8 bits
    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

end

endtask


//==================================================
// SLAVE PROCESS
//==================================================

initial begin

    //------------------------------------------------
    // WAIT FOR WRITE START
    //------------------------------------------------

    wait(scl == 1'b1);
    wait(sda == 1'b0);

    $display("");
    $display("==========================================");
    $display("SLAVE: WRITE START DETECTED");
    $display("==========================================");


    //------------------------------------------------
    // RECEIVE ADDRESS + WRITE
    //------------------------------------------------

    receive_byte;

    $display("SLAVE: ADDRESS + W = %h", rx_byte);

    ack;


    //------------------------------------------------
    // RECEIVE POINTER
    //------------------------------------------------

    receive_byte;

    $display("SLAVE: POINTER = %h", rx_byte);

    ack;


    //------------------------------------------------
    // RECEIVE WRITE DATA
    //------------------------------------------------

    receive_byte;

    $display("SLAVE: WRITE DATA = %h", rx_byte);

    if(rx_byte == 8'hB6)
        $display("SLAVE: WRITE DATA CORRECT");
    else
        $display("SLAVE: WRITE DATA WRONG");

    ack;


    //------------------------------------------------
    // WAIT FOR WRITE STOP
    //------------------------------------------------

    wait(scl == 1'b1);
    wait(sda == 1'b1);

    $display("");
    $display("==========================================");
    $display("SLAVE: WRITE COMPLETE");
    $display("==========================================");


    //------------------------------------------------
    // WAIT FOR READ START / REPEATED START
    //------------------------------------------------

    wait(scl == 1'b1);
    wait(sda == 1'b0);

    $display("");
    $display("==========================================");
    $display("SLAVE: READ / REPEATED START DETECTED");
    $display("==========================================");


    //------------------------------------------------
    // RECEIVE ADDRESS + READ
    //------------------------------------------------

    receive_byte;

    $display("SLAVE: ADDRESS + R = %h", rx_byte);

    ack;


    //------------------------------------------------
    // SEND READ DATA
    //------------------------------------------------

    slave_data = 8'hB6;

    $display("SLAVE: SEND DATA = %h", slave_data);

    send_byte;


    //------------------------------------------------
    // CHECK MASTER ACK/NACK
    //------------------------------------------------

    wait(scl == 1'b1);

    if(sda == 1'b0)
        $display("SLAVE: MASTER ACK");
    else
        $display("SLAVE: MASTER NACK");

    wait(scl == 1'b0);

    slave_sda_oe = 1'b0;

end


//==================================================
// MASTER TEST
//==================================================

initial begin

    //------------------------------------------------
    // VCD
    //------------------------------------------------

    $dumpfile("i2c_top.vcd");
    $dumpvars(0, top);


    //------------------------------------------------
    // INITIAL VALUES
    //------------------------------------------------

    reset     = 1'b1;
    start     = 1'b0;
    rw        = 1'b0;
    more_data = 1'b0;

    slave_addr  = 7'h50;
    pointer_addr = 8'h30;
    data_in      = 8'hB6;


    //------------------------------------------------
    // RESET
    //------------------------------------------------

    #100;

    reset = 1'b0;

    #100;


    //================================================
    // WRITE
    //================================================

    $display("");
    $display("==========================================");
    $display("MASTER: START WRITE");
    $display("==========================================");

    rw = 1'b0;

    slave_addr   = 7'h50;
    pointer_addr = 8'h30;
    data_in      = 8'hB6;

    start = 1'b1;

    wait(busy == 1'b1);

    start = 1'b0;

    wait(done == 1'b1);

    $display("");
    $display("MASTER: WRITE DONE");


    //------------------------------------------------
    // WAIT BEFORE READ
    //------------------------------------------------

    #1000;


    //================================================
    // READ
    //================================================

    $display("");
    $display("==========================================");
    $display("MASTER: START READ");
    $display("==========================================");

    rw = 1'b1;

    slave_addr   = 7'h50;
    pointer_addr = 8'h30;

    start = 1'b1;

    wait(busy == 1'b1);

    start = 1'b0;

    wait(done == 1'b1);


    //------------------------------------------------
    // READ RESULT
    //------------------------------------------------

    $display("");
    $display("MASTER: READ DONE");
    $display("MASTER: DATA READ = %h", data_out);


    //------------------------------------------------
    // CHECK RESULT
    //------------------------------------------------

    if(data_out == 8'hB6) begin

        $display("");
        $display("==========================================");
        $display("          TEST PASSED");
        $display("==========================================");
        $display("WRITE DATA = B6");
        $display("READ DATA  = B6");
        $display("==========================================");

    end
    else begin

        $display("");
        $display("==========================================");
        $display("          TEST FAILED");
        $display("==========================================");
        $display("EXPECTED DATA = B6");
        $display("ACTUAL DATA   = %h", data_out);
        $display("==========================================");

    end


    #1000;

    $finish;

end


//==================================================
// MONITOR
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
