module protocol_system #(
  parameter integer CLKS_PER_BIT = 219,
  parameter integer CLK_HZ = 25_200_000
)(
  input wire clk,
  input wire rst_n,
  input wire uart_rx_in,
  output wire uart_tx_out,
  input wire frame_start,
  output wire [1:0] active_mode,
  output wire [23:0] active_color,
  output wire signed [15:0] gain_q88,
  output wire signed [15:0] mac_result_q88,
  output wire [15:0] error_count,
  output wire status_led_debug,
  output wire response_valid_debug,
  output wire [7:0] response_status_debug
);
  wire rx_byte_valid;
  wire [7:0] rx_byte;
  wire framing_error;

  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) receiver (
    .clk(clk), .rst_n(rst_n), .rx(uart_rx_in),
    .data_valid(rx_byte_valid), .data_byte(rx_byte), .framing_error(framing_error)
  );

  wire cmd_valid;
  wire [7:0] cmd_seq;
  wire [7:0] cmd_id;
  wire [7:0] cmd_length;
  wire [31:0] cmd_payload;
  wire parser_response_valid;
  wire [7:0] response_seq;
  wire [7:0] response_status;
  wire [15:0] response_error_count;
  wire parser_error_pulse;

  packet_parser parser (
    .clk(clk), .rst_n(rst_n), .byte_valid(rx_byte_valid), .byte_data(rx_byte),
    .cmd_valid(cmd_valid), .cmd_seq(cmd_seq), .cmd_id(cmd_id),
    .cmd_length(cmd_length), .cmd_payload(cmd_payload),
    .response_valid(parser_response_valid), .response_seq(response_seq),
    .response_status(response_status), .response_error_count(response_error_count),
    .error_pulse(parser_error_pulse), .error_count(error_count)
  );

  wire cmd_ready;
  wire accepted_pulse;
  wire command_error_pulse;
  wire clear_pulse;
  wire mac_start;
  wire signed [15:0] mac_operand_a;
  wire signed [15:0] mac_operand_b;

  command_executor executor (
    .clk(clk), .rst_n(rst_n), .frame_start(frame_start),
    .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_id(cmd_id),
    .cmd_payload(cmd_payload), .accepted_pulse(accepted_pulse),
    .command_error_pulse(command_error_pulse), .clear_pulse(clear_pulse),
    .mac_start(mac_start), .mac_operand_a(mac_operand_a),
    .mac_operand_b(mac_operand_b), .active_mode(active_mode),
    .active_color(active_color), .gain_q88(gain_q88)
  );
  wire mac_done;
  wire signed [31:0] accumulator_q1616;
  wire mac_overflow;

  mac_unit mac (
    .clk(clk), .rst_n(rst_n), .start(mac_start), .clear(clear_pulse),
    .operand_a_q88(mac_operand_a), .operand_b_q88(mac_operand_b),
    .done(mac_done), .accumulator_q1616(accumulator_q1616),
    .result_q88(mac_result_q88), .overflow(mac_overflow)
  );

  wire tx_data_valid;
  wire tx_data_ready;
  wire [7:0] tx_data;
  wire dropped_response;

  response_builder responses (
    .clk(clk), .rst_n(rst_n), .response_valid(parser_response_valid),
    .response_seq(response_seq), .response_status(response_status),
    .active_mode(active_mode), .error_count(response_error_count),
    .tx_data_valid(tx_data_valid), .tx_data_ready(tx_data_ready),
    .tx_data(tx_data), .dropped_response(dropped_response)
  );

  wire tx_busy;
  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter (
    .clk(clk), .rst_n(rst_n), .data_valid(tx_data_valid),
    .data_ready(tx_data_ready), .data_byte(tx_data), .tx(uart_tx_out), .busy(tx_busy)
  );

  led_status #(.CLK_HZ(CLK_HZ)) status_indicator (
    .clk(clk),
    .rst_n(rst_n),
    .accepted_pulse(accepted_pulse),
    .protocol_error_pulse(
      parser_error_pulse |
      command_error_pulse |
      framing_error |
      dropped_response
    ),
    .fatal_error(mac_overflow),
    .clear_pulse(clear_pulse),
    .led_pin(status_led_debug)
  );
  
  assign response_valid_debug = parser_response_valid;
  assign response_status_debug = response_status;
endmodule