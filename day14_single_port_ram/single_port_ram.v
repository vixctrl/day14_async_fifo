module single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire we,                     // Write Enable
    input wire [ADDR_WIDTH-1:0] addr,   // Address
    input wire [DATA_WIDTH-1:0] din,    // Data In
    output reg [DATA_WIDTH-1:0] dout    // Data Out
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;  // Write
        dout <= mem[addr];     // Read
    end
endmodule
