
//  master.v  (upgraded)
//
//  Each master now supports:
//    1. BURST transfers - sends BURST_LEN words per transaction
//    2. Writes into the async_fifo (not direct wire to arbiter)
//    3. Performance counter: counts total transactions sent
//
//  BURST_LEN is a parameter - set differently per master if needed
// ============================================================

module master #(
    parameter BURST_LEN  = 4,           // words per burst
    parameter MASTER_ID  = 0            // for data tagging (upper 8 bits = ID)
) (
    input  wire        clk,
    input  wire        rst_n,

    // FIFO write interface (goes to async_fifo wr port)
    output reg         fifo_wr_en,
    output reg [31:0]  fifo_wr_data,
    input  wire        fifo_full,

    // ACK from arbiter (already synchronized back to this clock domain)
    input  wire        ack,

    // Performance counter output
    output reg [15:0]  trans_count      // number of bursts completed
);

    // FSM states
    localparam IDLE  = 2'd0;
    localparam BURST = 2'd1;
    localparam WAIT  = 2'd2;

    reg [1:0]  state;
    reg [2:0]  burst_cnt;               // counts words in current burst
    reg [23:0] base_data;               // increments each burst

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            burst_cnt   <= 0;
            base_data   <= 0;
            fifo_wr_en  <= 0;
            fifo_wr_data<= 0;
            trans_count <= 0;
        end else begin
            fifo_wr_en <= 0;            // default: no write

            case (state)
                // ----------------------------------------
                IDLE: begin
                    if (!fifo_full) begin
                        state     <= BURST;
                        burst_cnt <= 0;
                    end
                end

                // ----------------------------------------
                // Push BURST_LEN words into FIFO
                BURST: begin
                    if (!fifo_full) begin
                        fifo_wr_en   <= 1;
                        // Data format: [31:24]=MasterID [23:0]=base_data+word_index
                        fifo_wr_data <= {MASTER_ID[7:0], base_data + burst_cnt};
                        burst_cnt    <= burst_cnt + 1;

                        if (burst_cnt == BURST_LEN - 1) begin
                            state     <= WAIT;
                            base_data <= base_data + BURST_LEN;
                        end
                    end
                end

                // ----------------------------------------
                // Wait for ACK from arbiter before next burst
                WAIT: begin
                    if (ack) begin
                        trans_count <= trans_count + 1;
                        state       <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule