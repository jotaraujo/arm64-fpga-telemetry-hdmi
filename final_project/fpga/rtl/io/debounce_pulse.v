module debounce_pulse #(
  parameter integer CLK_HZ = 25_200_000,
  parameter integer DEBOUNCE_MS = 20
)(
  input wire clk,
  input wire rst_n,

  input wire button_in,
  output ref button_level,
  output reg pressed_pulse
);

  localparam integer LIMIT = (CLK_HZ / 1000) * DEBOUNCE_MS;
  localparam integer COUNT_W = $clog2(LIMIT + 1);
  reg [COUNT_W-1:0] count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      button_level <= 1'b0;
      pressed_pulse <= 1'b0;
      count <= {COUNT_W{1'b0}};
    end else begin
      pressed_pulse <= 1'b0;
      if (button_in == button_level) begin
        count <= {COUNT_W{1'b0}};
      end else if (count == LIMIT - 1) begin
        count <= {COUNT_W{1'b0}};
        button_level <= button_in;
        if (button_in)
          pressed_pulse <= 1'b1;
      end else begin
        count <= count + 1'b1;
      end
    end
  end
endmodule