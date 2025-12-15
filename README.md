# Multi-Clock-Domain-Arbiter
Round-robin arbiter for multi-clock domain systems using Verilog (Vivado)

## Overview
This project implements a multi-clock domain arbitration system using Verilog HDL.
Three masters operating at different clock frequencies communicate with two slaves
via a round-robin arbiter.

The design handles clock-domain crossing using synchronizers and uses request–acknowledge handshaking to ensure lossless data transfer.

## System Specifications
- Masters: 3 (100 MHz, 200 MHz, 300 MHz)
- Slaves: 2 (300 MHz)
- Data Width: 32-bit
- Arbitration: Round Robin
- Reset: Asynchronous Active-Low
- Tool: Xilinx Vivado

## File Structure
src/ <br>
├── top.v <br>
├── multi_clock_arbiter.v <br>
├── master.v <br>
├── slave.v <br>
├── req_sync.v <br>
└── tb_top.v <br>


## Simulation
1. Open Vivado
2. Add all files under `src/`
3. Set `tb_top.v` as simulation top
4. Run Behavioral Simulation
5. Observe waveform for master requests, arbitration, and slave data reception

## Key Features
- Safe clock-domain crossing
- Fair round-robin arbitration
- Handshake-based communication
- Vivado-compatible Verilog

## Author
Satwik Pal
