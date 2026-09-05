// ============================================================
//  arbiter.v  (Level-3 upgrade)
//
//  Improvements over original:
//    1. Reads data from async FIFOs (not direct wires)
//    2. Burst transfer - drains BURST_LEN words per grant
//    3. Priority override - if a master waits > STALL_THRESH
//       cycles it gets boosted to front (starvation prevention)
//    4. Performance counters per master + stall cycles
//    5. Proper slave selection: M0→SA, M1→SB, M2→SA (alternating)
// ============================================================

module multi_clock_arbiter #(
    parameter BURST_LEN   = 4,          // words per burst (match master.v)
    parameter STALL_THRESH = 8          // cycles before priority boost
) (
    input  wire        clk_arb,         // 300 MHz
    input  wire        rst_n,

    // FIFO read interfaces (one per master, already in clk300 domain)
    input  wire [31:0] fifo_rd_data0,
    input  wire [31:0] fifo_rd_data1,
    input  wire [31:0] fifo_rd_data2,
    input  wire        fifo_empty0,
    input  wire        fifo_empty1,
    input  wire        fifo_empty2,
    output reg         fifo_rd_en0,
    output reg         fifo_rd_en1,
    output reg         fifo_rd_en2,

    // ACK back to masters (in clk300, will be re-synced in top.v)
    output reg  [2:0]  m_ack,

    // Slave interface
    output reg         s_req,
    output reg  [31:0] s_data,
    output reg         s_sel,           // 0=Slave A, 1=Slave B
    input  wire        s_ack,

    // Performance counters (clk300 domain)
    output reg [15:0]  arb_count0,      // grants given to master 0
    output reg [15:0]  arb_count1,
    output reg [15:0]  arb_count2,
    output reg [15:0]  stall_cycles     // total cycles arbiter was idle
);

    // FSM
    localparam IDLE      = 3'd0;
    localparam GRANT     = 3'd1;        // draining FIFO words
    localparam WAIT_ACK  = 3'd2;        // waiting for slave ACK
    localparam ACK_PULSE = 3'd3;        // 1-cycle ACK pulse to master

    reg [2:0]  state;
    reg [1:0]  cur;                     // which master is granted (0/1/2)
    reg [2:0]  burst_cnt;               // words sent in current burst
    reg [1:0]  rr_ptr;                  // round-robin pointer persists across grants

    // Stall counters per master - how long each has been waiting
    reg [3:0]  wait_cnt0, wait_cnt1, wait_cnt2;

    // --------------------------------------------------------
    // Priority selection: find next master to serve
    // Checks round-robin order, boosts if wait > STALL_THRESH
    // --------------------------------------------------------
    reg [1:0] next_master;
    reg       found;

    // Wires for "has data" per master
    wire has0 = ~fifo_empty0;
    wire has1 = ~fifo_empty1;
    wire has2 = ~fifo_empty2;
    wire [2:0] has = {has2, has1, has0};

    // --------------------------------------------------------
    // Priority boost: master with longest wait gets served first
    // if it exceeds threshold - prevents starvation
    // --------------------------------------------------------
    always @(*) begin
        next_master = rr_ptr;
        found = 1'b0;

        // First pass: check for starvation override
        if (has0 && (wait_cnt0 >= STALL_THRESH)) begin
            next_master = 2'd0; found = 1'b1;
        end else if (has1 && (wait_cnt1 >= STALL_THRESH)) begin
            next_master = 2'd1; found = 1'b1;
        end else if (has2 && (wait_cnt2 >= STALL_THRESH)) begin
            next_master = 2'd2; found = 1'b1;
        end

        // Second pass: normal round-robin
        if (!found) begin
            // Check from rr_ptr onwards, wrapping around
            if      (has[rr_ptr])                     next_master = rr_ptr;
            else if (has[(rr_ptr+1 <= 2) ? rr_ptr+1 : 0])
                                                       next_master = (rr_ptr+1 <= 2) ? rr_ptr+1 : 0;
            else if (has[(rr_ptr+2 <= 2) ? rr_ptr+2 : (rr_ptr+2-3)])
                                                       next_master = (rr_ptr+2 <= 2) ? rr_ptr+2 : rr_ptr+2-3;
            // if none has data, next_master stays = rr_ptr (IDLE loop)
        end
    end

    // --------------------------------------------------------
    // Main FSM
    // --------------------------------------------------------
    always @(posedge clk_arb or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            cur         <= 0;
            rr_ptr      <= 0;
            burst_cnt   <= 0;
            m_ack       <= 0;
            s_req       <= 0;
            s_data      <= 0;
            s_sel       <= 0;
            fifo_rd_en0 <= 0;
            fifo_rd_en1 <= 0;
            fifo_rd_en2 <= 0;
            wait_cnt0   <= 0;
            wait_cnt1   <= 0;
            wait_cnt2   <= 0;
            arb_count0  <= 0;
            arb_count1  <= 0;
            arb_count2  <= 0;
            stall_cycles<= 0;
        end else begin
            // Default: deassert strobes
            m_ack       <= 0;
            fifo_rd_en0 <= 0;
            fifo_rd_en1 <= 0;
            fifo_rd_en2 <= 0;

            // Increment wait counters for masters with data (saturating)
            if (has0 && wait_cnt0 < 4'hF) wait_cnt0 <= wait_cnt0 + 1;
            if (has1 && wait_cnt1 < 4'hF) wait_cnt1 <= wait_cnt1 + 1;
            if (has2 && wait_cnt2 < 4'hF) wait_cnt2 <= wait_cnt2 + 1;

            case (state)
                // ----------------------------------------
                IDLE: begin
                    if (has != 0) begin
                        cur       <= next_master;
                        burst_cnt <= 0;
                        state     <= GRANT;
                        // Reset wait counter for chosen master
                        case (next_master)
                            0: wait_cnt0 <= 0;
                            1: wait_cnt1 <= 0;
                            2: wait_cnt2 <= 0;
                        endcase
                    end else begin
                        stall_cycles <= stall_cycles + 1;
                    end
                end

                // ----------------------------------------
                // Drain BURST_LEN words from selected FIFO → slave
                GRANT: begin
                    // Read one word from the correct FIFO
                    case (cur)
                        0: begin
                            if (!fifo_empty0) begin
                                fifo_rd_en0 <= 1;
                                s_data      <= fifo_rd_data0;
                            end
                        end
                        1: begin
                            if (!fifo_empty1) begin
                                fifo_rd_en1 <= 1;
                                s_data      <= fifo_rd_data1;
                            end
                        end
                        default: begin
                            if (!fifo_empty2) begin
                                fifo_rd_en2 <= 1;
                                s_data      <= fifo_rd_data2;
                            end
                        end
                    endcase

                    // Select slave: M0→SA(0), M1→SB(1), M2→SA(0)
                    s_sel   <= cur[0];
                    s_req   <= 1'b1;
                    burst_cnt <= burst_cnt + 1;

                    if (burst_cnt == BURST_LEN - 1)
                        state <= WAIT_ACK;
                end

                // ----------------------------------------
                // Hold last word, wait for slave ACK
                WAIT_ACK: begin
                    if (s_ack) begin
                        s_req  <= 0;
                        state  <= ACK_PULSE;
                        // Update perf counters
                        case (cur)
                            0: arb_count0 <= arb_count0 + 1;
                            1: arb_count1 <= arb_count1 + 1;
                            2: arb_count2 <= arb_count2 + 1;
                        endcase
                    end
                end

                // ----------------------------------------
                // 1-cycle ACK pulse back to master, then advance RR
                ACK_PULSE: begin
                    m_ack[cur] <= 1'b1;
                    rr_ptr     <= (cur == 2) ? 2'd0 : cur + 1;
                    state      <= IDLE;
                end

            endcase
        end
    end

endmodule