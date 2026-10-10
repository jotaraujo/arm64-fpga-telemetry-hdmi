`timescale 1ns/1ps
// Teste unitario de UART RX: 256 bytes, stop bit invalido e falso start.
// Compilar a partir de final_project/fpga/sim.
module tb_uart_stress;
    localparam integer CLKS_PER_BIT = 16;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx = 1'b1;
    wire data_valid;
    wire [7:0] data_byte;
    wire framing_error;
    integer received = 0;
    integer framing_errors = 0;
    reg [7:0] last_byte;
    integer i;
    integer previous;
    integer old_errors;

    always #5 clk = ~clk;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk), .rst_n(rst_n), .rx(rx),
        .data_valid(data_valid), .data_byte(data_byte),
        .framing_error(framing_error)
    );

    always @(posedge clk) begin
        if (rst_n) begin
            if (data_valid) begin
                received = received + 1;
                last_byte = data_byte;
            end
            if (framing_error)
                framing_errors = framing_errors + 1;
        end
    end

    task send_uart_byte;
        input [7:0] value;
        input good_stop;
        integer b;
        begin
            @(negedge clk); rx = 1'b0; // start
            repeat (CLKS_PER_BIT) @(negedge clk);
            for (b=0; b<8; b=b+1) begin
                rx = value[b];
                repeat (CLKS_PER_BIT) @(negedge clk);
            end
            rx = good_stop; // forcar erro fisico no stop bit, se 0
            repeat (CLKS_PER_BIT) @(negedge clk);
            rx = 1'b1;
            repeat (CLKS_PER_BIT*2) @(negedge clk);
        end
    endtask

    task check_byte;
        input [7:0] value;
        begin
            previous = received;
            send_uart_byte(value, 1'b1);
            repeat (3) @(negedge clk);
            if ((received != previous + 1) || (last_byte !== value))
                $fatal(1, "FAIL UART byte=%h recebido=%h delta=%0d", value, last_byte, received-previous);
        end
    endtask

    initial begin
        $dumpfile("build/tb_uart_stress.vcd");
        $dumpvars(0,tb_uart_stress);
        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (8) @(negedge clk);

        // Exaustivo no espaco pequeno: cada byte possivel.
        for (i=0; i<256; i=i+1)
            check_byte(i[7:0]);
        $display("PASS UART: 256 valores de byte recebidos");

        // Start falso: duracao muito menor do que meio bit.
        previous = received;
        @(negedge clk); rx = 1'b0;
        repeat (2) @(negedge clk);
        rx = 1'b1;
        repeat (CLKS_PER_BIT*3) @(negedge clk);
        if (received != previous)
            $fatal(1,"FAIL UART falso start gerou byte");
        $display("PASS UART: pulso de falso start ignorado");

        // Stop errado: DEVE detectar framing_error, sem entregar byte.
        previous = received;
        old_errors = framing_errors;
        send_uart_byte(8'h55,1'b0);
        repeat (3) @(negedge clk);
        if (received != previous || framing_errors != old_errors+1)
            $fatal(1,"FAIL UART stop: recebidos=%0d erro_delta=%0d", received-previous,framing_errors-old_errors);
        $display("PASS UART: stop bit invalido detectado");

        // O receptor precisa continuar funcionando depois do erro.
        check_byte(8'hA5);
        $display("PASS UART: recuperou-se do stop bit invalido");
        $display("PASS tb_uart_stress: bytes_validos=%0d framing_errors=%0d", received, framing_errors);
        $finish;
    end
endmodule
