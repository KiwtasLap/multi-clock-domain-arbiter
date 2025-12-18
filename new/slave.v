module slave (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req,
    input  wire [31:0] data,
    output reg         ack,
    output reg [31:0]  last_data
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            last_data <= 32'd0;
        end else begin
            ack <= req;
            if (req)
                last_data <= data;
        end
    end
endmodule
