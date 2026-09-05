// ============================================================
//  seg7_display.v
//
//  Drives the Boolean board's 7-segment displays.
//  Each display has 4 digits multiplexed (AN[3:0]).
//  Takes a 16-bit value, shows it as 4 hex digits.
//
//  Boolean board has TWO 7-seg displays:
//    Display 0 (D0): shows arb_count0 (low 8 bits) + arb_count1 (low 8 bits)
//    Display 1 (D1): shows arb_count2 (low 8 bits) + stall_cycles (low 8 bits)
//
//  Segment encoding (active LOW on Boolean):
//    SEG[7]=DP, SEG[6]=CG, SEG[5]=CF, SEG[4]=CE,
//    SEG[3]=CD, SEG[2]=CC, SEG[1]=CB, SEG[0]=CA
// ============================================================

module seg7_display (
    input  wire        clk,         // 100 MHz input
    input  wire        rst_n,
    input  wire [15:0] value0,      // shown on Display 0
    input  wire [15:0] value1,      // shown on Display 1
    // Display 0
    output reg  [3:0]  D0_AN,       // active LOW anode select
    output reg  [7:0]  D0_SEG,      // active LOW segments
    // Display 1
    output reg  [3:0]  D1_AN,
    output reg  [7:0]  D1_SEG
);

    // --------------------------------------------------------
    // Slow down to ~1 kHz for multiplexing (100MHz / 100000 = 1kHz)
    // --------------------------------------------------------
    reg [16:0] div_cnt;
    reg [1:0]  digit_sel;           // 0-3: which digit is active

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt   <= 0;
            digit_sel <= 0;
        end else begin
            if (div_cnt == 17'd99999) begin
                div_cnt   <= 0;
                digit_sel <= digit_sel + 1;
            end else
                div_cnt <= div_cnt + 1;
        end
    end

    // --------------------------------------------------------
    // Extract hex nibbles from each 16-bit value
    // --------------------------------------------------------
    reg [3:0] nibble0, nibble1;

    always @(*) begin
        case (digit_sel)
            2'd0: nibble0 = value0[3:0];
            2'd1: nibble0 = value0[7:4];
            2'd2: nibble0 = value0[11:8];
            2'd3: nibble0 = value0[15:12];
        endcase
        case (digit_sel)
            2'd0: nibble1 = value1[3:0];
            2'd1: nibble1 = value1[7:4];
            2'd2: nibble1 = value1[11:8];
            2'd3: nibble1 = value1[15:12];
        endcase
    end

    // --------------------------------------------------------
    // Hex to 7-segment decoder (active LOW)
    // Segment order: DP CG CF CE CD CC CB CA
    // --------------------------------------------------------
    function [7:0] hex_to_seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_seg = 8'b11000000; // 0
                4'h1: hex_to_seg = 8'b11111001; // 1
                4'h2: hex_to_seg = 8'b10100100; // 2
                4'h3: hex_to_seg = 8'b10110000; // 3
                4'h4: hex_to_seg = 8'b10011001; // 4
                4'h5: hex_to_seg = 8'b10010010; // 5
                4'h6: hex_to_seg = 8'b10000010; // 6
                4'h7: hex_to_seg = 8'b11111000; // 7
                4'h8: hex_to_seg = 8'b10000000; // 8
                4'h9: hex_to_seg = 8'b10010000; // 9
                4'hA: hex_to_seg = 8'b10001000; // A
                4'hB: hex_to_seg = 8'b10000011; // b
                4'hC: hex_to_seg = 8'b11000110; // C
                4'hD: hex_to_seg = 8'b10100001; // d
                4'hE: hex_to_seg = 8'b10000110; // E
                4'hF: hex_to_seg = 8'b10001110; // F
            endcase
        end
    endfunction

    // --------------------------------------------------------
    // Drive anodes and segments (active LOW)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            D0_AN  <= 4'b1111;
            D0_SEG <= 8'hFF;
            D1_AN  <= 4'b1111;
            D1_SEG <= 8'hFF;
        end else begin
            D0_AN  <= ~(4'b0001 << digit_sel);  // one LOW at a time
            D0_SEG <= hex_to_seg(nibble0);
            D1_AN  <= ~(4'b0001 << digit_sel);
            D1_SEG <= hex_to_seg(nibble1);
        end
    end

endmodule