// ============================================================
//  top_boolean.v  -  Boolean Board Wrapper
//
//  This is the TRUE top module you set in Vivado.
//  It wraps top.v and adds:
//    1. Clocking Wizard (MMCM) to generate 100/200/300 MHz
//    2. LED status display (16 LEDs)
//    3. 7-segment display (arb counters)
//    4. RGB LEDs (health indicators)
//    5. btn[0] = reset (active LOW after inversion)
//    6. sw[0] = freeze display (pause counter updates on 7-seg)
//
//  HOW TO USE ON BOARD:
//    LEDs [15:8] = arb_count0[7:0]   - Master 0 grants
//    LEDs [7:0]  = arb_count1[7:0]   - Master 1 grants
//    Display 0   = arb_count0 (hex)  - left
//    Display 1   = stall_cycles (hex)- right
//    RGB0        = Slave A health    (green=ok, red=error)
//    RGB1        = Slave B health    (green=ok, red=error)
//    btn[0]      = RESET
//    sw[0]       = freeze 7-seg display
// ============================================================

module top_boolean (
    input  wire        clk,             // 100 MHz, pin F14

    // Buttons (active HIGH on Boolean)
    input  wire [3:0]  btn,             // btn[0] = reset

    // Slide switches
    input  wire [15:0] sw,              // sw[0] = freeze display

    // LEDs
    output wire [15:0] led,

    // 7-segment Display 0
    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,

    // 7-segment Display 1
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG,

    // RGB LEDs
    output wire [2:0]  RGB0,            // Slave A: [2]=B [1]=G [0]=R
    output wire [2:0]  RGB1             // Slave B: [2]=B [1]=G [0]=R
);

    // --------------------------------------------------------
    // Reset: btn[0] is active HIGH on Boolean board.
    // Our design uses active-LOW rst_n.
    // --------------------------------------------------------
    wire rst_n = ~btn[0];

    // --------------------------------------------------------
    // Clock Wizard outputs
    // You MUST instantiate the Clocking Wizard IP in Vivado:
    //   IP Catalog → Clocking Wizard
    //   Input:  100 MHz
    //   Output: clk_out1=100MHz, clk_out2=200MHz, clk_out3=300MHz
    //   Name:   clk_wiz_0
    //   Enable locked output
    //
    // Spartan-7 MMCM can definitely do 300 MHz on XC7S50-1
    // --------------------------------------------------------
    wire clk100, clk200, clk300;
    wire locked;                        // MMCM lock indicator

    clk_wiz_0 clk_wiz_inst (
        .clk_in1  (clk),               // 100 MHz board clock
        .clk_out1 (clk100),            // 100 MHz
        .clk_out2 (clk200),            // 200 MHz
        .clk_out3 (clk300),            // 300 MHz
        .reset    (btn[0]),            // reset wizard when btn[0] held
        .locked   (locked)
    );

    // Hold design in reset until MMCM is locked
    wire rst_n_safe = locked & ~btn[0];

    // --------------------------------------------------------
    // Performance counter wires
    // --------------------------------------------------------
    wire [15:0] trans_count0, trans_count1, trans_count2;
    wire [15:0] arb_count0, arb_count1, arb_count2;
    wire [15:0] stall_cycles;
    wire [15:0] rx_count_a, rx_count_b;
    wire        err_a, err_b;

    // --------------------------------------------------------
    // Core design instantiation
    // --------------------------------------------------------
    top core (
        .clk100       (clk100),
        .clk200       (clk200),
        .clk300       (clk300),
        .rst_n        (rst_n_safe),
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
    // LED display:
    //   LED[15:8] = arb_count0 lower 8 bits (Master 0 grants)
    //   LED[7:0]  = arb_count1 lower 8 bits (Master 1 grants)
    //   You can see them increment in real time on the board
    // --------------------------------------------------------
    assign led[15:8] = arb_count0[7:0];
    assign led[7:0]  = arb_count1[7:0];

    // --------------------------------------------------------
    // 7-segment displays
    //   sw[0] = 0: live counters
    //   sw[0] = 1: freeze display (examine last value)
    // --------------------------------------------------------
    wire [15:0] disp0_val = sw[0] ? 16'hFFFF : arb_count0;
    wire [15:0] disp1_val = sw[0] ? 16'hFFFF : stall_cycles;

    seg7_display SEG (
        .clk     (clk100),             // use 100 MHz for display mux
        .rst_n   (rst_n_safe),
        .value0  (disp0_val),
        .value1  (disp1_val),
        .D0_AN   (D0_AN),
        .D0_SEG  (D0_SEG),
        .D1_AN   (D1_AN),
        .D1_SEG  (D1_SEG)
    );

    // --------------------------------------------------------
    // RGB LEDs: health indicator for each slave
    //   Green = slave receiving data, no error
    //   Red   = error flag set
    //   Blue  = idle (neither)
    // --------------------------------------------------------
    // Slave A
    assign RGB0[0] = err_a;            // Red   = error
    assign RGB0[1] = ~err_a & (rx_count_a[0]); // Green = activity
    assign RGB0[2] = ~err_a & ~rx_count_a[0];  // Blue  = idle

    // Slave B
    assign RGB1[0] = err_b;
    assign RGB1[1] = ~err_b & (rx_count_b[0]);
    assign RGB1[2] = ~err_b & ~rx_count_b[0];

endmodule