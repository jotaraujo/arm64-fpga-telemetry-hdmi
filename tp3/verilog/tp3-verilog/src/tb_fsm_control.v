`timescale 1ns/1ps

module tb_fsm_control;

    reg clk, rst_n;
    reg cmd_trigger_sync;
    reg [1:0] cmd_data_sync;
    wire busy, error_flag, error_latch;
    wire [1:0] led_result;

    fsm_control #(.STABLE_CYCLES(3)) dut (
        .clk(clk), .rst_n(rst_n),
        .cmd_trigger_sync(cmd_trigger_sync),
        .cmd_data_sync(cmd_data_sync),
        .busy(busy), .error_flag(error_flag), .error_latch(error_latch),
        .led_result(led_result)
    );

    always #10 clk = ~clk;

    task send_command(input [1:0] cmd, input integer hold_cycles);
        integer i;
        begin
            cmd_data_sync    = cmd;
            cmd_trigger_sync = 1'b1;
            for (i = 0; i < hold_cycles; i = i + 1) @(posedge clk);
            cmd_trigger_sync = 1'b0;
            cmd_data_sync    = 2'b00;
            @(posedge clk); @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_fsm_control.vcd");
        $dumpvars(0, tb_fsm_control);

        clk = 0; rst_n = 0;
        cmd_trigger_sync = 0; cmd_data_sync = 2'b00;
        repeat (4) @(posedge clk);
        rst_n = 1;

        // Caso 1: LED_ON
        send_command(2'b01, 5); #5;
        if (led_result !== 2'b01 || error_flag !== 1'b0)
            $display("FALHA Caso1: led_result=%b error=%b", led_result, error_flag);
        else $display("OK Caso1: LED_ON aplicado corretamente");

        // Caso 2: STATUS
        send_command(2'b10, 5); #5;
        if (led_result !== 2'b10) $display("FALHA Caso2: led_result=%b", led_result);
        else $display("OK Caso2: STATUS aplicado corretamente");

        // Caso 3: LED_OFF
        send_command(2'b00, 5); #5;
        if (led_result !== 2'b00) $display("FALHA Caso3: led_result=%b", led_result);
        else $display("OK Caso3: LED_OFF aplicado corretamente");

        // Caso 4: comando invalido
        send_command(2'b11, 5); #5;
        if (dut.error_latch !== 1'b1)
            $display("FALHA Caso4: error_latch=%b", dut.error_latch);
        else $display("OK Caso4: erro detectado para comando 11");

        // Caso 5: glitch (trigger sobe e cai antes de STABLE_CYCLES)
        cmd_data_sync = 2'b01; cmd_trigger_sync = 1'b1;
        @(posedge clk);
        cmd_trigger_sync = 1'b0; cmd_data_sync = 2'b00;
        repeat (3) @(posedge clk);
        if (dut.state !== 3'b000)
            $display("FALHA Caso5: state=%b (esperado IDLE)", dut.state);
        else $display("OK Caso5: glitch ignorado, retorno a IDLE");

        // Caso 6: recuperacao apos erro
        send_command(2'b01, 5); #5;
        if (dut.error_latch !== 1'b0 || led_result !== 2'b01)
            $display("FALHA Caso6: error_latch=%b led_result=%b", dut.error_latch, led_result);
        else $display("OK Caso6: erro limpo apos novo comando valido");

        #50;
        $display("Testbench concluido.");
        $finish;
    end
endmodule