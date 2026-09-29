`timescale 1ns/1ps
module tb_arm_fpga_protocol;
  localparam CLKS_PER_BIT = 8;
  localparam COMMAND_BYTES = 80;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg uart_rx_line = 1'b1;
  reg frame_start = 1'b0;
  wire uart_tx_line;
  wire [1:0] active_mode;
  wire [23:0] active_color;
  wire signed [15:0] gain_q88;
  wire signed [15:0] mac_result_q88;
  wire [15:0] error_count;
  wire status_led_debug;
  wire response_valid;
  wire [7:0] response_status;

  reg [7:0] command_mem [0:COMMAND_BYTES-1];
  integer ack_count = 0;
  integer bad_crc_count = 0;
  integer duplicate_count = 0;
  integer tx_byte_count = 0;
  integer failures = 0;

  always #5 clk = ~clk;
  protocol_system #(.CLKS_PER_BIT(CLKS_PER_BIT), .CLK_HZ(1000)) dut (
    .clk(clk), .rst_n(rst_n), .uart_rx_in(uart_rx_line),
    .uart_tx_out(uart_tx_line), .frame_start(frame_start),
    .active_mode(active_mode), .active_color(active_color),
    .gain_q88(gain_q88), .mac_result_q88(mac_result_q88),
    .error_count(error_count), .status_led_debug(status_led_debug),
    .response_valid_debug(response_valid),
    .response_status_debug(response_status)
  );

  wire tx_monitor_valid;
  wire [7:0] tx_monitor_byte;
  wire tx_monitor_error;
  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_monitor (
    .clk(clk), .rst_n(rst_n), .rx(uart_tx_line),
    .data_valid(tx_monitor_valid), .data_byte(tx_monitor_byte),
    .framing_error(tx_monitor_error)
  );

  always @(posedge clk) begin
    if (response_valid) begin
      case (response_status)
        8'd0: ack_count = ack_count + 1;
        8'd1: bad_crc_count = bad_crc_count + 1;
        8'd2: duplicate_count = duplicate_count + 1;
        default: failures = failures + 1;
      endcase
    end
    if (tx_monitor_valid)
      tx_byte_count = tx_byte_count + 1;
    if (tx_monitor_error)
      failures = failures + 1;
  end

  task send_uart_byte;
    input [7:0] value;
    integer bit_number;
    begin
      @(negedge clk); uart_rx_line = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        uart_rx_line = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      uart_rx_line = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  task send_packet;
    input integer base;
    input corrupt_crc;
    integer offset;
    reg [7:0] value;
    begin
      for (offset = 0; offset < 10; offset = offset + 1) begin
        value = command_mem[base + offset];
        if (corrupt_crc && offset == 9)
          value = value ^ 8'h01;
        send_uart_byte(value);
      end
    end
  endtask

  task apply_frame_start;
    begin
      @(negedge clk); frame_start = 1'b1;
      @(negedge clk); frame_start = 1'b0;
    end
  endtask

  initial begin
    $readmemh("commands.hex", command_mem);
    $dumpfile("build/tb_arm_fpga_protocol.vcd");
    $dumpvars(0, tb_arm_fpga_protocol);
    repeat (6) @(negedge clk);
    rst_n = 1'b1;

    send_packet(0, 1'b0); apply_frame_start();
    send_packet(10, 1'b0); apply_frame_start();
    send_packet(20, 1'b0); apply_frame_start();
    send_packet(30, 1'b0); apply_frame_start();
    send_packet(40, 1'b0); apply_frame_start();
    send_packet(50, 1'b0); apply_frame_start();
    send_packet(60, 1'b0); apply_frame_start();
    send_packet(70, 1'b0); apply_frame_start();
    repeat (20) @(negedge clk);

    if (active_mode !== 2'd3) begin
      $display("FALHA active_mode=%0d", active_mode);
      failures = failures + 1;
    end

    if (active_color !== 24'h2080e0) begin
      $display("FALHA active_color=%h", active_color);
      failures = failures + 1;
    end

    if (gain_q88 !== 16'sh0180) begin
      $display("FALHA gain=%0d", gain_q88);
      failures = failures + 1;
    end

    if (mac_result_q88 !== 16'sd64) begin
      $display("FALHA MAC=%0d", mac_result_q88);
      failures = failures + 1;
    end

    send_packet(0, 1'b1); // CRC incorreto
    send_packet(70, 1'b0); // sequencia 7 repetida
    repeat (1000) @(negedge clk);

    if (ack_count != 8) begin
      $display("FALHA ACK=%0d", ack_count);
      failures = failures + 1;
    end

    if (bad_crc_count != 1 || duplicate_count != 1 || error_count != 2) begin
      $display("FALHA NACK crc=%0d dup=%0d errors=%0d",
      bad_crc_count, duplicate_count, error_count);
      failures = failures + 1;
    end

    if (tx_byte_count < 80) begin
      $display("FALHA TX retornou apenas %0d bytes", tx_byte_count);
      failures = failures + 1;
    end

    if (failures == 0)
      $display("PASS integracao ARM64 FPGA: 8 ACK, CRC e duplicata detectados");
    else
      $fatal(1, "FALHA integracao: %0d erros", failures);
    $finish;
  end
endmodule