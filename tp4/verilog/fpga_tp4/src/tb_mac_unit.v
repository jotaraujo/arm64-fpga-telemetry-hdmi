`timescale 1ns/1ps

module tb_mac_unit;

    reg clk, rst_n;
    reg signed [15:0] a, b;
    reg mac_en, clear_acc;
    wire signed [31:0] acc;
    wire overflow;

    mac_unit dut (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .mac_en(mac_en), .clear_acc(clear_acc),
        .acc(acc), .overflow(overflow)
    );

    always #10 clk = ~clk;

    task do_mac(input signed [15:0] va, input signed [15:0] vb);
        begin
            a = va; b = vb; mac_en = 1'b1;
            @(posedge clk); #1;
            mac_en = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $dumpfile("tb_mac_unit.vcd");
        $dumpvars(0, tb_mac_unit);

        clk = 0; rst_n = 0; a = 0; b = 0; mac_en = 0; clear_acc = 0;
        repeat (2) @(posedge clk);
        rst_n = 1; #1;

        // Caso 1: 100 * 50 = 5000
        do_mac(100, 50);
        if (acc !== 32'sd5000) $display("FALHA Caso1: acc=%0d (esperado 5000)", acc);
        else $display("OK Caso1: MAC positivo simples, acc=%0d", acc);

        // Caso 2: soma com valor negativo: -100*50 = -5000 -> acc volta a 0
        do_mac(-100, 50);
        if (acc !== 32'sd0) $display("FALHA Caso2: acc=%0d (esperado 0)", acc);
        else $display("OK Caso2: MAC com operando negativo, acc=%0d", acc);

        // Caso 3: satura no maximo positivo (32767*32767 aplicado duas vezes)
        do_mac(32767, 32767);
        do_mac(32767, 32767);
        do_mac(32767, 32767);
        if (acc !== 32'sh7FFFFFFF || overflow !== 1'b1)
            $display("FALHA Caso3: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso3: saturacao positiva detectada, acc=%0d overflow=%b", acc, overflow);

        // Caso 4: clear_acc reseta acumulador e flag de overflow
        clear_acc = 1'b1; @(posedge clk); #1; clear_acc = 1'b0; @(posedge clk); #1;
        if (acc !== 32'sd0 || overflow !== 1'b0)
            $display("FALHA Caso4: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso4: clear_acc funcionando, acc=%0d overflow=%b", acc, overflow);

        // Caso 5: satura no minimo negativo apos reset
        do_mac(-32768, 32767);
        do_mac(-32768, 32767);
        do_mac(-32768, 32767);
        if (acc !== 32'sh80000000 || overflow !== 1'b1)
            $display("FALHA Caso5: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso5: saturacao negativa detectada, acc=%0d overflow=%b", acc, overflow);

        // Caso 6: operacao normal apos novo clear
        clear_acc = 1'b1; @(posedge clk); #1; clear_acc = 1'b0; @(posedge clk); #1;
        do_mac(10, 10);
        if (acc !== 32'sd100 || overflow !== 1'b0)
            $display("FALHA Caso6: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso6: operacao normal restaurada, acc=%0d overflow=%b", acc, overflow);

        #50;
        $display("Testbench concluido.");
        $finish;
    end
endmodule