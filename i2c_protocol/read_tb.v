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

//--------------------------------------------------
// Slave control
//--------------------------------------------------

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
// I2C pull-ups
//--------------------------------------------------

pullup(scl);
pullup(sda);

//--------------------------------------------------
// Slave open-drain SDA
//--------------------------------------------------

assign sda = slave_sda_oe ? 1'b0 : 1'bz;

//--------------------------------------------------
// 50 MHz clock
//--------------------------------------------------

initial begin

    clk_50mhz = 1'b0;

    forever #10 clk_50mhz = ~clk_50mhz;

end

//--------------------------------------------------
// Slave ACK and DATA control
//--------------------------------------------------

always @(*) begin

    slave_sda_oe = 1'b0;

    case(uut.state)

        //--------------------------------------------------
        // ACK WRITE ADDRESS
        //--------------------------------------------------

        uut.SLAVE_ACK_W:
        begin
            slave_sda_oe = 1'b1;
        end

        //--------------------------------------------------
        // ACK POINTER ADDRESS
        //--------------------------------------------------

        uut.POINTER_ACK:
        begin
            slave_sda_oe = 1'b1;
        end

        //--------------------------------------------------
        // ACK READ ADDRESS
        //--------------------------------------------------

        uut.SLAVE_ACK_R:
        begin
            slave_sda_oe = 1'b1;
        end

        //--------------------------------------------------
        // SLAVE SENDS READ DATA
        //--------------------------------------------------

        uut.READ_DATA:
        begin

            // Change SDA only while SCL is LOW

            if(scl == 1'b0)
            begin

                if(slave_read_data[uut.bit_count] == 1'b0)
                    slave_sda_oe = 1'b1;
                else
                    slave_sda_oe = 1'b0;

            end
            else
            begin
                // Keep current data during SCL HIGH
                slave_sda_oe = 1'b0;
            end

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
// Main test
//--------------------------------------------------

initial begin

    //--------------------------------------------------
    // Initial values
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
    // START
    //--------------------------------------------------

    start = 1'b1;

    #20;

    start = 1'b0;

    //--------------------------------------------------
    // Wait for START
    //--------------------------------------------------

    wait(uut.state == uut.START);

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");

    //--------------------------------------------------
    // WRITE SLAVE ADDRESS
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR_W);

    $display("-----------------------------------------");
    $display("Slave receiving WRITE address");
    $display("-----------------------------------------");

    wait(uut.state == uut.SLAVE_ACK_W);

    $display("Slave ACK WRITE address");

    //--------------------------------------------------
    // POINTER ADDRESS
    //--------------------------------------------------

    wait(uut.state == uut.POINTER_ADDR);

    $display("-----------------------------------------");
    $display("Slave receiving POINTER address");
    $display("-----------------------------------------");

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
    // READ SLAVE ADDRESS
    //--------------------------------------------------

    wait(uut.state == uut.SLAVE_ADDR_R);

    $display("-----------------------------------------");
    $display("Slave receiving READ address");
    $display("-----------------------------------------");

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
    // Wait until READ_DATA finishes
    //--------------------------------------------------

    wait(uut.state == uut.MASTER_NACK);

    //--------------------------------------------------
    // MASTER NACK
    //--------------------------------------------------

    $display("-----------------------------------------");
    $display("Master NACK");
    $display("-----------------------------------------");

    //--------------------------------------------------
    // STOP
    //--------------------------------------------------

    wait(uut.state == uut.STOP);

    $display("-----------------------------------------");
    $display("STOP detected");
    $display("-----------------------------------------");

    //--------------------------------------------------
    // DONE
    //--------------------------------------------------

    wait(done == 1'b1);

    //--------------------------------------------------
    // Check received data
    //--------------------------------------------------

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
