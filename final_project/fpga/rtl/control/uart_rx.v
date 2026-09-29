module uart_rx #(
  parameter integer CLKS_PER_BIT = 219
)(
  input wire clk,
  input wire rst_n,
  input wire rx,
  output reg data_valid,
  output reg [7:0] data_byte,
  output reg framing_error
);
  localparam S_IDLE = 3'd0;
  localparam S_START = 3'd1;
  localparam S_DATA = 3'd2;
  localparam S_STOP = 3'd3;

  localparam COUNT_W = $clog2(CLKS_PER_BIT + 1);
  reg [2:0] state;
  reg [COUNT_W-1:0] clock_count;
  reg [2:0] bit_index;
  reg [7:0] shift;
  reg rx_meta;
  reg rx_sync;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
    end else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE;
      clock_count <= {COUNT_W{1'b0}};
      bit_index <= 3'd0;
      shift <= 8'd0;
      data_valid <= 1'b0;
      data_byte <= 8'd0;
      framing_error <= 1'b0;
    end else begin
      data_valid <= 1'b0;
      framing_error <= 1'b0;
      case (state)
        S_IDLE: begin
          clock_count <= {COUNT_W{1'b0}};
            if (!rx_sync)
            state <= S_START;
        end
        S_START: begin
          if (clock_count == (CLKS_PER_BIT / 2) - 1) begin
            clock_count <= {COUNT_W{1'b0}};
            if (!rx_sync) begin
              bit_index <= 3'd0;
              state <= S_DATA;
            end else begin
              state <= S_IDLE;
            end
          end else begin
            clock_count <= clock_count + 1'b1;
          end
        end
        S_DATA: begin
          if (clock_count == CLKS_PER_BIT - 1) begin
            clock_count <= {COUNT_W{1'b0}};
            shift[bit_index] <= rx_sync;
            if (bit_index == 3'd7)
              state <= S_STOP;
            else
              bit_index <= bit_index + 1'b1;
          end else begin
            clock_count <= clock_count + 1'b1;
          end
        end
        S_STOP: begin
          if (clock_count == CLKS_PER_BIT - 1) begin
            clock_count <= {COUNT_W{1'b0}};
            if (rx_sync) begin
              data_byte <= shift;
              data_valid <= 1'b1;
            end else begin
              framing_error <= 1'b1;
            end
            state <= S_IDLE;
          end else begin
            clock_count <= clock_count + 1'b1;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end
endmodule