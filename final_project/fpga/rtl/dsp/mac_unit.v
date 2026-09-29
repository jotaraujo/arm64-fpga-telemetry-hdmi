module mac_unit (
  input wire                clk,
  input wire                rst_n,
  input wire                start,
  input wire                clear,
  input wire signed [15:0] operand_a_q88,
  input wire signed [15:0] operand_b_q88,
  output reg                done,
  output reg signed [31:0] accumulator_q1616,
  output reg signed [15:0] result_q88,
  output reg               overflow
);
  wire signed [31:0] product_q1616 = operand_a_q88 * operand_b_q88;
  wire signed [32:0] sum_ext =
    {accumulator_q1616[31], accumulator_q1616} +
    {product_q1616[31], product_q1616};

  reg signed [31:0] next_acc;
  reg next_overflow;
  reg signed [31:0] scaled_q88;

  always @(*) begin
    next_overflow = 1'b0;
    if (sum_ext > 33'sd2147483647) begin
      next_acc = 32'sh7fffffff;
      next_overflow = 1'b1;
    end else if (sum_ext < -33'sd2147483648) begin
      next_acc = 32'sh80000000;
      next_overflow = 1'b1;
    end else begin
      next_acc = sum_ext[31:0];
    end
    scaled_q88 = next_acc >>> 8;
  end

  function signed [15:0] saturate_q88;
    input signed [31:0] value;
    begin
      if (value > 32'sd32767)
        saturate_q88 = 16'sh7fff;
      else if (value < -32'sd32768)
        saturate_q88 = 16'sh8000;
      else
        saturate_q88 = value[15:0];
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      done <= 1'b0;
      accumulator_q1616 <= 32'sd0;
      result_q88 <= 16'sd0;
      overflow <= 1'b0;
    end else begin
      done <= 1'b0;
      if (clear) begin
        accumulator_q1616 <= 32'sd0;
        result_q88 <= 16'sd0;
        overflow <= 1'b0;
      end else if (start) begin
        accumulator_q1616 <= next_acc;
        result_q88 <= saturate_q88(scaled_q88);
        overflow <= overflow | next_overflow;
        done <= 1'b1;
      end
    end
  end
endmodule