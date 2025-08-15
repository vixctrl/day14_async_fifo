`timescale 1ns/1ps

module tb_single_port_ram;
    reg clk;
    reg we;
    reg [3:0] addr;
    reg [7:0] din;
    wire [7:0] dout;

    single_port_ram uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we = 0; addr = 0; din = 0;
        
        // Write
        we = 1;
        addr = 4'b0001; din = 8'hA5; #10;
        addr = 4'b0010; din = 8'h5A; #10;
        
        // Read
        we = 0;
        addr = 4'b0001; #10;
        addr = 4'b0010; #10;

        $finish;
    end
endmodule
