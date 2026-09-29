`timescale 1ns/1ps
module tb_pattern_stream;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg [1:0] mode = 2'd0;
  reg ready = 1'b1;

  wire [9:0] telemetry_addr;
  wire frame_start;
  wire valid;
  wire [23:0] data;
  wire [0:0] user;

  integer failures = 0;
  integer starts = 0;

  always #5 clk = ~clk;

  pattern_stream #(.H_VISIBLE(640), .V_VISIBLE(2)) dut (
    .clk(clk), .rst_n(rst_n), .mode(mode), .base_color(24'h204080),
    .telemetry_sample(16'sd0), .telemetry_count(10'd0),
    .telemetry_addr(telemetry_addr), .frame_start(frame_start),
    .out_axis_tvalid(valid), .out_axis_tready(ready),
    .out_axis_tdata(data), .out_axis_tuser(user)
  );

  always @(posedge clk) begin
    if (valid && ready && user[0])
      starts = starts + 1;
  end

  task restart_frame;
    begin
      rst_n = 1'b0;
      repeat (2) @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  task expect_indicator;
    input [1:0] expected_mode;
    reg [23:0] expected_bit1;
    reg [23:0] expected_bit0;
    begin
      mode = expected_mode;
      restart_frame();

      expected_bit1 = expected_mode[1] ? 24'hffffff : 24'h202020;
      expected_bit0 = expected_mode[0] ? 24'hffffff : 24'h202020;

      while (!(dut.y == 0 && dut.x == 10'd565))
        @(negedge clk);
      if (data !== expected_bit1) begin
        $display("FALHA mode=%b indicador bit1 data=%h esperado=%h",
          expected_mode, data, expected_bit1);
        failures = failures + 1;
      end

      while (!(dut.y == 0 && dut.x == 10'd605))
        @(negedge clk);
      if (data !== expected_bit0) begin
        $display("FALHA mode=%b indicador bit0 data=%h esperado=%h",
          expected_mode, data, expected_bit0);
        failures = failures + 1;
      end
    end
  endtask

  initial begin
    $dumpfile("build/tb_pattern_stream.vcd");
    $dumpvars(0, tb_pattern_stream);

    expect_indicator(2'b00);
    expect_indicator(2'b01);
    expect_indicator(2'b10);
    expect_indicator(2'b11);

    if (starts < 4) begin
      $display("FALHA frame_start starts=%0d", starts);
      failures = failures + 1;
    end

    if (failures == 0)
      $display("PASS tb_pattern_stream: active_mode 00/01/10/11 visivel no HDMI");
    else
      $fatal(1, "FALHA tb_pattern_stream: %0d erros", failures);
    $finish;
  end
endmodule