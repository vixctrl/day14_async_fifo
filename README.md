# Day 14 — Asynchronous FIFO (CDC-safe) & Single-Port RAM

## 📌 Overview
This day's task covers **two core digital design modules**:
1. **Asynchronous FIFO (CDC-safe)** — For transferring data between different clock domains using Gray-code pointers and 2-FF synchronizers.
2. **Single-Port RAM** — Basic synchronous memory for storage with single read/write port.

These designs are common building blocks in VLSI chip design and are widely used in:
- Clock domain crossing interfaces
- Buffering in communication protocols
- On-chip memory storage

---

## 1️⃣ Asynchronous FIFO

### **Block Diagram**
![Async FIFO Block Diagram](docs/async_fifo_block.png)

**Key Features:**
- Separate `wr_clk` and `rd_clk`
- Gray code pointers to avoid metastability
- Pointer synchronization using double flip-flops
- Full/Empty flag generation

**Use Cases:**  
Crossing data between CPU core clock and peripheral clock.

---

## 2️⃣ Single-Port RAM

### **Block Diagram**
![Single-Port RAM Block Diagram](docs/single_port_ram_block.png)

**Key Features:**
- Single clock input
- Single read/write port
- Parameterized data width and depth

**Use Cases:**  
Temporary storage within the same clock domain.

---

## 🛠 Build & Run

### **Run Simulation (Icarus Verilog)**
```bash
# For Async FIFO
cd rtl
iverilog -o async_fifo_tb tb/tb_async_fifo.v rtl/async_fifo.v
vvp async_fifo_tb
gtkwave wave.vcd

# For Single-Port RAM
cd day14_single_port_ram
iverilog -o spram_tb tb_single_port_ram.v single_port_ram.v
vvp spram_tb
gtkwave wave.vcd
