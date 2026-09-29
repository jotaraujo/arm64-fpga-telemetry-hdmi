module por_reset (
    input  wire clk,
    output reg  rst_n
);
    reg [3:0] por_cnt = 4'd0;

    always @(posedge clk) begin
        if (por_cnt != 4'hF) begin
            por_cnt <= por_cnt + 4'd1;
            rst_n   <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end
endmodule