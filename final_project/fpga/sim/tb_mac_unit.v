`timescale 1ns/1ps
module tb_mac_unit;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg start = 1'b0;
  reg clear = 1'b0;
  reg signed [15:0] a = 16'sd0;
  reg signed [15:0] b = 16'sd0;
  wire done;
  wire signed [31:0] acc;
  wire signed [15:0] result;
  wire overflow;
  integer failures = 0;

  always #5 clk = ~clk;
  mac_unit dut (
    .clk(clk), .rst_n(rst_n), .start(start), .clear(clear),
    .operand_a_q88(a), .operand_b_q88(b), .done(done),
    .accumulator_q1616(acc), .result_q88(result), .overflow(overflow)
  );

  task step;
    input signed [15:0] value_a;
    input signed [15:0] value_b;
    begin
      @(negedge clk); a = value_a; b = value_b; start = 1'b1;
      @(negedge clk); start = 1'b0;
      @(negedge clk);
    end
  endtask

  task expect_result;
    input signed [15:0] expected;
    begin
      if (result !== expected) begin
        $display("FALHA result=%0d esperado=%0d", result, expected);
        failures = failures + 1;
      end
    end
  endtask

  initial begin
    $dumpfile("build/tb_mac_unit.vcd");
    $dumpvars(0, tb_mac_unit);
    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    step(16'sd256, 16'sd256); // 1.0 x 1.0
    expect_result(16'sd256);
    step(-16'sd256, 16'sd128); // soma -0.5
    expect_result(16'sd128);
    
    @(negedge clk); clear = 1'b1;
    @(negedge clk); clear = 1'b0;
    @(negedge clk);
    expect_result(16'sd0);

    step(16'sd32767, 16'sd32767);
    step(16'sd32767, 16'sd32767);
    step(16'sd32767, 16'sd32767);

    if (!overflow) begin
      $display("FALHA overflow nao ativou");
      failures = failures + 1;
    end

    if (failures == 0)
      $display("PASS tb_mac_unit");
    else
    $fatal(1, "FALHA tb_mac_unit: %0d erros", failures);
    $finish;
  end
endmodule
