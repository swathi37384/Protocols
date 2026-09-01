module i2c_master_top (
    input        clk_50mhz,
    input        reset,

    input        start,        
    input        rw,           // 0 = write, 1 = read
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

    // Gate the start pulse to the FSM selected by rw
    wire start_write = start & ~rw;
    wire start_read  = start &  rw;

    wire       busy_w, done_w;
    wire       busy_r, done_r;
    wire [7:0] data_out_r;

    write u_i2c_write (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start_write),
        .more_data    (more_data),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_in      (data_in),
        .busy         (busy_w),
        .done         (done_w),
        .scl          (scl),
        .sda          (sda)
    );

    read u_i2c_read (
        .clk_50mhz    (clk_50mhz),
        .reset        (reset),
        .start        (start_read),
        .slave_addr   (slave_addr),
        .pointer_addr (pointer_addr),
        .data_out     (data_out_r),
        .busy         (busy_r),
        .done         (done_r),
        .scl          (scl),
        .sda          (sda)
    );
    
    assign busy     = rw ? busy_r : busy_w;
    assign done     = rw ? done_r : done_w;
    assign data_out = data_out_r;

endmodule
