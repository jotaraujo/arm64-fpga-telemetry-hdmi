`timescale 1ns/1ps
// Teste de integracao: pacote incompleto, framing error e recuperacao.
// Este teste E ESPERADO FALHAR no parser original, sem timeout/aborto.
// Compilar a partir de final_project/fpga/sim.
module tb_packet_recovery;
    localparam integer CLKS_PER_BIT = 16;
    localparam integer PACKET_TIMEOUT_CYCLES = CLKS_PER_BIT * 40;
    localparam integer MAX_WAIT = 2500;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx = 1'b1;
    wire tx;
    wire [15:0] error_count;
    wire response_valid;
    wire [7:0] response_status;
    wire tx_byte_valid;
    wire [7:0] tx_byte;
    wire tx_framing_error;
    integer ack_count = 0;
    integer cmd_count = 0;
    integer response_bytes = 0;
    integer tx_errors = 0;
    integer i;
    integer clocks_waited;
    reg [7:0] packet [0:9];

    always #5 clk = ~clk;

    // Usa apenas portas comprovadas em ambas as variantes do protocol_system.
    protocol_system #(.CLKS_PER_BIT(CLKS_PER_BIT), .CLK_HZ(1000)) dut (
        .clk(clk), .rst_n(rst_n), .uart_rx_in(rx),
        .uart_tx_out(tx), .frame_start(1'b0),
        .error_count(error_count),
        .response_valid_debug(response_valid),
        .response_status_debug(response_status)
    );

    // Monitora bytes de resposta pela UART TX, nao so sinais de debug.
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) monitor (
        .clk(clk), .rst_n(rst_n), .rx(tx),
        .data_valid(tx_byte_valid), .data_byte(tx_byte),
        .framing_error(tx_framing_error)
    );

    always @(posedge clk) begin
        if (rst_n) begin
            if (response_valid) begin
                if (response_status !== 8'd0)
                    $fatal(1,"FAIL resposta inesperada: status=%0d", response_status);
                ack_count = ack_count+1;
            end
            if (dut.cmd_valid) cmd_count = cmd_count+1;
            if (tx_byte_valid) response_bytes = response_bytes+1;
            if (tx_framing_error) tx_errors = tx_errors+1;
        end
    end

    function [7:0] crc8_next;
        input [7:0] old_crc;
        input [7:0] value;
        reg [7:0] c;
        integer bit_no;
        begin
            c = old_crc ^ value;
            for (bit_no=0;bit_no<8;bit_no=bit_no+1)
                c = c[7] ? ((c << 1) ^ 8'h07) : (c << 1);
            crc8_next = c;
        end
    endfunction

    task prepare_ping;
        input [7:0] seq;
        reg [7:0] c;
        integer j;
        begin
            packet[0]=8'hA5;
            packet[1]=8'h01;
            packet[2]=seq;
            packet[3]=8'h7F; // PING
            packet[4]=8'h04;
            packet[5]=8'h11;
            packet[6]=8'h22;
            packet[7]=8'h33;
            packet[8]=8'h44;
            c=0;
            for (j=1;j<9;j=j+1)
                c=crc8_next(c,packet[j]);
            packet[9]=c;
        end
    endtask

    task send_uart_byte;
        input [7:0] value;
        input good_stop;
        integer b;
        begin
            @(negedge clk); rx=1'b0;
            repeat (CLKS_PER_BIT) @(negedge clk);
            for (b=0;b<8;b=b+1) begin
                rx=value[b];
                repeat (CLKS_PER_BIT) @(negedge clk);
            end
            rx=good_stop;
            repeat (CLKS_PER_BIT) @(negedge clk);
            rx=1'b1;
            // Pequena folga para evitar que o final de um stop invalido
            // pareca um novo start.
            repeat (CLKS_PER_BIT*2) @(negedge clk);
        end
    endtask

    task send_packet;
        input integer nbytes;
        input integer stop_bad_at; // -1 se todos os stops sao corretos
        integer k;
        begin
            for(k=0;k<nbytes;k=k+1)
                send_uart_byte(packet[k],(k != stop_bad_at));
        end
    endtask

    task wait_response_bytes;
        input integer target;
        begin
            clocks_waited=0;
            while ((response_bytes<target) && (clocks_waited<MAX_WAIT)) begin
                @(negedge clk);
                clocks_waited=clocks_waited+1;
            end
            if(response_bytes != target)
                $fatal(1,"FAIL timeout/quantidade resposta: bytes=%0d esperado=%0d",response_bytes,target);
            repeat (4) @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("build/tb_packet_recovery.vcd");
        $dumpvars(0,tb_packet_recovery);
        repeat(8) @(negedge clk); rst_n=1'b1;
        repeat(8) @(negedge clk);

        // 1. Pacote completo, controle positivo.
        prepare_ping(8'd0); send_packet(10,-1);
        wait_response_bytes(8);
        if(ack_count!=1 || cmd_count!=1 || error_count!=0)
            $fatal(1,"FAIL PING inicial ACK=%0d CMD=%0d ERROR=%0d",ack_count,cmd_count,error_count);
        $display("PASS controle: PING completo recebido");

        // 2. Interromper no quarto byte; sem CRC, nao tem resposta util.
        prepare_ping(8'd1); send_packet(4,-1);
        repeat(PACKET_TIMEOUT_CYCLES+CLKS_PER_BIT*8) @(negedge clk);
        if(ack_count!=1 || cmd_count!=1 || response_bytes!=8 || error_count!=1)
            $fatal(1,"FAIL timeout: ack=%0d cmd=%0d respostas_bytes=%0d erros=%0d (esperado 1)",ack_count,cmd_count,response_bytes,error_count);
        $display("PASS timeout: pacote parcial foi descartado sem ACK/NACK");

        // 3. Novo pacote completo depois do timeout deve funcionar.
        prepare_ping(8'd1); send_packet(10,-1);
        wait_response_bytes(16);
        if(ack_count!=2 || cmd_count!=2 || error_count!=1)
            $fatal(1,"FAIL recuperacao apos timeout: ack=%0d cmd=%0d erros=%0d",ack_count,cmd_count,error_count);
        $display("PASS recuperacao: pacote valido apos interrupcao");

        // 4. Agora quebrar o STOP de um byte dentro de outro pacote.
        prepare_ping(8'd2); send_packet(5,4);
        repeat(CLKS_PER_BIT*6) @(negedge clk);
        if(ack_count!=2 || cmd_count!=2 || error_count!=2)
            $fatal(1,"FAIL erro UART: ack=%0d cmd=%0d erros=%0d (esperado 2)",ack_count,cmd_count,error_count);
        $display("PASS framing error: pacote abortado");

        // 5. Novo pacote completo deve ser aceito apos o framing error.
        prepare_ping(8'd2); send_packet(10,-1);
        wait_response_bytes(24);
        if(ack_count!=3 || cmd_count!=3 || error_count!=2 || tx_errors!=0)
            $fatal(1,"FAIL recuperacao apos UART: ACK=%0d CMD=%0d ERROR=%0d TX_ERR=%0d",ack_count,cmd_count,error_count,tx_errors);
        $display("PASS recuperacao UART: pacote valido apos stop invalido");
        $display("PASS tb_packet_recovery: ACK=3, comandos=3, erros_recepcao=2, respostas_bytes=24");
        $finish;
    end
endmodule
