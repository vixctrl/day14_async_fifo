`timescale 1ns/1ps

module tb_async_fifo;
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4; // DEPTH = 16

    // DUT IO
    reg  wclk, wrst_n, w_en;
    reg  rclk, rrst_n, r_en;
    reg  [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire w_full, w_afull, r_empty, r_aempty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ALMOST_FULL_THRESH(2),
        .ALMOST_EMPTY_THRESH(2)
    ) dut (
        .wclk(wclk), .wrst_n(wrst_n), .w_en(w_en), .wdata(wdata),
        .w_full(w_full), .w_almost_full(w_afull),
        .rclk(rclk), .rrst_n(rrst_n), .r_en(r_en), .rdata(rdata),
        .r_empty(r_empty), .r_almost_empty(r_aempty)
    );

    // Clocks: different frequencies
    initial wclk = 0; always #5  wclk = ~wclk;  // 100 MHz
    initial rclk = 0; always #7  rclk = ~rclk;  // ~71 MHz

    // Simple scoreboard (ring)
    reg [DATA_WIDTH-1:0] ref_mem [0:1023];
    integer ref_wr_ptr = 0;
    integer ref_rd_ptr = 0;
    integer mismatches = 0;

    // Wave dump
    initial begin
        $dumpfile("sim/async_fifo_tb.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    // Reset sequence
    initial begin
        wrst_n = 0; rrst_n = 0;
        w_en = 0; r_en = 0; wdata = 0;
        #40; wrst_n = 1;
        #40; rrst_n = 1;
    end

    // Writer: burst writes with gaps
    initial begin
        @(posedge wrst_n);
        repeat (4) @(posedge wclk);
        repeat (120) begin
            @(posedge wclk);
            if (!w_full && ($random % 3 != 0)) begin
                w_en  <= 1'b1;
                wdata <= $random;
                ref_mem[ref_wr_ptr] = wdata;
                ref_wr_ptr = ref_wr_ptr + 1;
            end else begin
                w_en  <= 1'b0;
            end
        end
        w_en <= 1'b0;
    end

    // Reader: consume whenever not empty (with some pauses)
    initial begin
        @(posedge rrst_n);
        repeat (10) @(posedge rclk);
        repeat (140) begin
            @(posedge rclk);
            if (!r_empty && ($random % 4 != 0)) begin
                r_en <= 1'b1;
                // check next cycle (data presented same cycle in our RTL)
                @(negedge rclk); // small delay to sample after read
                if (rdata !== ref_mem[ref_rd_ptr]) begin
                    $display("MISMATCH: exp=%0h got=%0h at t=%0t",
                             ref_mem[ref_rd_ptr], rdata, $time);
                    mismatches = mismatches + 1;
                end
                ref_rd_ptr = ref_rd_ptr + 1;
            end else begin
                r_en <= 1'b0;
            end
        end
        r_en <= 1'b0;

        // Report
        #50;
        if (mismatches == 0)
            $display("TEST PASS: Async FIFO data order preserved without errors.");
        else
            $display("TEST FAIL: %0d mismatches.", mismatches);
        $finish;
    end

endmodule
