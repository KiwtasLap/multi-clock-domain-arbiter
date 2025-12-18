module top (
    input wire clk100,
    input wire clk200,
    input wire clk300,
    input wire rst_n
);

    wire [31:0] m_data0, m_data1, m_data2;
    wire [2:0]  m_req, m_req_sync, m_ack;

    master M0 (.clk(clk100), .rst_n(rst_n), .req(m_req[0]), .data(m_data0), .ack(m_ack[0]));
    master M1 (.clk(clk200), .rst_n(rst_n), .req(m_req[1]), .data(m_data1), .ack(m_ack[1]));
    master M2 (.clk(clk300), .rst_n(rst_n), .req(m_req[2]), .data(m_data2), .ack(m_ack[2]));

    req_sync S0 (.clk_dst(clk300), .rst_n(rst_n), .req_src(m_req[0]), .req_dst(m_req_sync[0]));
    req_sync S1 (.clk_dst(clk300), .rst_n(rst_n), .req_src(m_req[1]), .req_dst(m_req_sync[1]));
    req_sync S2 (.clk_dst(clk300), .rst_n(rst_n), .req_src(m_req[2]), .req_dst(m_req_sync[2]));

    wire s_req, s_sel;
    wire [31:0] s_data;
    wire s_ack_a, s_ack_b;
    wire [31:0] last_a, last_b;

    multi_clock_arbiter ARB (
        .clk_arb(clk300),
        .rst_n(rst_n),
        .m_req(m_req_sync),
        .m_data0(m_data0),
        .m_data1(m_data1),
        .m_data2(m_data2),
        .m_ack(m_ack),
        .s_req(s_req),
        .s_data(s_data),
        .s_sel(s_sel),
        .s_ack(s_sel ? s_ack_b : s_ack_a)
    );

    slave SA (.clk(clk300), .rst_n(rst_n), .req(s_req & ~s_sel), .data(s_data), .ack(s_ack_a), .last_data(last_a));
    slave SB (.clk(clk300), .rst_n(rst_n), .req(s_req &  s_sel), .data(s_data), .ack(s_ack_b), .last_data(last_b));

endmodule
