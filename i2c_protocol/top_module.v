module top_module(
    input        clk_50mhz,
    input        reset,

    input        start,
    input        rw,              // 0 = WRITE, 1 = READ

    input        more_data,

    input  [6:0] slave_addr,
    input  [7:0] pointer_addr,
    input  [7:0] data_in,

    output [7:0] data_out,

    output       busy,
    output       done,

    inout        scl,
    inout        sda

);

    wire write_busy;
    wire write_done;

    wire read_busy;
    wire read_done;

    wire [7:0] read_data;

    wire write_scl;
    wire write_sda;

    wire read_scl;
    wire read_sda;

      write write_inst (

        .clk_50mhz   (clk_50mhz),
        .reset       (reset),

        .start       (start && !rw),
        .more_data   (more_data),

        .slave_addr  (slave_addr),
        .pointer_addr(pointer_addr),
        .data_in     (data_in),

        .busy        (write_busy),
        .done        (write_done),

        .scl         (write_scl),
        .sda         (write_sda)

    );


    read read_inst (

        .clk_50mhz   (clk_50mhz),
        .reset       (reset),

        .start       (start && rw),

        .slave_addr  (slave_addr),
        .pointer_addr(pointer_addr),

        .data_out    (read_data),

        .busy        (read_busy),
        .done        (read_done),

        .scl         (read_scl),
        .sda         (read_sda)

    );
   assign scl = rw ? read_scl : write_scl;
assign sda = rw ? read_sda : write_sda;

assign busy = rw ? read_busy : write_busy;
assign done = rw ? read_done : write_done;

assign data_out = read_data;


endmodule
