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

initial begin
    clk_50mhz = 1'b0;
    forever #10 clk_50mhz = ~clk_50mhz;
end

reg [7:0] slave_read_data;
reg [7:0] received_addr;
reg [7:0] received_pointer;

integer i;

task slave_ack;
begin
    @(negedge scl);
    slave_sda_oe = 1'b1;
    @(posedge scl);
    @(negedge scl);
    slave_sda_oe = 1'b0;
end
endtask

task slave_receive_byte;
    output [7:0] received_byte;
    integer j;
begin
    received_byte = 8'd0;

    for (j = 7; j >= 0; j = j - 1)
    begin
        @(posedge scl);
        received_byte[j] = sda;
        @(negedge scl);
    end
end
endtask

task slave_send_byte;
    input [7:0] transmit_data;
    integer j;
begin
    for (j = 7; j >= 0; j = j - 1)
    begin
        if (transmit_data[j] == 1'b0)
            slave_sda_oe = 1'b1;
        else
            slave_sda_oe = 1'b0;

        @(posedge scl);
        @(negedge scl);
    end

    slave_sda_oe = 1'b0;
end
endtask

initial
begin
    reset = 1'b1;
    start = 1'b0;

    slave_addr   = 7'h57;
    pointer_addr = 8'h2A;

    slave_sda_oe   = 1'b0;
    slave_read_data = 8'hA5;

    #100;

    reset = 1'b0;

    #100;

    start = 1'b1;

    #20;

    start = 1'b0;

    @(negedge sda);

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");

    slave_receive_byte(received_addr);

    $display("Slave received address = %h",
             received_addr);

    slave_ack();

    slave_receive_byte(received_pointer);

    $display("Slave received pointer = %h",
             received_pointer);

    slave_ack();

    @(negedge sda);

    $display("-----------------------------------------");
    $display("REPEATED START detected");
    $display("-----------------------------------------");

    slave_receive_byte(received_addr);

    $display("Slave received READ address = %h",
             received_addr);

    slave_ack();

    $display("Slave sending data = %h",
             slave_read_data);

    slave_send_byte(slave_read_data);

    @(posedge scl);

    if (sda === 1'b1)
        $display("Master sent NACK");
    else
        $display("ERROR: Master did not send NACK");

    @(negedge scl);

    @(posedge scl);
    @(posedge sda);

    $display("-----------------------------------------");
    $display("STOP detected");
    $display("-----------------------------------------");

    wait(done == 1'b1);

    if (data_out == slave_read_data)
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

initial
begin
    $dumpfile("i2c_read.vcd");
    $dumpvars(0, i2c_read_tb);
end

initial
begin
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
