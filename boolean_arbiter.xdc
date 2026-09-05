# ============================================================
#  boolean_arbiter.xdc
#  Constraints for Multi-Clock Arbiter on Boolean Board
#  Board: Boolean (XC7S50CSGA324-1, Spartan-7)
# ============================================================

# ============================================================
# CLOCK — 100 MHz oscillator on pin F14
# The clocking wizard generates 100/200/300 MHz from this.
# We only constrain the INPUT clock here; the wizard's outputs
# are automatically constrained by the IP.
# ============================================================
set_property PACKAGE_PIN F14 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# ============================================================
# CRITICAL: Multi-clock domain constraints
# Tell the timing engine that clk100/200/300 (wizard outputs)
# are asynchronous to each other.
# Your async FIFOs handle the actual crossings safely.
#
# Run this AFTER synthesis. Replace clk_wiz_0/* with the
# actual wizard instance path shown in your timing report.
# ============================================================
set_clock_groups -name async_clocks -asynchronous \
    -group [get_clocks -of_objects [get_pins clk_wiz_inst/clk_out1]] \
    -group [get_clocks -of_objects [get_pins clk_wiz_inst/clk_out2]] \
    -group [get_clocks -of_objects [get_pins clk_wiz_inst/clk_out3]]

# ============================================================
# Bank 0 voltage
# ============================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ============================================================
# RESET — btn[0] on pin J2 (active HIGH on Boolean)
# ============================================================
set_property PACKAGE_PIN J2 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]

# Other buttons (optional, not used by this design)
set_property PACKAGE_PIN J5 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property PACKAGE_PIN H2 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property PACKAGE_PIN J1 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]

# ============================================================
# SLIDE SWITCHES — sw[0] = freeze display
# ============================================================
set_property PACKAGE_PIN V2 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN U2 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN U1 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN T2 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN T1 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN R2 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN R1 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN P2 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN P1 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN N2 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN N1 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN M2 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN M1 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN L1 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN K2 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN K1 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

# ============================================================
# LEDs
#   [15:8] = arb_count0 (Master 0 grants)
#   [7:0]  = arb_count1 (Master 1 grants)
# Watch these increment in real time after programming!
# ============================================================
set_property PACKAGE_PIN G1 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN G2 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN F1 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN F2 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN E1 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN E2 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN E3 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN E5 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN E6 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN C3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN B2 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN A2 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN B3 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN A3 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN B4 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN A4 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

# ============================================================
# 7-SEGMENT DISPLAY 0  (shows arb_count0 — Master 0 grants)
# ============================================================
set_property PACKAGE_PIN D5 [get_ports {D0_AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_AN[0]}]
set_property PACKAGE_PIN C4 [get_ports {D0_AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_AN[1]}]
set_property PACKAGE_PIN C7 [get_ports {D0_AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_AN[2]}]
set_property PACKAGE_PIN A8 [get_ports {D0_AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_AN[3]}]

set_property PACKAGE_PIN D7 [get_ports {D0_SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[0]}]
set_property PACKAGE_PIN C5 [get_ports {D0_SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[1]}]
set_property PACKAGE_PIN A5 [get_ports {D0_SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[2]}]
set_property PACKAGE_PIN B7 [get_ports {D0_SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[3]}]
set_property PACKAGE_PIN A7 [get_ports {D0_SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[4]}]
set_property PACKAGE_PIN D6 [get_ports {D0_SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[5]}]
set_property PACKAGE_PIN B5 [get_ports {D0_SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[6]}]
set_property PACKAGE_PIN A6 [get_ports {D0_SEG[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D0_SEG[7]}]

# ============================================================
# 7-SEGMENT DISPLAY 1  (shows stall_cycles)
# ============================================================
set_property PACKAGE_PIN H3 [get_ports {D1_AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_AN[0]}]
set_property PACKAGE_PIN J4 [get_ports {D1_AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_AN[1]}]
set_property PACKAGE_PIN F3 [get_ports {D1_AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_AN[2]}]
set_property PACKAGE_PIN E4 [get_ports {D1_AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_AN[3]}]

set_property PACKAGE_PIN F4 [get_ports {D1_SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[0]}]
set_property PACKAGE_PIN J3 [get_ports {D1_SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[1]}]
set_property PACKAGE_PIN D2 [get_ports {D1_SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[2]}]
set_property PACKAGE_PIN C2 [get_ports {D1_SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[3]}]
set_property PACKAGE_PIN B1 [get_ports {D1_SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[4]}]
set_property PACKAGE_PIN H4 [get_ports {D1_SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[5]}]
set_property PACKAGE_PIN D1 [get_ports {D1_SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[6]}]
set_property PACKAGE_PIN C1 [get_ports {D1_SEG[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D1_SEG[7]}]

# ============================================================
# RGB LEDs
#   RGB0 = Slave A health indicator
#   RGB1 = Slave B health indicator
# ============================================================
set_property PACKAGE_PIN V6 [get_ports {RGB0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB0[0]}]
set_property PACKAGE_PIN V4 [get_ports {RGB0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB0[1]}]
set_property PACKAGE_PIN U6 [get_ports {RGB0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB0[2]}]

set_property PACKAGE_PIN U3 [get_ports {RGB1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB1[0]}]
set_property PACKAGE_PIN V3 [get_ports {RGB1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB1[1]}]
set_property PACKAGE_PIN V5 [get_ports {RGB1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RGB1[2]}]

# ============================================================
# TIMING EXCEPTIONS
# False paths on async reset (it's asynchronous by design)
# ============================================================
set_false_path -from [get_ports {btn[0]}]

# ============================================================
# INPUT/OUTPUT DELAY (optional but good practice)
# Board signals go through simple logic, 5ns budget each
# ============================================================
set_input_delay  -clock sys_clk -max 5.0 [get_ports {sw[*]}]
set_input_delay  -clock sys_clk -min 1.0 [get_ports {sw[*]}]
set_output_delay -clock sys_clk -max 5.0 [get_ports {led[*]}]
set_output_delay -clock sys_clk -max 5.0 [get_ports {RGB0[*]}]
set_output_delay -clock sys_clk -max 5.0 [get_ports {RGB1[*]}]
