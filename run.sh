#!/bin/bash
set -e

# Compile
iverilog -g2012 -o sim/async_fifo_tb rtl/async_fifo.v tb/tb_async_fifo.v

# Simulate
vvp sim/async_fifo_tb

# Waveform
gtkwave sim/async_fifo_tb.vcd
