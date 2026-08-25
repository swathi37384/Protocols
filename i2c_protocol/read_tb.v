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

pullup(scl);
pullup(sda);

assign sda = slave_sda_oe ? 1'b0 : 1'bz;

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
// 50 MHz clock
//--------------------------------------------------

initial begin
    clk_50mhz = 1'b0;

    forever #10 clk_50mhz = ~clk_50mhz;
end



//--------------------------------------------------
// Slave variables
//--------------------------------------------------

reg [7:0] slave_read_data;

reg [7:0] received_addr;
reg [7:0] received_pointer;

integer i;



//--------------------------------------------------
// Slave receive byte
// No posedge/negedge
//--------------------------------------------------

task slave_receive_byte;

    output [7:0] received_byte;

    integer j;

    begin

        received_byte = 8'd0;
	#2500;
        for(j = 7; j >= 0; j = j - 1)
        begin

            // SCL HIGH period
            #2500;

            received_byte[j] = sda;

            // SCL LOW period
        
	    #7500;

        end

    end

endtask



//--------------------------------------------------
// Slave ACK
// No edge sensitivity
//--------------------------------------------------

task slave_ack;

    begin

        // SCL is LOW here

        slave_sda_oe = 1'b1;

        // Hold ACK during SCL HIGH
        #5000;

        // SCL goes LOW
        #5000;

        // Release SDA
        slave_sda_oe = 1'b0;

    end

endtask



//--------------------------------------------------
// Slave sends one byte
// No posedge/negedge
//--------------------------------------------------

task slave_send_byte;

    input [7:0] transmit_data;

    integer j;

    begin

        for(j = 7; j >= 0; j = j - 1)
        begin

            // Set data while SCL LOW
            if(transmit_data[j] == 1'b0)
                slave_sda_oe = 1'b1;
            else
                slave_sda_oe = 1'b0;

            // SCL HIGH
            #5000;

            // SCL LOW
            #5000;

        end

        // Release SDA after 8 bits
        slave_sda_oe = 1'b0;

    end

endtask



//--------------------------------------------------
// Main test
//--------------------------------------------------

initial begin

    reset = 1'b1;
    start = 1'b0;

    slave_addr   = 7'h57;
    pointer_addr = 8'h2A;

    slave_sda_oe = 1'b0;

    slave_read_data = 8'hA5;


    //------------------------------------------------
    // Reset
    //------------------------------------------------

    #100;

    reset = 1'b0;

    #100;


    //------------------------------------------------
    // Start transaction
    //------------------------------------------------

    start = 1'b1;

    #20;

    start = 1'b0;


    //------------------------------------------------
    // Wait for START
    //------------------------------------------------

    #5000;

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");


    //------------------------------------------------
    // Receive WRITE address
    //------------------------------------------------

    slave_receive_byte(received_addr);

    $display("Slave received address = %h",
             received_addr);


    //------------------------------------------------
    // ACK WRITE address
    //------------------------------------------------

    slave_ack();


    //------------------------------------------------
    // Receive pointer
    //------------------------------------------------

    slave_receive_byte(received_pointer);

    $display("Slave received pointer = %h",
             received_pointer);


    //------------------------------------------------
    // ACK pointer
    //------------------------------------------------

    slave_ack();


    //------------------------------------------------
    // Repeated START
    //------------------------------------------------

    #10000;

    $display("-----------------------------------------");
    $display("REPEATED START detected");
    $display("-----------------------------------------");


    //------------------------------------------------
    // Receive READ address
    //------------------------------------------------

    slave_receive_byte(received_addr);

    $display("Slave received READ address = %h",
             received_addr);


    //------------------------------------------------
    // ACK READ address
    //------------------------------------------------

    slave_ack();


    //------------------------------------------------
    // Send data
    //------------------------------------------------

    $display("Slave sending data = %h",
             slave_read_data);

    slave_send_byte(slave_read_data);


    //------------------------------------------------
    // Master NACK
    //------------------------------------------------

    #5000;

    if(sda === 1'b1)
        $display("Master sent NACK");
    else
        $display("ERROR: Master did not send NACK");


    //------------------------------------------------
    // STOP
    //------------------------------------------------

    #10000;

    $display("-----------------------------------------");
    $display("STOP detected");
    $display("-----------------------------------------");


    //------------------------------------------------
    // Wait for DONE
    //------------------------------------------------

    wait(done == 1'b1);


    //------------------------------------------------
    // Check result
    //------------------------------------------------

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
// VCD
//--------------------------------------------------

initial begin

    $dumpfile("i2c_read.vcd");

    $dumpvars(0, i2c_read_tb);

end



//--------------------------------------------------
// Monitor
//--------------------------------------------------

initial begin

    $monitor(
        "TIME=%0t SCL=%b SDA=%b STATE=%0d PHASE=%b BIT=%0d BUSY=%b DONE=%b DATA=%h",
        $time,
        scl,
        sda,
        uut.state,
        uut.scl_phase,
        uut.bit_count,
        busy,
        done,
        data_out
    );

end

endmodule
