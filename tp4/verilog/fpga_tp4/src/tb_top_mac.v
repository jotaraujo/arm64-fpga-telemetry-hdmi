`timescale 1ns/1ps

module tb_top_mac;

    reg clk, rst_n;
    reg step_pulse, reset_pulse;
    wire [5:0] addr;
    wire mac_en, clear_acc;

    mac_control u_ctrl (
        .clk(clk), .rst_n(rst_n),
        .step_pulse(step_pulse), .reset_pulse(reset_pulse),
        .addr(addr), .mac_en(mac_en), .clear_acc(clear_acc)
    );

    wire signed [15:0] coeff_dout, sample_dout;
    coeff_rom  u_coeff  (.clk(clk), .addr(addr), .dout(coeff_dout));
    sample_rom u_sample (.clk(clk), .addr(addr), .dout(sample_dout));

    wire signed [31:0] acc;
    wire overflow;

    mac_unit u_mac (
        .clk(clk), .rst_n(rst_n),
        .a(coeff_dout), .b(sample_dout),
        .mac_en(mac_en), .clear_acc(clear_acc),
        .acc(acc), .overflow(overflow)
    );

    always #10 clk = ~clk;

    task press_step;
        begin
            step_pulse = 1'b1; @(posedge clk); #1;
            step_pulse = 1'b0;
            repeat (3) @(posedge clk); #1;
        end
    endtask

    integer i;
    initial begin
        $dumpfile("tb_top_mac.vcd");
        $dumpvars(0, tb_top_mac);

        clk = 0; rst_n = 0; step_pulse = 0; reset_pulse = 0;
        repeat (2) @(posedge clk);
        rst_n = 1; #1;

        // Executa 8 passos consecutivos, lendo da BRAM (coeff/sample) via mac_control
        for (i = 0; i < 8; i = i + 1) press_step;

        $display("Apos 8 passos: addr=%0d acc=%0d overflow=%b", addr, acc, overflow);

        #50;
        $display("Testbench de integracao concluido.");
        $finish;
    end
endmodule