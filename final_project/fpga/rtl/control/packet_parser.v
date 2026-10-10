// packet_parser.v - versao com recuperacao de erro UART e timeout.
// Baseada na interface documentada do projeto ARM64 + FPGA.
// ATENCAO: o protocol_system.v precisa conectar framing_error e definir
// PACKET_TIMEOUT_CYCLES usando CLKS_PER_BIT (ver instrucoes).
// Timeout e framing error sao descartes sem resposta UART: nao existe
// um pacote completo com sequencia/CRC confiaveis para responder.
// CRC/comando/length/duplicacao mantem o comportamento original.
module packet_parser #(
    parameter integer PACKET_TIMEOUT_CYCLES = 8760
)(
    input wire clk,
    input wire rst_n,
    input wire byte_valid,
    input wire [7:0] byte_data,
    input wire framing_error, // conecta uart_rx.framing_error
    output reg cmd_valid,
    output reg [7:0] cmd_seq,
    output reg [7:0] cmd_id,
    output reg [7:0] cmd_length,
    output reg [31:0] cmd_payload,
    output reg response_valid,
    output reg [7:0] response_seq,
    output reg [7:0] response_status,
    output reg [15:0] response_error_count,
    output reg error_pulse,
    output reg [15:0] error_count
);
    localparam STATUS_ACK      = 8'd0;
    localparam STATUS_BAD_CRC  = 8'd1;
    localparam STATUS_DUP_SEQ  = 8'd2;
    localparam STATUS_BAD_CMD  = 8'd3;
    localparam STATUS_BAD_LEN  = 8'd4;

    // Defina PACKET_TIMEOUT_CYCLES >= 1.
    localparam integer TIMER_W =
        (PACKET_TIMEOUT_CYCLES <= 1) ? 1 : $clog2(PACKET_TIMEOUT_CYCLES+1);
    reg [TIMER_W-1:0] idle_count;
    reg receiving;
    reg [3:0] index;
    reg [7:0] crc;
    reg [7:0] version_reg;
    reg [7:0] seq_reg;
    reg [7:0] cmd_reg;
    reg [7:0] length_reg;
    reg [31:0] payload_reg;
    reg have_last_seq;
    reg [7:0] last_seq;

    function [7:0] crc8_next;
        input [7:0] old_crc;
        input [7:0] data;
        reg [7:0] work;
        integer bit_number;
        begin
            work=old_crc^data;
            for (bit_number=0;bit_number<8;bit_number=bit_number+1)
                work=work[7]?((work<<1)^8'h07):(work<<1);
            crc8_next=work;
        end
    endfunction

    function command_is_valid;
        input [7:0] value;
        begin
            command_is_valid =
                value==8'h01 || value==8'h02 || value==8'h03 ||
                value==8'h04 || value==8'h05 || value==8'h06 ||
                value==8'h7f;
        end
    endfunction

    task reject_packet;
        input [7:0] status_value;
        begin
            response_valid <= 1'b1;
            response_seq <= seq_reg;
            response_status <= status_value;
            response_error_count <= error_count+16'd1;
            error_count <= error_count+16'd1;
            error_pulse <= 1'b1;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idle_count <= {TIMER_W{1'b0}};
            receiving <= 1'b0;
            index <= 4'd0;
            crc <= 8'd0;
            version_reg <= 8'd0;
            seq_reg <= 8'd0;
            cmd_reg <= 8'd0;
            length_reg <= 8'd0;
            payload_reg <= 32'd0;
            have_last_seq <= 1'b0;
            last_seq <= 8'd0;
            cmd_valid <= 1'b0;
            cmd_seq <= 8'd0;
            cmd_id <= 8'd0;
            cmd_length <= 8'd0;
            cmd_payload <= 32'd0;
            response_valid <= 1'b0;
            response_seq <= 8'd0;
            response_status <= 8'd0;
            response_error_count <= 16'd0;
            error_pulse <= 1'b0;
            error_count <= 16'd0;
        end else begin
            cmd_valid <= 1'b0;
            response_valid <= 1'b0;
            error_pulse <= 1'b0;

            // 1) Stop bit ruim: descartar pacote parcial imediatamente.
            // Sem comando confiavel/CRC, nao fabricar ACK ou NACK.
            if (framing_error) begin
                receiving <= 1'b0;
                index <= 4'd0;
                crc <= 8'd0;
                payload_reg <= 32'd0;
                idle_count <= {TIMER_W{1'b0}};
                error_count <= error_count+16'd1;
                error_pulse <= 1'b1;
            end
            // 2) Mensagem comecou, mas bytes seguintes nao chegaram a tempo.
            else if (receiving && !byte_valid &&
                     idle_count >= PACKET_TIMEOUT_CYCLES - 1) begin
                receiving <= 1'b0;
                index <= 4'd0;
                crc <= 8'd0;
                payload_reg <= 32'd0;
                idle_count <= {TIMER_W{1'b0}};
                error_count <= error_count+16'd1;
                error_pulse <= 1'b1;
            end
            else if (byte_valid) begin
                idle_count <= {TIMER_W{1'b0}};
                if (!receiving) begin
                    if (byte_data == 8'hA5) begin
                        receiving <= 1'b1;
                        index <= 4'd0;
                        crc <= 8'd0;
                        payload_reg <= 32'd0;
                    end
                end else if (index < 4'd8) begin
                    crc <= crc8_next(crc,byte_data);
                    case (index)
                        4'd0: version_reg <= byte_data;
                        4'd1: seq_reg <= byte_data;
                        4'd2: cmd_reg <= byte_data;
                        4'd3: length_reg <= byte_data;
                        4'd4: payload_reg[7:0] <= byte_data;
                        4'd5: payload_reg[15:8] <= byte_data;
                        4'd6: payload_reg[23:16] <= byte_data;
                        4'd7: payload_reg[31:24] <= byte_data;
                        default: ;
                    endcase
                    index <= index+1'b1;
                end else begin
                    receiving <= 1'b0;
                    response_seq <= seq_reg;
                    if (byte_data != crc)
                        reject_packet(STATUS_BAD_CRC);
                    else if (version_reg != 8'h01 || !command_is_valid(cmd_reg))
                        reject_packet(STATUS_BAD_CMD);
                    else if (length_reg > 8'd4)
                        reject_packet(STATUS_BAD_LEN);
                    else if (have_last_seq && seq_reg == last_seq)
                        reject_packet(STATUS_DUP_SEQ);
                    else begin
                        cmd_valid <= 1'b1;
                        cmd_seq <= seq_reg;
                        cmd_id <= cmd_reg;
                        cmd_length <= length_reg;
                        cmd_payload <= payload_reg;
                        response_valid <= 1'b1;
                        response_status <= STATUS_ACK;
                        response_error_count <= error_count;
                        last_seq <= seq_reg;
                        have_last_seq <= 1'b1;
                    end
                end
            end
            else if (receiving)
                idle_count <= idle_count + 1'b1;
            else
                idle_count <= {TIMER_W{1'b0}};
        end
    end
endmodule
