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
// I2C PULLUPS
//--------------------------------------------------

pullup(scl);
pullup(sda);


//--------------------------------------------------
// SLAVE OPEN DRAIN SDA
//--------------------------------------------------

assign sda = slave_sda_oe ? 1'b0 : 1'bz;


//--------------------------------------------------
// 50 MHz CLOCK
//--------------------------------------------------

initial begin

    clk_50mhz = 1'b0;

    forever #10 clk_50mhz = ~clk_50mhz;

end


//--------------------------------------------------
// SLAVE ACK + DATA
//--------------------------------------------------

always @(*) begin

    slave_sda_oe = 1'b0;

    case(uut.state)

        //--------------------------------------------------
        // WRITE ADDRESS ACK
        //--------------------------------------------------

        uut.SLAVE_ACK_W:
        begin
            slave_sda_oe = 1'b1;
        end


        //--------------------------------------------------
        // POINTER ACK
        //--------------------------------------------------

        uut.POINTER_ACK:
        begin
            slave_sda_oe = 1'b1;
        end


        //--------------------------------------------------
        // READ ADDRESS ACK
        //--------------------------------------------------

        uut.SLAVE_ACK_R:
        begin
            slave_sda_oe = 1'b1;
        end


        //--------------------------------------------------
        // SLAVE SENDS DATA
        //--------------------------------------------------

        uut.READ_DATA:
        begin

            // IMPORTANT:
            // Keep SDA stable during both LOW and HIGH.
            //
            // bit_count changes only after SCL HIGH,
            // so SDA changes only for the next bit
            // when SCL becomes LOW again.

            if(slave_read_data[uut.bit_count] == 1'b0)
                slave_sda_oe = 1'b1;
            else
                slave_sda_oe = 1'b0;

        end


        //--------------------------------------------------
        // DEFAULT
        //--------------------------------------------------

        default:
        begin
            slave_sda_oe = 1'b0;
        end

    endcase

end


//--------------------------------------------------
// MAIN TEST
//--------------------------------------------------

initial begin

    //--------------------------------------------------
    // INITIAL VALUES
    //--------------------------------------------------

    reset = 1'b1;
    start = 1'b0;

    slave_addr   = 7'h57;
    pointer_addr = 8'h2A;

    slave_read_data = 8'hA5;


    //--------------------------------------------------
    // RESET
    //--------------------------------------------------

    #100;

    reset = 1'b0;

    #100;


    //--------------------------------------------------
    // START TRANSACTION
    //--------------------------------------------------

    start = 1'b1;

    #6000;

    start = 1'b0;


    //--------------------------------------------------
    // START
    //--------------------------------------------------

    wait(uut.state == uut.START);

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // WRITE ADDRESS
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR_W);

    $display("-----------------------------------------");
    $display("Slave receiving WRITE address");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // WRITE ADDRESS ACK
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ACK_W);

    $display("Slave ACK WRITE address");


    //--------------------------------------------------
    // POINTER
    //--------------------------------------------------

    wait(uut.state == uut.POINTER_ADDR);

    $display("-----------------------------------------");
    $display("Slave receiving POINTER address");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // POINTER ACK
    //--------------------------------------------------

    wait(uut.state == uut.POINTER_ACK);

    $display("Slave ACK POINTER address");


    //--------------------------------------------------
    // REPEATED START
    //--------------------------------------------------

    wait(uut.state == uut.REPEATED_START);

    $display("-----------------------------------------");
    $display("REPEATED START detected");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // READ ADDRESS
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR_R);

    $display("-----------------------------------------");
    $display("Slave receiving READ address");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // READ ADDRESS ACK
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ACK_R);

    $display("Slave ACK READ address");


    //--------------------------------------------------
    // SLAVE SEND DATA
    //--------------------------------------------------

    wait(uut.state == uut.READ_DATA);

    $display("-----------------------------------------");
    $display("Slave sending data = %h",
             slave_read_data);
    $display("-----------------------------------------");


    //--------------------------------------------------
    // WAIT FOR MASTER NACK
    //--------------------------------------------------

    wait(uut.state == uut.MASTER_NACK);

    $display("-----------------------------------------");
    $display("Master NACK");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // WAIT FOR STOP
    //--------------------------------------------------

    wait(uut.state == uut.STOP);

    $display("-----------------------------------------");
    $display("STOP detected");
    $display("-----------------------------------------");


    //--------------------------------------------------
    // WAIT FOR DONE
    //--------------------------------------------------

    wait(done == 1'b1);


    //--------------------------------------------------
    // CHECK DATA
    //--------------------------------------------------

    $display("-----------------------------------------");
    $display("I2C READ TRANSACTION COMPLETED");
    $display("-----------------------------------------");


    if(data_out == slave_read_data)
    begin

        $display("-----------------------------------------");
        $display("READ TEST PASSED");
        $display("Expected data = %h",
                 slave_read_data);
        $display("Received data = %h",
                 data_out);
        $display("-----------------------------------------");

    end
    else
    begin

        $display("-----------------------------------------");
        $display("READ TEST FAILED");
        $display("Expected data = %h",
                 slave_read_data);
        $display("Received data = %h",
                 data_out);
        $display("-----------------------------------------");

    end


    #100;

    $finish;

end


//--------------------------------------------------
// MONITOR
//--------------------------------------------------

initial begin

    $monitor(
        "TIME=%0t | TICK=%b | START=%b | STATE=%0d | NEXT=%0d | PHASE=%b | SCL=%b | SDA=%b | BIT=%0d | BUSY=%b | DONE=%b | DATA=%h",
        $time,
        uut.timing_tick,
        start,
        uut.state,
        uut.next_state,
        uut.scl_phase,
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
