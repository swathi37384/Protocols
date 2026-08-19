`timescale 1ns/1ps

module tb_write;

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

reg slave_sda_drive;

// Open-drain slave SDA
assign sda = (slave_sda_drive == 1'b0) ? 1'b0 : 1'bz;

pullup(sda);
pullup(scl);

// DUT
write dut (
    .clk(clk),
    .rst(rst),
    .s(s),
    .rw(rw),
    .slave_add(slave_add),
    .pointer_add(pointer_add),
    .tx_data(tx_data),
    .busy(busy),
    .done(done),
    .ack_error(ack_error),
    .sda(sda),
    .scl(scl)
);

// 100 MHz clock
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// Slave ACK
always @(*) begin

    slave_sda_drive = 1'b1;

    if (dut.state == dut.ack_addr)
        slave_sda_drive = 1'b0;

    else if (dut.state == dut.pointer_ack)
        slave_sda_drive = 1'b0;

    else if (dut.state == dut.data_ack)
        slave_sda_drive = 1'b0;

end

// Test
initial begin

    rst         = 1'b1;
    s           = 1'b0;
    rw          = 1'b0;

    slave_add   = 7'h55;
    pointer_add = 8'h20;
    tx_data     = 8'hA0;

    #50;
    rst = 1'b0;

    #50;

    // Start write transaction
    s = 1'b1;
    #10;
    s = 1'b0;

    // Wait for completion
    wait(done == 1'b1);

    $display("--------------------------------------");
    $display("WRITE TRANSACTION COMPLETED");
    $display("Slave Address = %h", slave_add);
    $display("Pointer       = %h", pointer_add);
    $display("Data          = %h", tx_data);
    $display("ACK Error     = %b", ack_error);
    $display("--------------------------------------");

    #100;

    $finish;
end

// Monitor
initial begin

    $monitor(
        "Time=%0t | State=%d | SDA=%b | SCL=%b | Busy=%b | Done=%b | ACK_Error=%b",
        $time,
        dut.state,
        sda,
        scl,
        busy,
        done,
        ack_error
    );

end

// VCD
initial begin
    $dumpfile("write.vcd");
    $dumpvars(0, tb_write);
end

endmodule
