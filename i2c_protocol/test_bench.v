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

reg slave_sda_oe;
reg [7:0] slave_read_data;

pullup(scl);
pullup(sda);

assign sda = slave_sda_oe ? 1'b0 : 1'bz;

top_module uut(
    .clk_50mhz   (clk_50mhz),
    .reset       (reset),
    .start       (start),
    .rw          (rw),
    .more_data   (more_data),
    .slave_addr  (slave_addr),
    .pointer_addr(pointer_addr),
    .data_in     (data_in),
    .data_out    (data_out),
    .busy        (busy),
    .done        (done),
    .scl         (scl),
    .sda         (sda)
);

initial begin
    clk_50mhz = 1'b0;
    forever #10 clk_50mhz = ~clk_50mhz;
end

always @(*) begin

    slave_sda_oe = 1'b0;

    if (rw == 1'b0) begin

        case (uut.write_inst.state)

            uut.write_inst.SLAVE_ACK:
                slave_sda_oe = 1'b1;

            uut.write_inst.POINTER_ACK:
                slave_sda_oe = 1'b1;

            uut.write_inst.DATA_ACK:
                slave_sda_oe = 1'b1;

            default:
                slave_sda_oe = 1'b0;

        endcase

    end
    else begin

        case (uut.read_inst.state)

            uut.read_inst.SLAVE_ACK_W:
                slave_sda_oe = 1'b1;

            uut.read_inst.POINTER_ACK:
                slave_sda_oe = 1'b1;

            uut.read_inst.SLAVE_ACK_R:
                slave_sda_oe = 1'b1;

            uut.read_inst.READ_DATA:
            begin

                if (slave_read_data[uut.read_inst.bit_count] == 1'b0)
                    slave_sda_oe = 1'b1;
                else
                    slave_sda_oe = 1'b0;

            end

            default:
                slave_sda_oe = 1'b0;

        endcase

    end

end

initial begin

    reset = 1'b1;
    start = 1'b0;
    rw = 1'b0;
    more_data = 1'b0;

    slave_addr = 7'h57;
    pointer_addr = 8'h2A;
    data_in = 8'hA5;
    slave_read_data = 8'hA5;

    #100;

    reset = 1'b0;

    #100;

    write_test;

    #10000;

    read_test;

    #10000;

    $display("");
    $display("=========================================");
    $display("       I2C ALL TESTS COMPLETED");
    $display("=========================================");

    $finish;

end

task write_test;

begin

    $display("");
    $display("-----------------------------------------");
    $display("          I2C WRITE TEST");
    $display("-----------------------------------------");

    rw = 1'b0;

    start = 1'b1;

    wait(busy == 1'b1);

    start = 1'b0;

    wait(done == 1'b1);

    $display("");
    $display("-----------------------------------------");
    $display("I2C WRITE TRANSACTION COMPLETED");
    $display("-----------------------------------------");

    if (done == 1'b1)
        $display("WRITE TEST PASSED");
    else
        $display("WRITE TEST FAILED");

end

endtask

task read_test;

begin

    $display("");
    $display("-----------------------------------------");
    $display("           I2C READ TEST");
    $display("-----------------------------------------");

    rw = 1'b1;

    start = 1'b1;

    wait(busy == 1'b1);

    start = 1'b0;

    wait(uut.read_inst.state == uut.read_inst.START);

    $display("-----------------------------------------");
    $display("START detected");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.SLAVE_ADDR_W);

    $display("-----------------------------------------");
    $display("Slave receiving WRITE address");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.SLAVE_ACK_W);

    $display("Slave ACK WRITE address");

    wait(uut.read_inst.state == uut.read_inst.POINTER_ADDR);

    $display("-----------------------------------------");
    $display("Slave receiving POINTER address");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.POINTER_ACK);

    $display("Slave ACK POINTER address");

    wait(uut.read_inst.state == uut.read_inst.REPEATED_START);

    $display("-----------------------------------------");
    $display("REPEATED START detected");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.SLAVE_ADDR_R);

    $display("-----------------------------------------");
    $display("Slave receiving READ address");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.SLAVE_ACK_R);

    $display("Slave ACK READ address");

    wait(uut.read_inst.state == uut.read_inst.READ_DATA);

    $display("-----------------------------------------");
    $display("Slave sending data = %h", slave_read_data);
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.MASTER_NACK);

    $display("-----------------------------------------");
    $display("Master NACK");
    $display("-----------------------------------------");

    wait(uut.read_inst.state == uut.read_inst.STOP);

    $display("-----------------------------------------");
    $display("STOP detected");
    $display("-----------------------------------------");

    wait(done == 1'b1);

    #20;

    $display("-----------------------------------------");
    $display("I2C READ TRANSACTION COMPLETED");
    $display("-----------------------------------------");

    if (data_out == slave_read_data) begin

        $display("-----------------------------------------");
        $display("READ TEST PASSED");
        $display("Expected data = %h", slave_read_data);
        $display("Received data = %h", data_out);
        $display("-----------------------------------------");

    end
    else begin

        $display("-----------------------------------------");
        $display("READ TEST FAILED");
        $display("Expected data = %h", slave_read_data);
        $display("Received data = %h", data_out);
        $display("-----------------------------------------");

    end

end

endtask

initial begin

    $monitor(
        "TIME=%0t | RW=%b | START=%b | SCL=%b | SDA=%b | BUSY=%b | DONE=%b | DATA=%h",
        $time,
        rw,
        start,
        scl,
        sda,
        busy,
        done,
        data_out
    );

end

initial begin

    $dumpfile("i2c_top.vcd");
    $dumpvars(0, top);

end

endmodule
