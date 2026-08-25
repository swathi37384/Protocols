`timescale 1ns/1ps

module i2c_read_tb;

reg clk_50mhz;
reg reset;
reg start;

reg [6:0] slave_addr;
reg [7:0] pointer_addr;

wire [7:0] data_out;
wire busy;
wire done;

wire scl;
wire sda;

reg slave_sda_oe;

reg [7:0] slave_read_data;

integer i;

//--------------------------------------------------
// DUT
//--------------------------------------------------

read uut (
    .clk_50mhz    (clk_50mhz),
    .reset        (reset),
    .start        (start),
    .slave_addr   (slave_addr),
    .pointer_addr (pointer_addr),
    .data_out     (data_out),
    .busy         (busy),
    .done         (done),
    .scl          (scl),
    .sda          (sda)
);

//--------------------------------------------------
// I2C pull-ups
//--------------------------------------------------

pullup(scl);
pullup(sda);

// Slave can only pull SDA LOW
assign sda = slave_sda_oe ? 1'b0 : 1'bz;

//--------------------------------------------------
// 50 MHz clock
//--------------------------------------------------

initial begin
    clk_50mhz = 1'b0;

    forever #10 clk_50mhz = ~clk_50mhz;
end

//--------------------------------------------------
// Test
//--------------------------------------------------

initial begin

    reset          = 1'b1;
    start          = 1'b0;

    slave_addr     = 7'h57;
    pointer_addr   = 8'h2A;

    slave_read_data = 8'hA5;

    slave_sda_oe   = 1'b0;

    //------------------------------------------------
    // RESET
    //------------------------------------------------

    #100;

    reset = 1'b0;

    #100;

    //------------------------------------------------
    // START READ TRANSACTION
    //------------------------------------------------

    start = 1'b1;

    #20;

    start = 1'b0;

    //------------------------------------------------
    // Wait until transaction starts
    //------------------------------------------------

    wait(uut.state == uut.START);

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");

    //------------------------------------------------
    // WRITE ADDRESS
    //------------------------------------------------
    // DUT sends:
    //
    // 7-bit slave address = 57
    // Write bit            = 0
    //
    // 8-bit value = AE
    //
    //------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR);

    $display("-----------------------------------------");
    $display("Slave receiving WRITE address");
    $display("-----------------------------------------");

    //------------------------------------------------
    // Slave ACK WRITE address
    //------------------------------------------------

    wait(uut.state == uut.SLAVE_ACK);

    slave_sda_oe = 1'b1;

    wait(uut.state != uut.SLAVE_ACK);

    slave_sda_oe = 1'b0;

    //------------------------------------------------
    // POINTER ADDRESS
    //------------------------------------------------

    wait(uut.state == uut.POINTER);

    $display("-----------------------------------------");
    $display("Slave receiving POINTER address");
    $display("-----------------------------------------");

    //------------------------------------------------
    // Slave ACK POINTER
    //------------------------------------------------

    wait(uut.state == uut.POINTER_ACK);

    slave_sda_oe = 1'b1;

    wait(uut.state != uut.POINTER_ACK);

    slave_sda_oe = 1'b0;

    //------------------------------------------------
    // REPEATED START
    //------------------------------------------------

    wait(uut.state == uut.REPEATED_START);

    $display("-----------------------------------------");
    $display("REPEATED START detected");
    $display("-----------------------------------------");

    //------------------------------------------------
    // READ ADDRESS
    //------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR_R);

    $display("-----------------------------------------");
    $display("Slave receiving READ address");
    $display("-----------------------------------------");

    //------------------------------------------------
    // Slave ACK READ address
    //------------------------------------------------

    wait(uut.state == uut.SLAVE_ACK_R);

    slave_sda_oe = 1'b1;

    wait(uut.state != uut.SLAVE_ACK_R);

    slave_sda_oe = 1'b0;

    //------------------------------------------------
    // SLAVE SENDS DATA
    //------------------------------------------------

    wait(uut.state == uut.READ_DATA);

    $display("-----------------------------------------");
    $display("Slave sending data = %h",
             slave_read_data);
    $display("-----------------------------------------");

    //------------------------------------------------
    // Send 8 bits MSB first
    //
    // SDA changes only while SCL is LOW
    //
    //------------------------------------------------

    for(i = 7; i >= 0; i = i - 1)
    begin

        // Wait until SCL is LOW
        wait(scl == 1'b0);

        if(slave_read_data[i] == 1'b0)
            slave_sda_oe = 1'b1;
        else
            slave_sda_oe = 1'b0;

        // Wait for SCL HIGH
        wait(scl == 1'b1);

        // Wait for SCL LOW
        wait(scl == 1'b0);

    end

    //------------------------------------------------
    // Release SDA after sending 8 bits
    //------------------------------------------------

    slave_sda_oe = 1'b0;

    //------------------------------------------------
    // MASTER NACK
    //------------------------------------------------

    wait(uut.state == uut.DATA_NACK);

    $display("-----------------------------------------");
    $display("Master sent NACK");
    $display("-----------------------------------------");

    //------------------------------------------------
    // WAIT FOR DONE
    //------------------------------------------------

    wait(done == 1'b1);

    //------------------------------------------------
    // CHECK RESULT
    //------------------------------------------------

    $display("-----------------------------------------");
    $display("I2C READ TRANSACTION COMPLETED");
    $display("-----------------------------------------");

    if(data_out == slave_read_data)
    begin

        $display("-----------------------------------------");
        $display("READ TEST PASSED");
        $display("Expected data = %h", slave_read_data);
        $display("Received data = %h", data_out);
        $display("-----------------------------------------");

    end
    else
    begin

        $display("-----------------------------------------");
        $display("READ TEST FAILED");
        $display("Expected data = %h", slave_read_data);
        $display("Received data = %h", data_out);
        $display("-----------------------------------------");

    end

    #100;

    $finish;

end

//--------------------------------------------------
// Monitor
//--------------------------------------------------

initial begin

    $monitor(
        "TIME=%0t | TICK=%b | START=%b | STATE=%0d | NEXT=%0d | SCL=%b | SDA=%b | BIT=%0d | BUSY=%b | DONE=%b | DATA=%h",
        $time,
        uut.timing_tick,
        start,
        uut.state,
        uut.next_state,
        scl,
        sda,
        uut.bit_count,
        busy,
        done,
        data_out
    );

end

//--------------------------------------------------
// VCD
//--------------------------------------------------

initial begin

    $dumpfile("i2c_read.vcd");

    $dumpvars(0, i2c_read_tb);

end

endmodule
