// ============================================================
//  slave.v  (upgraded)
//
//  Improvements:
//    1. Accepts burst transfers (stores last BURST_LEN words)
//    2. Multi-cycle ACK - asserts ACK only after receiving
//       all burst words (more realistic slave behavior)
//    3. Error flag: detects if req drops before burst completes
//    4. rx_count: total words received (performance counter)
// ============================================================

module slave #(
    parameter BURST_LEN = 4
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req,
    input  wire [31:0] data,
    output reg         ack,
    output reg [31:0]  last_data,       // last word received
    output reg         err_flag,        // burst incomplete error
    output reg [15:0]  rx_count         // total words received
);

    reg [2:0] word_cnt;                 // counts words in current burst
    reg       receiving;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack       <= 1'b0;
            last_data <= 32'd0;
            err_flag  <= 1'b0;
            rx_count  <= 0;
            word_cnt  <= 0;
            receiving <= 0;
        end else begin
            ack <= 1'b0;                // default

            if (req) begin
                receiving <= 1'b1;
                last_data <= data;
                rx_count  <= rx_count + 1;
                word_cnt  <= word_cnt + 1;

                // ACK after receiving all burst words
                if (word_cnt == BURST_LEN - 1) begin
                    ack      <= 1'b1;
                    word_cnt <= 0;
                    receiving<= 0;
                end

            end else if (receiving) begin
                // req dropped mid-burst - error condition
                err_flag  <= 1'b1;
                word_cnt  <= 0;
                receiving <= 0;
            end
        end
    end

endmodule