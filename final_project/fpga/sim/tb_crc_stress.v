`timescale 1ns/1ps

// Testbench de CRC para gen_crc_stress.py.
// 2630 casos: 2 validos; 72 erros simples; 2556 erros duplos.
// Requer protocolo com PING 0x7F e CRC-8 (poly 0x07).
// Rode a simulação a partir de final_project/fpga/sim.
module tb_crc_stress;
    localparam integer CLKS_PER_BIT   = 8;
    localparam integer PACKET_COUNT   = 2630;
    localparam integer PACKET_BYTES   = 10;
    localparam integer RESPONSE_BYTES = 8;
    localparam integer WAIT_LIMIT     = 3000;

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
    wire response_valid;
    wire [7:0] response_status;

    reg [7:0] packet_mem [0:PACKET_COUNT*PACKET_BYTES-1];
    reg [7:0] expected_mem [0:PACKET_COUNT-1];
    reg [7:0] reply [0:RESPONSE_BYTES-1];

    integer rx_response_bytes = 0;
    integer response_pulses = 0;
    integer command_pulses = 0;
    integer mac_start_pulses = 0;
    integer mac_done_pulses = 0;
    integer clear_pulses = 0;
    integer response_uart_errors = 0;
    integer expected_errors = 0;
    integer failures = 0;
    integer passed = 0;
    integer cases_to_run = PACKET_COUNT;
    integer test_index;

    always #5 clk = ~clk;

    protocol_system #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .CLK_HZ(1000)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_in(uart_rx_line),
        .uart_tx_out(uart_tx_line),
        .frame_start(frame_start),
        .active_mode(active_mode),
        .active_color(active_color),
        .gain_q88(gain_q88),
        .mac_result_q88(mac_result_q88),
        .error_count(error_count),
        .response_valid_debug(response_valid),
        .response_status_debug(response_status)
    );

    // Segundo receptor UART: captura de fato os bytes transmitidos
    // pela saída uart_tx_out, em vez de confiar só no debug do parser.
    wire tx_byte_valid;
    wire [7:0] tx_byte;
    wire tx_framing_error;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_monitor (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_tx_line),
        .data_valid(tx_byte_valid),
        .data_byte(tx_byte),
        .framing_error(tx_framing_error)
    );

    // Contadores de eventos (sem dependência de DUT físico).
    always @(posedge clk) begin
        if (rst_n) begin
            if (tx_byte_valid) begin
                reply[rx_response_bytes % RESPONSE_BYTES] = tx_byte;
                rx_response_bytes = rx_response_bytes + 1;
            end
            if (tx_framing_error)
                response_uart_errors = response_uart_errors + 1;
            if (response_valid)
                response_pulses = response_pulses + 1;
            if (dut.cmd_valid)
                command_pulses = command_pulses + 1;
            if (dut.mac_start)
                mac_start_pulses = mac_start_pulses + 1;
            if (dut.mac_done)
                mac_done_pulses = mac_done_pulses + 1;
            if (dut.clear_pulse)
                clear_pulses = clear_pulses + 1;
        end
    end

    function [7:0] crc8_next;
        input [7:0] old_crc;
        input [7:0] new_byte;
        reg [7:0] c;
        integer k;
        begin
            c = old_crc ^ new_byte;
            for (k = 0; k < 8; k = k + 1)
                c = c[7] ? ((c << 1) ^ 8'h07) : (c << 1);
            crc8_next = c;
        end
    endfunction

    task send_uart_byte;
        input [7:0] value;
        integer bit_number;
        begin
            @(negedge clk);
            uart_rx_line = 1'b0; // start bit
            repeat (CLKS_PER_BIT) @(negedge clk);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                uart_rx_line = value[bit_number]; // LSB first
                repeat (CLKS_PER_BIT) @(negedge clk);
            end
            uart_rx_line = 1'b1; // stop bit
            repeat (CLKS_PER_BIT) @(negedge clk);
        end
    endtask

    task start_new_video_frame;
        begin
            @(negedge clk);
            frame_start = 1'b1;
            @(negedge clk);
            frame_start = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task run_case;
        input integer case_number;
        integer base;
        integer j;
        integer wait_cycles;
        integer old_rx_bytes;
        integer old_rsp_pulses;
        integer old_cmd_pulses;
        integer old_mac_start_pulses;
        integer old_mac_done_pulses;
        integer old_clear_pulses;
        integer old_uart_errors;
        integer old_failures;
        reg [7:0] expected_status;
        reg [7:0] command_id;
        reg [7:0] sequence_number;
        reg [31:0] payload;
        reg [1:0] prior_mode;
        reg [23:0] prior_color;
        reg [15:0] prior_gain;
        reg [15:0] prior_mac_result;
        reg [7:0] crc_check;
        begin
            base = case_number * PACKET_BYTES;
            expected_status = expected_mem[case_number];
            sequence_number = packet_mem[base + 2];
            command_id = packet_mem[base + 3];
            payload = {packet_mem[base+8], packet_mem[base+7],
                       packet_mem[base+6], packet_mem[base+5]};

            old_rx_bytes = rx_response_bytes;
            old_rsp_pulses = response_pulses;
            old_cmd_pulses = command_pulses;
            old_mac_start_pulses = mac_start_pulses;
            old_mac_done_pulses = mac_done_pulses;
            old_clear_pulses = clear_pulses;
            old_uart_errors = response_uart_errors;
            old_failures = failures;
            prior_mode = active_mode;
            prior_color = active_color;
            prior_gain = gain_q88;
            prior_mac_result = mac_result_q88;

            for (j = 0; j < PACKET_BYTES; j = j + 1)
                send_uart_byte(packet_mem[base + j]);

            // Aguarda 8 bytes DE VERDADE na UART TX.
            wait_cycles = 0;
            while ((rx_response_bytes < old_rx_bytes + RESPONSE_BYTES) &&
                   (wait_cycles < WAIT_LIMIT)) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end
            if (rx_response_bytes < old_rx_bytes + RESPONSE_BYTES)
                $fatal(1, "TIMEOUT caso=%0d seq=%0d status_esperado=%0d bytes_recebidos=%0d",
                       case_number, sequence_number, expected_status,
                       rx_response_bytes - old_rx_bytes);

            repeat (4) @(negedge clk);

            if (rx_response_bytes != old_rx_bytes + RESPONSE_BYTES) begin
                $display("FAIL caso=%0d quantidade de bytes da resposta", case_number);
                failures = failures + 1;
            end
            if (response_pulses != old_rsp_pulses + 1) begin
                $display("FAIL caso=%0d quantidade de pulsos de resposta", case_number);
                failures = failures + 1;
            end
            if (command_pulses != old_cmd_pulses + (expected_status == 8'd0)) begin
                $display("FAIL caso=%0d cmd_valid inesperado", case_number);
                failures = failures + 1;
            end
            if (response_uart_errors != old_uart_errors) begin
                $display("FAIL caso=%0d framing_error na UART de resposta", case_number);
                failures = failures + 1;
            end

            if (reply[0] !== 8'h5A || reply[1] !== 8'h01 ||
                reply[2] !== sequence_number || reply[3] !== expected_status) begin
                $display("FAIL caso=%0d resposta: SOF=%h VER=%h SEQ=%h STATUS=%h; esperado seq=%h status=%h",
                        case_number, reply[0], reply[1], reply[2], reply[3],
                        sequence_number, expected_status);
                failures = failures + 1;
            end
            if (reply[4] !== {6'b0, prior_mode}) begin
                $display("FAIL caso=%0d modo devolvido=%h esperado=%h",
                         case_number, reply[4], {6'b0, prior_mode});
                failures = failures + 1;
            end

            if (expected_status != 0)
                expected_errors = expected_errors + 1;

            if ({reply[6], reply[5]} !== expected_errors[15:0] ||
                error_count !== expected_errors[15:0]) begin
                $display("FAIL caso=%0d error_count TX=%h DUT=%h esperado=%h",
                         case_number, {reply[6],reply[5]}, error_count,
                         expected_errors[15:0]);
                failures = failures + 1;
            end

            crc_check = 8'h00;
            for (j = 1; j <= 6; j = j + 1)
                crc_check = crc8_next(crc_check, reply[j]);
            if (reply[7] !== crc_check) begin
                $display("FAIL caso=%0d CRC da resposta: recebido=%h esperado=%h",
                         case_number, reply[7], crc_check);
                failures = failures + 1;
            end

            // Um pacote rejeitado não pode acionar o executor.
            if (expected_status != 0) begin
                if (active_mode !== prior_mode || active_color !== prior_color ||
                    gain_q88 !== prior_gain || mac_result_q88 !== prior_mac_result ||
                    mac_start_pulses != old_mac_start_pulses ||
                    clear_pulses != old_clear_pulses) begin
                    $display("FAIL caso=%0d rejeitado mas alterou estado do executor", case_number);
                    failures = failures + 1;
                end
            end else begin
                case (command_id)
                    8'h01: begin // SET_MODE
                        start_new_video_frame();
                        if (active_mode !== payload[1:0]) begin
                            $display("FAIL caso=%0d SET_MODE: %h != %h",
                                     case_number, active_mode, payload[1:0]);
                            failures = failures + 1;
                        end
                    end
                    8'h02: begin // SET_COLOR
                        start_new_video_frame();
                        if (active_color !== {payload[7:0],payload[15:8],payload[23:16]}) begin
                            $display("FAIL caso=%0d SET_COLOR: %h", case_number, active_color);
                            failures = failures + 1;
                        end
                    end
                    8'h03: begin // SET_GAIN
                        if (gain_q88 !== payload[15:0]) begin
                            $display("FAIL caso=%0d SET_GAIN: %h", case_number, gain_q88);
                            failures = failures + 1;
                        end
                    end
                    8'h04: begin // MAC_STEP
                        if (mac_start_pulses != old_mac_start_pulses + 1 ||
                            mac_done_pulses != old_mac_done_pulses + 1) begin
                            $display("FAIL caso=%0d MAC_STEP nao iniciou/terminou exatamente uma vez", case_number);
                            failures = failures + 1;
                        end
                    end
                    8'h05: begin // CLEAR
                        if (clear_pulses != old_clear_pulses + 1 ||
                            mac_result_q88 !== 16'sd0) begin
                            $display("FAIL caso=%0d CLEAR nao limpou o MAC", case_number);
                            failures = failures + 1;
                        end
                    end
                endcase
            end

            if (failures == old_failures)
                passed = passed + 1;
        end
    endtask

    initial begin
        $readmemh("crc_stress_packets.hex", packet_mem);
        $readmemh("crc_stress_expected.hex", expected_mem);

        if ($value$plusargs("cases=%d", cases_to_run)) begin
            if (cases_to_run < 1 || cases_to_run > PACKET_COUNT)
                $fatal(1, "cases deve estar entre 1 e %0d", PACKET_COUNT);
        end
        if ($test$plusargs("wave")) begin
            $dumpfile("build/tb_crc_stress.vcd");
            $dumpvars(0, tb_crc_stress);
        end

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (8) @(negedge clk);

        for (test_index = 0; test_index < cases_to_run; test_index = test_index + 1)
            run_case(test_index);

        if (tx_framing_error || response_uart_errors != 0)
            failures = failures + 1;

        $display("RESULTADO CRC_STRESS: casos=%0d PASS=%0d falhas=%0d respostas=%0d comandos_aceitos=%0d erros_detectados=%0d",
                 cases_to_run, passed, failures, response_pulses,
                 command_pulses, expected_errors);
        if (failures != 0 || passed != cases_to_run)
            $fatal(1, "FALHA nos testes CRC de 1 e 2 bits");
        $display("PASS tb_crc_stress");
        $finish;
    end
endmodule
