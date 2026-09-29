`timescale 1ns/1ps
module tb_led_status;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg accepted_pulse = 1'b0;
  reg protocol_error_pulse = 1'b0;
  reg fatal_error = 1'b0;
  reg clear_pulse = 1'b0;
  wire led_pin;

  integer failures = 0;
  integer rise_count = 0;
  integer toggle_count = 0;
  reg previous_led = 1'b0;
  integer baseline;

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n) begin
      if (led_pin && !previous_led)
        rise_count = rise_count + 1;
      if (led_pin != previous_led)
        toggle_count = toggle_count + 1;
        previous_led <= led_pin;
    end
  end

  led_status #(
    .CLK_HZ(1000),
    .COMMAND_MS(4),
    .PROTOCOL_MS(2),
    .FATAL_HALF_MS(2)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .accepted_pulse(accepted_pulse),
    .protocol_error_pulse(protocol_error_pulse),
    .fatal_error(fatal_error),
    .clear_pulse(clear_pulse),
    .led_pin(led_pin)
  );

  initial begin
    $dumpfile("build/tb_led_status.vcd");
    $dumpvars(0, tb_led_status);

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(negedge clk);

    // Comando aceito: uma piscada e retorno ao apagado.
    baseline = rise_count;
    accepted_pulse = 1'b1;
    @(negedge clk); accepted_pulse = 1'b0;
    repeat (8) @(negedge clk);
    if (rise_count - baseline < 1 || led_pin !== 1'b0)
      failures = failures + 1;

    // Erro de protocolo: duas piscadas e retorno ao apagado.
    baseline = rise_count;
    protocol_error_pulse = 1'b1;
    @(negedge clk); protocol_error_pulse = 1'b0;
    repeat (12) @(negedge clk);
    if (rise_count - baseline < 2 || led_pin !== 1'b0)
      failures = failures + 1;

    // Erro grave: piscada continua ate CLEAR.
    baseline = toggle_count;
    fatal_error = 1'b1;
    @(negedge clk); fatal_error = 1'b0;
    repeat (12) @(negedge clk);
    if (toggle_count - baseline < 4)
      failures = failures + 1;

    clear_pulse = 1'b1;
    @(negedge clk); clear_pulse = 1'b0;
    repeat (2) @(negedge clk);
    if (led_pin !== 1'b0)
      failures = failures + 1;

    if (failures == 0)
      $display("PASS tb_led_status");
    else
      $fatal(1, "FALHA tb_led_status: %0d erros", failures);
    $finish;
  end
endmodule