//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Wed May 21 11:01:57 2025
//Host        : simtool-5 running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target top_level_wrapper.bd
//Design      : top_level_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module top_level_wrapper
   (CLK100MHZ,
    CPU_RESETN,
    UART_rxd,
    UART_txd,
    eth0_aligned,
    eth1_aligned,
    status_led);
  input CLK100MHZ;
  input CPU_RESETN;
  input UART_rxd;
  output UART_txd;
  input eth0_aligned;
  input eth1_aligned;
  output [3:0]status_led;

  wire CLK100MHZ;
  wire CPU_RESETN;
  wire UART_rxd;
  wire UART_txd;
  wire eth0_aligned;
  wire eth1_aligned;
  wire [3:0]status_led;

  top_level top_level_i
       (.CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .UART_rxd(UART_rxd),
        .UART_txd(UART_txd),
        .eth0_aligned(eth0_aligned),
        .eth1_aligned(eth1_aligned),
        .status_led(status_led));
endmodule
