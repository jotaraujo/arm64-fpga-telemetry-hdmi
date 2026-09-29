`timescale 1ns/1ps
module tb_mac_unit_v2;

    reg clk, rst_n, oe, mac_en, clear_acc;
    reg signed [15:0] a, b;
    wire signed [31:0] acc;
    wire overflow;
    wire signed [15:0] acc_q88;

    mac_unit #(.FRAC_BITS(8)) dut (
        .clk(clk), .rst_n(rst_n), .oe(oe),
        .a(a), .b(b), .mac_en(mac_en), .clear_acc(clear_acc),
        .acc(acc), .overflow(overflow), .acc_q88(acc_q88)
    );

    always #10 clk = ~clk;

    task do_mac(input signed [15:0] va, input signed [15:0] vb);
        begin
            a = va; b = vb; mac_en = 1;
            @(posedge clk); #1;
            mac_en = 0;
            @(posedge clk); #1;
        end
    endtask

    task do_clear;
        begin
            clear_acc = 1; @(posedge clk); #1;
            clear_acc = 0; @(posedge clk); #1;
        end
    endtask

    initial begin
        $dumpfile("tb_mac_unit_v2.vcd");
        $dumpvars(0, tb_mac_unit_v2);

        clk=0; rst_n=0; oe=1; mac_en=0; clear_acc=0; a=0; b=0;
        repeat(2) @(posedge clk);
        rst_n = 1; #1;

        do_mac(0, 32767);
        if (acc !== 0)
            $display("FALHA Caso1: acc=%0d", acc);
        else $display("OK Caso1: zero preservado, acc=%0d", acc);

        do_clear;
        do_mac(256, 256);
        if (acc !== 32'd65536)
            $display("FALHA Caso2: acc=%0d (esperado 65536)", acc);
        else $display("OK Caso2: Q8.8 1.0*1.0=65536 (acc_q88=%0d)", acc_q88);

        do_clear;
        do_mac(32767, 32767);
        do_mac(32767, 32767);
        do_mac(32767, 32767);
        if (acc !== 32'sh7FFFFFFF || overflow !== 1)
            $display("FALHA Caso3: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso3: saturacao positiva no limite, acc=%0d", acc);

        do_clear;
        do_mac(100, 100);
        oe = 0;
        do_mac(200, 200);
        oe = 1;
        if (acc !== 32'sd10000)
            $display("FALHA Caso4: acc=%0d (esperado 10000, OE deveria congelar)", acc);
        else $display("OK Caso4: OE=0 congelou saida, acc=%0d", acc);

        do_clear;
        do_mac(10, 20);
        if (acc !== 32'sd200 || overflow !== 0)
            $display("FALHA Caso5: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso5: operacao normal apos saturacao+clear, acc=%0d", acc);

        do_clear;
        do_mac(-32768, 32767);
        do_mac(-32768, 32767);
        do_mac(-32768, 32767);
        if (acc !== 32'sh80000000 || overflow !== 1)
            $display("FALHA Caso6: acc=%0d overflow=%b", acc, overflow);
        else $display("OK Caso6: saturacao negativa, acc=%0d", acc);

        #50;
        $display("Testbench v2 concluido.");
        $finish;
    end
endmodule