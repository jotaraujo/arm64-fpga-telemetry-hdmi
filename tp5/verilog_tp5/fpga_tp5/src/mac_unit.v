module mac_unit #(
    parameter FRAC_BITS = 8
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               oe,
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    input  wire               mac_en,
    input  wire               clear_acc,
    output reg  signed [31:0] acc,
    output reg                overflow,
    output wire signed [15:0] acc_q88
);
    wire signed [31:0] product = a * b;

    wire signed [32:0] sum_ext =
        {acc[31], acc} + {product[31], product};

    localparam signed [33:0] MAX_32 =  34'sd2147483647;
    localparam signed [33:0] MIN_32 = -34'sd2147483648;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc      <= 32'sd0;
            overflow <= 1'b0;
        end else if (!oe) begin
        end else if (clear_acc) begin
            acc      <= 32'sd0;
            overflow <= 1'b0;
        end else if (mac_en) begin
            if (sum_ext > MAX_32) begin
                acc      <= 32'sh7FFFFFFF;
                overflow <= 1'b1;
            end else if (sum_ext < MIN_32) begin
                acc      <= 32'sh80000000;
                overflow <= 1'b1;
            end else begin
                acc      <= sum_ext[31:0];
            end
        end
    end

    assign acc_q88 = acc[31:16];

endmodule