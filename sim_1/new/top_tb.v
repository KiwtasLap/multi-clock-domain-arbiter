`timescale 1ns/1ps

module tb_top;

    reg clk100 = 0, clk200 = 0, clk300 = 0;
    reg rst_n = 0;

    always #5   clk100 = ~clk100;
    always #2.5 clk200 = ~clk200;
    always #1.67 clk300 = ~clk300;

    top DUT (.clk100(clk100), .clk200(clk200), .clk300(clk300), .rst_n(rst_n));

    initial begin
        rst_n = 0;
        #20 rst_n = 1;
        #500 $finish;
    end
endmodule
