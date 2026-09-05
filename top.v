// ============================================================
//  top.v  (Level-3 - complete integration)
//
//  Architecture:
//
//  clk100 ──► Master0 ──► async_fifo0 ──►┐
//  clk200 ──► Master1 ──► async_fifo1 ──►├──► Arbiter(clk300) ──► SlaveA
//  clk300 ──► Master2 ──► async_fifo2 ──►┘                    ──► SlaveB
//
//  ACK path (clk300 → each master's domain):
//    m_ack[0] ──► bit_sync(clk100) ──► Master0.ack
//    m_ack[1] ──► bit_sync(clk200) ──► Master1.ack
//    m_ack[2] ──► directly          ──► Master2.ack  (same domain)
//
//  All performance counters are available as outputs for
//  chipscope / ILA monitoring in Vivado.
// ============================================================

module top (
    input wire clk100,
    input wire clk200,
    input wire clk300,
    input wire rst_n,

    // Performance counter outputs (connect to ILA in Vivado)
    output wire [15:0] trans_count0,
    output wire [15:0] trans_count1,
    output wire [15:0] trans_count2,
    output wire [15:0] arb_count0,
    output wire [15:0] arb_count1,
    output wire [15:0] arb_count2,
    output wire [15:0] stall_cycles,
    output wire [15:0] rx_count_a,
    output wire [15:0] rx_count_b,
    output wire        err_a,
    output wire        err_b
);

    // --------------------------------------------------------
    // FIFO interconnect wires
    // --------------------------------------------------------
    wire [31:0] fifo_wr_data0, fifo_wr_data1, fifo_wr_data2;
    wire        fifo_wr_en0,   fifo_wr_en1,   fifo_wr_en2;
    wire        fifo_full0,    fifo_full1,    fifo_full2;

    wire [31:0] fifo_rd_data0, fifo_rd_data1, fifo_rd_data2;
    wire        fifo_empty0,   fifo_empty1,   fifo_empty2;
    wire        fifo_rd_en0,   fifo_rd_en1,   fifo_rd_en2;

    // --------------------------------------------------------
    // ACK signals
    // --------------------------------------------------------
    wire [2:0] m_ack_raw;       // from arbiter, in clk300 domain
    wire       ack0_sync;       // synced to clk100
    wire       ack1_sync;       // synced to clk200
    // ack2 stays in clk300 - Master2 is already there

    // --------------------------------------------------------
    // Slave wires
    // --------------------------------------------------------
    wire s_req, s_sel;
    wire [31:0] s_data;
    wire s_ack_a, s_ack_b;

    // --------------------------------------------------------
    // Masters
    // --------------------------------------------------------
    master #(.BURST_LEN(4), .MASTER_ID(0)) M0 (
        .clk          (clk100),
        .rst_n        (rst_n),
        .fifo_wr_en   (fifo_wr_en0),
        .fifo_wr_data (fifo_wr_data0),
        .fifo_full    (fifo_full0),
        .ack          (ack0_sync),
        .trans_count  (trans_count0)
    );

    master #(.BURST_LEN(4), .MASTER_ID(1)) M1 (
        .clk          (clk200),
        .rst_n        (rst_n),
        .fifo_wr_en   (fifo_wr_en1),
        .fifo_wr_data (fifo_wr_data1),
        .fifo_full    (fifo_full1),
        .ack          (ack1_sync),
        .trans_count  (trans_count1)
    );

    master #(.BURST_LEN(4), .MASTER_ID(2)) M2 (
        .clk          (clk300),
        .rst_n        (rst_n),
        .fifo_wr_en   (fifo_wr_en2),
        .fifo_wr_data (fifo_wr_data2),
        .fifo_full    (fifo_full2),
        .ack          (m_ack_raw[2]),   // same domain, no sync needed
        .trans_count  (trans_count2)
    );

    // --------------------------------------------------------
    // Async FIFOs (one per master)
    // Write side = master's clock, Read side = clk300
    // --------------------------------------------------------
    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(2)) FIFO0 (
        .wr_clk   (clk100),
        .wr_rst_n (rst_n),
        .wr_en    (fifo_wr_en0),
        .wr_data  (fifo_wr_data0),
        .full     (fifo_full0),
        .rd_clk   (clk300),
        .rd_rst_n (rst_n),
        .rd_en    (fifo_rd_en0),
        .rd_data  (fifo_rd_data0),
        .empty    (fifo_empty0)
    );

    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(2)) FIFO1 (
        .wr_clk   (clk200),
        .wr_rst_n (rst_n),
        .wr_en    (fifo_wr_en1),
        .wr_data  (fifo_wr_data1),
        .full     (fifo_full1),
        .rd_clk   (clk300),
        .rd_rst_n (rst_n),
        .rd_en    (fifo_rd_en1),
        .rd_data  (fifo_rd_data1),
        .empty    (fifo_empty1)
    );

    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(2)) FIFO2 (
        .wr_clk   (clk300),
        .wr_rst_n (rst_n),
        .wr_en    (fifo_wr_en2),
        .wr_data  (fifo_wr_data2),
        .full     (fifo_full2),
        .rd_clk   (clk300),
        .rd_rst_n (rst_n),
        .rd_en    (fifo_rd_en2),
        .rd_data  (fifo_rd_data2),
        .empty    (fifo_empty2)
    );

    // --------------------------------------------------------
    // ACK synchronizers: clk300 → clk100, clk200
    // --------------------------------------------------------
    bit_sync ACK_SYNC0 (
        .clk_dst (clk100),
        .rst_n   (rst_n),
        .sig_in  (m_ack_raw[0]),
        .sig_out (ack0_sync)
    );

    bit_sync ACK_SYNC1 (
        .clk_dst (clk200),
        .rst_n   (rst_n),
        .sig_in  (m_ack_raw[1]),
        .sig_out (ack1_sync)
    );

    // --------------------------------------------------------
    // Arbiter
    // --------------------------------------------------------
    multi_clock_arbiter #(.BURST_LEN(4), .STALL_THRESH(8)) ARB (
        .clk_arb      (clk300),
        .rst_n        (rst_n),
        .fifo_rd_data0(fifo_rd_data0),
        .fifo_rd_data1(fifo_rd_data1),
        .fifo_rd_data2(fifo_rd_data2),
        .fifo_empty0  (fifo_empty0),
        .fifo_empty1  (fifo_empty1),
        .fifo_empty2  (fifo_empty2),
        .fifo_rd_en0  (fifo_rd_en0),
        .fifo_rd_en1  (fifo_rd_en1),
        .fifo_rd_en2  (fifo_rd_en2),
        .m_ack        (m_ack_raw),
        .s_req        (s_req),
        .s_data       (s_data),
        .s_sel        (s_sel),
        .s_ack        (s_sel ? s_ack_b : s_ack_a),
        .arb_count0   (arb_count0),
        .arb_count1   (arb_count1),
        .arb_count2   (arb_count2),
        .stall_cycles (stall_cycles)
    );

    // --------------------------------------------------------
    // Slaves (both on clk300)
    // --------------------------------------------------------
    slave #(.BURST_LEN(4)) SA (
        .clk      (clk300),
        .rst_n    (rst_n),
        .req      (s_req & ~s_sel),
        .data     (s_data),
        .ack      (s_ack_a),
        .last_data(),
        .err_flag (err_a),
        .rx_count (rx_count_a)
    );

    slave #(.BURST_LEN(4)) SB (
        .clk      (clk300),
        .rst_n    (rst_n),
        .req      (s_req &  s_sel),
        .data     (s_data),
        .ack      (s_ack_b),
        .last_data(),
        .err_flag (err_b),
        .rx_count (rx_count_b)
    );

endmodule