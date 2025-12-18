module master (
    input  wire        clk,
    input  wire        rst_n,
    output reg         req,
    output reg [31:0]  data,
    input  wire        ack
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req  <= 1'b0;
            data <= 32'd0;
        end else begin
            if (!req) begin
                req  <= 1'b1;
                data <= data + 1'b1;
            end else if (ack) begin
                req <= 1'b0;  
            end
        end
    end
endmodule
