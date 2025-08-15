// Asynchronous FIFO with Gray-code pointers and 2-FF synchronizers
// Parameters: DATA_WIDTH, ADDR_WIDTH (DEPTH = 2**ADDR_WIDTH)
// Flags: full, almost_full (write domain), empty, almost_empty (read domain)

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,              // DEPTH = 16 by default
    parameter ALMOST_FULL_THRESH  = 2,     // assert when <= 2 slots left
    parameter ALMOST_EMPTY_THRESH = 2      // assert when <= 2 items left
)(
    // Write domain
    input                   wclk,
    input                   wrst_n,        // async active-low reset
    input                   w_en,
    input  [DATA_WIDTH-1:0] wdata,
    output                  w_full,
    output                  w_almost_full,

    // Read domain
    input                   rclk,
    input                   rrst_n,        // async active-low reset
    input                   r_en,
    output reg [DATA_WIDTH-1:0] rdata,
    output                  r_empty,
    output                  r_almost_empty
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    localparam PTR_W = ADDR_WIDTH + 1; // extra bit to detect wrap-around

    // ----------------------------------------------------------------
    // Memory
    // ----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ----------------------------------------------------------------
    // Binary <-> Gray helpers
    // ----------------------------------------------------------------
    function [PTR_W-1:0] bin2gray(input [PTR_W-1:0] b);
        bin2gray = (b >> 1) ^ b;
    endfunction

    function [PTR_W-1:0] gray2bin(input [PTR_W-1:0] g);
        integer i;
        begin
            gray2bin[PTR_W-1] = g[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];
        end
    endfunction

    // ----------------------------------------------------------------
    // Write domain pointers
    // ----------------------------------------------------------------
    reg [PTR_W-1:0] wptr_bin, wptr_bin_n;
    reg [PTR_W-1:0] wptr_gray, wptr_gray_n;

    // Read pointer synchronized into write clock domain (Gray)
    reg [PTR_W-1:0] rptr_gray_w1, rptr_gray_w2;

    // Write-side next logic
    wire w_do = w_en & ~w_full;
    always @* begin
        wptr_bin_n  = wptr_bin + w_do;
        wptr_gray_n = bin2gray(wptr_bin_n);
    end

    // Write-side registers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else begin
            if (w_do) mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
            wptr_bin  <= wptr_bin_n;
            wptr_gray <= wptr_gray_n;
        end
    end

    // Synchronize read pointer (Gray) into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= '0;
            rptr_gray_w2 <= '0;
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end

    // ----------------------------------------------------------------
    // Read domain pointers
    // ----------------------------------------------------------------
    reg [PTR_W-1:0] rptr_bin, rptr_bin_n;
    reg [PTR_W-1:0] rptr_gray, rptr_gray_n;

    // Write pointer synchronized into read clock domain (Gray)
    reg [PTR_W-1:0] wptr_gray_r1, wptr_gray_r2;

    // Read-side next logic
    wire r_do = r_en & ~r_empty;
    always @* begin
        rptr_bin_n  = rptr_bin + r_do;
        rptr_gray_n = bin2gray(rptr_bin_n);
    end

    // Read-side registers
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
            rdata     <= '0;
        end else begin
            if (r_do) rdata <= mem[rptr_bin[ADDR_WIDTH-1:0]];
            rptr_bin  <= rptr_bin_n;
            rptr_gray <= rptr_gray_n;
        end
    end

    // Synchronize write pointer (Gray) into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= '0;
            wptr_gray_r2 <= '0;
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end

    // ----------------------------------------------------------------
    // Status flags
    // ----------------------------------------------------------------
    // Empty (read domain): when synchronized write Gray == local read Gray
    assign r_empty = (wptr_gray_r2 == rptr_gray);

    // Full (write domain): next write Gray equals read Gray with MSBs inverted
    wire [PTR_W-1:0] rptr_gray_w2_inv = {~rptr_gray_w2[PTR_W-1:PTR_W-2], rptr_gray_w2[PTR_W-3:0]};
    assign w_full = (wptr_gray_n == rptr_gray_w2_inv);

    // Almost flags use occupancy estimate via synchronized opposite pointer
    wire [PTR_W-1:0] rbin_in_w = gray2bin(rptr_gray_w2);
    wire [PTR_W-1:0] wbin_in_r = gray2bin(wptr_gray_r2);

    // occupancy from write domain perspective
    wire [PTR_W-1:0] occ_w = wptr_bin - rbin_in_w;
    // free slots
    wire [PTR_W-1:0] free_w = DEPTH[PTR_W-1:0] - occ_w;
    assign w_almost_full = (free_w <= ALMOST_FULL_THRESH);

    // occupancy from read domain perspective
    wire [PTR_W-1:0] occ_r = wbin_in_r - rptr_bin;
    assign r_almost_empty = (occ_r <= ALMOST_EMPTY_THRESH);

endmodule
