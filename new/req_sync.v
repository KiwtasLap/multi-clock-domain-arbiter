module req_sync (
    input  wire clk_dst,
    input  wire rst_n,
    input  wire req_src,
    output reg  req_dst
);
    reg ff1, ff2;

    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            ff1 <= 0;
            ff2 <= 0;
            req_dst <= 0;
        end else begin
            ff1 <= req_src;
            ff2 <= ff1;
            req_dst <= ff2;
        end
    end
endmodule
