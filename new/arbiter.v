module multi_clock_arbiter (
    input  wire        clk_arb,
    input  wire        rst_n,
    input  wire [2:0]  m_req,
    input  wire [31:0] m_data0,
    input  wire [31:0] m_data1,
    input  wire [31:0] m_data2,
    output reg  [2:0]  m_ack,
    output reg         s_req,
    output reg  [31:0] s_data,
    output reg         s_sel,
    input  wire        s_ack
);

    reg [1:0] cur;
    reg busy;

    always @(posedge clk_arb or negedge rst_n) begin
        if (!rst_n) begin
            cur <= 0;
            busy <= 0;
            s_req <= 0;
            m_ack <= 0;
        end else begin
            m_ack <= 0;

            if (!busy) begin
                if (m_req[cur]) begin
                    case (cur)
                        0: s_data <= m_data0;
                        1: s_data <= m_data1;
                        2: s_data <= m_data2;
                    endcase
                    s_sel <= cur[0];
                    s_req <= 1'b1;
                    busy  <= 1'b1;
                end else
                    cur <= (cur == 2) ? 0 : cur + 1;
            end else if (s_ack) begin
                s_req <= 0;
                m_ack[cur] <= 1'b1;
                busy <= 0;
                cur <= (cur == 2) ? 0 : cur + 1;
            end
        end
    end
endmodule
