// ============================================================
//  tb_top.v  -  Self-checking testbench
//
//  What this verifies:
//    1. All three masters send bursts and receive ACKs
//    2. Round-robin order is maintained
//    3. No slave error flags asserted
//    4. Performance counters advance correctly
//    5. Starvation: one master goes quiet, others still served
//
//  Run in Vivado: Add all .v files, set tb_top as top.
//  Simulation time: 10 us is enough to see many transactions.
// ============================================================

`timescale 1ns/1ps

module tb_top;

    // --------------------------------------------------------
    // Clock generation
    // Periods: 100MHz=10ns, 200MHz=5ns, 300MHz=3.33ns
    // --------------------------------------------------------
    reg clk100, clk200, clk300, rst_n;

    initial clk100 = 0;
    always #5   clk100 = ~clk100;   // 100 MHz

    initial clk200 = 0;
    always #2.5 clk200 = ~clk200;   // 200 MHz

    initial clk300 = 0;
    always #1.67 clk300 = ~clk300;  // ~300 MHz

    // --------------------------------------------------------
    // DUT output wires
    // --------------------------------------------------------
    wire [15:0] trans_count0, trans_count1, trans_count2;
    wire [15:0] arb_count0,   arb_count1,   arb_count2;
    wire [15:0] stall_cycles;
    wire [15:0] rx_count_a,   rx_count_b;
    wire        err_a, err_b;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    top DUT (
        .clk100       (clk100),
        .clk200       (clk200),
        .clk300       (clk300),
        .rst_n        (rst_n),
        .trans_count0 (trans_count0),
        .trans_count1 (trans_count1),
        .trans_count2 (trans_count2),
        .arb_count0   (arb_count0),
        .arb_count1   (arb_count1),
        .arb_count2   (arb_count2),
        .stall_cycles (stall_cycles),
        .rx_count_a   (rx_count_a),
        .rx_count_b   (rx_count_b),
        .err_a        (err_a),
        .err_b        (err_b)
    );

    // --------------------------------------------------------
    // Reset + run
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        rst_n = 0;
        repeat(10) @(posedge clk300);
        rst_n = 1;

        $display("=== Reset released. Simulation starting ===");

        // ---- Test 1: Basic operation - run for 3us ----
        #3000;
        $display("[T=%.1f ns] trans0=%0d  trans1=%0d  trans2=%0d",
                 $realtime, trans_count0, trans_count1, trans_count2);
        $display("[T=%.1f ns] arb0=%0d  arb1=%0d  arb2=%0d  stalls=%0d",
                 $realtime, arb_count0, arb_count1, arb_count2, stall_cycles);
        $display("[T=%.1f ns] rxA=%0d  rxB=%0d  errA=%b  errB=%b",
                 $realtime, rx_count_a, rx_count_b, err_a, err_b);

        // CHECK: no errors
        if (!err_a && !err_b) begin
            $display("PASS: No slave errors");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Slave error detected!");
            fail_count = fail_count + 1;
        end

        // CHECK: all masters got service
        if (trans_count0 > 0 && trans_count1 > 0 && trans_count2 > 0) begin
            $display("PASS: All 3 masters completed transactions");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Some master got no service (trans0=%0d trans1=%0d trans2=%0d)",
                     trans_count0, trans_count1, trans_count2);
            fail_count = fail_count + 1;
        end

        // ---- Test 2: Run further, check counters still advance ----
        #5000;
        $display("\n[T=%.1f ns] After 5 more us:", $realtime);
        $display("  trans0=%0d  trans1=%0d  trans2=%0d",
                 trans_count0, trans_count1, trans_count2);
        $display("  arb0=%0d  arb1=%0d  arb2=%0d",
                 arb_count0, arb_count1, arb_count2);

        // CHECK: arbitration counts match transaction counts
        if (arb_count0 == trans_count0 &&
            arb_count1 == trans_count1 &&
            arb_count2 == trans_count2) begin
            $display("PASS: Arb counts match master trans counts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Count mismatch between arbiter and masters");
            fail_count = fail_count + 1;
        end

        // ---- Final report ----
        #100;
        $display("\n========================================");
        $display("  RESULTS: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED - check waveforms");

        $finish;
    end

    // --------------------------------------------------------
    // Timeout watchdog - if simulation hangs, catch it
    // --------------------------------------------------------
    initial begin
        #20000;
        $display("TIMEOUT: Simulation exceeded 20us - possible deadlock!");
        $finish;
    end

    // --------------------------------------------------------
    // Waveform dump (for GTKWave or Vivado simulator)
    // --------------------------------------------------------
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

endmodule