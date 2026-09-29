module uart_tx #(
  parameter integer CLKS_PER_BIT = 219
)(
  input wire clk,
  input wire rst_n,
  input wire data_valid,
  output wire data_ready,
  input wire [7:0] data_byte,
  output reg tx,
  output reg busy
);
  localparam COUNT_W = $clog2(CLKS_PER_BIT + 1);
  reg [COUNT_W-1:0] clock_count;
  reg [3:0] bit_index;
  reg [9:0] frame;

  assign data_ready = !busy;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx <= 1'b1;
      busy <= 1'b0;
      clock_count <= {COUNT_W{1'b0}};
      bit_index <= 4'd0;
      frame <= 10'h3ff;
    end else if (!busy) begin
      tx <= 1'b1;

      if (data_valid) begin
        frame <= {1'b1, data_byte, 1'b0};
        tx <= 1'b0;
        busy <= 1'b1;
        clock_count <= {COUNT_W{1'b0}};
        bit_index <= 4'd0;
      end
    end else if (clock_count == CLKS_PER_BIT - 1) begin
      clock_count <= {COUNT_W{1'b0}};
      if (bit_index == 4'd9) begin
        tx <= 1'b1;
        busy <= 1'b0;
      end else begin
        bit_index <= bit_index + 1'b1;
        tx <= frame[bit_index + 1'b1];
      end
    end else begin
      clock_count <= clock_count + 1'b1;
    end
  end
endmodule
