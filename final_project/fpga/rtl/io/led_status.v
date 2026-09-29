`timescale 1ns / 1ps

module led_status #(
    parameter integer CLK_HZ        = 25_200_000,
    parameter integer COMMAND_MS    = 150,
    parameter integer PROTOCOL_MS   = 200,
    parameter integer FATAL_HALF_MS = 100
)(
    input  wire clk,
    input  wire rst_n,

    // Um comando valido foi recebido/executado.
    input  wire accepted_pulse,

    // Erro de protocolo ou comando invalido.
    input  wire protocol_error_pulse,

    // Erro grave. No projeto atual, corresponde ao overflow do MAC.
    input  wire fatal_error,

    // Limpa o erro grave armazenado.
    input  wire clear_pulse,

    // LED onboard da Tang Nano 4K.
    output reg led_pin
);

    /*
     * ============================================================
     * Tempos dos padroes
     * ============================================================
     *
     * Comando aceito:
     *     1 piscada de aproximadamente 150 ms
     *
     * Erro de protocolo:
     *     aceso 200 ms
     *     apagado 200 ms
     *     aceso 200 ms
     *
     * Erro grave:
     *     alterna a cada 100 ms continuamente ate CLEAR
     */

    localparam integer COMMAND_CYCLES =
        (CLK_HZ / 1000) * COMMAND_MS;

    localparam integer PROTOCOL_CYCLES =
        (CLK_HZ / 1000) * PROTOCOL_MS;

    localparam integer FATAL_HALF_CYCLES =
        (CLK_HZ / 1000) * FATAL_HALF_MS;


    /*
     * ============================================================
     * Estados da maquina de estados
     * ============================================================
     */

    localparam [2:0] S_IDLE       = 3'd0;
    localparam [2:0] S_COMMAND    = 3'd1;
    localparam [2:0] S_PROTO_ON_1 = 3'd2;
    localparam [2:0] S_PROTO_OFF  = 3'd3;
    localparam [2:0] S_PROTO_ON_2 = 3'd4;
    localparam [2:0] S_FATAL      = 3'd5;

    reg [2:0]  state;
    reg [31:0] timer;

    /*
     * fatal_latched guarda a informacao de erro grave.
     *
     * Mesmo que fatal_error dure somente um ciclo,
     * o LED continua piscando ate clear_pulse.
     */
    reg fatal_latched;


    /*
     * ============================================================
     * Logica principal
     * ============================================================
     */

    always @(posedge clk or negedge rst_n) begin

        /*
         * RESET
         */
        if (!rst_n) begin
            state         <= S_IDLE;
            timer         <= 32'd0;
            fatal_latched <= 1'b0;
            led_pin       <= 1'b0;
        end

        /*
         * CLEAR possui prioridade para apagar os estados de erro.
         */
        else if (clear_pulse) begin
            state         <= S_IDLE;
            timer         <= 32'd0;
            fatal_latched <= 1'b0;
            led_pin       <= 1'b0;
        end

        else begin

            /*
             * Se ocorrer erro grave, memorize-o.
             */
            if (fatal_error)
                fatal_latched <= 1'b1;


            /*
             * ====================================================
             * PRIORIDADE 1: ERRO GRAVE
             * ====================================================
             *
             * Piscada rapida continua:
             *
             * 100 ms ON
             * 100 ms OFF
             * 100 ms ON
             * ...
             *
             * So para quando chega CLEAR.
             */

            if (fatal_latched || fatal_error) begin

                state <= S_FATAL;

                if (timer >= FATAL_HALF_CYCLES - 1) begin
                    timer   <= 32'd0;
                    led_pin <= ~led_pin;
                end
                else begin
                    timer <= timer + 1'b1;
                end
            end


            /*
             * ====================================================
             * PRIORIDADE 2: ERRO DE PROTOCOLO
             * ====================================================
             */

            else if (protocol_error_pulse) begin
                state   <= S_PROTO_ON_1;
                timer   <= 32'd0;
                led_pin <= 1'b1;
            end


            /*
             * ====================================================
             * Estados normais
             * ====================================================
             */

            else begin

                case (state)

                    /*
                     * ------------------------------------------------
                     * Nenhum evento.
                     * LED apagado.
                     * ------------------------------------------------
                     */
                    S_IDLE: begin
                        timer   <= 32'd0;
                        led_pin <= 1'b0;

                        /*
                         * Um comando aceito inicia uma piscada curta.
                         */
                        if (accepted_pulse) begin
                            state   <= S_COMMAND;
                            timer   <= 32'd0;
                            led_pin <= 1'b1;
                        end
                    end


                    /*
                     * ------------------------------------------------
                     * Uma piscada curta para comando aceito.
                     * ------------------------------------------------
                     */
                    S_COMMAND: begin

                        if (timer >= COMMAND_CYCLES - 1) begin
                            state   <= S_IDLE;
                            timer   <= 32'd0;
                            led_pin <= 1'b0;
                        end
                        else begin
                            timer <= timer + 1'b1;
                        end
                    end


                    /*
                     * ------------------------------------------------
                     * Primeira piscada do erro de protocolo.
                     * ------------------------------------------------
                     */
                    S_PROTO_ON_1: begin

                        if (timer >= PROTOCOL_CYCLES - 1) begin
                            state   <= S_PROTO_OFF;
                            timer   <= 32'd0;
                            led_pin <= 1'b0;
                        end
                        else begin
                            timer <= timer + 1'b1;
                        end
                    end


                    /*
                     * ------------------------------------------------
                     * Intervalo apagado entre as duas piscadas.
                     * ------------------------------------------------
                     */
                    S_PROTO_OFF: begin

                        if (timer >= PROTOCOL_CYCLES - 1) begin
                            state   <= S_PROTO_ON_2;
                            timer   <= 32'd0;
                            led_pin <= 1'b1;
                        end
                        else begin
                            timer <= timer + 1'b1;
                        end
                    end


                    /*
                     * ------------------------------------------------
                     * Segunda piscada do erro de protocolo.
                     * ------------------------------------------------
                     */
                    S_PROTO_ON_2: begin

                        if (timer >= PROTOCOL_CYCLES - 1) begin
                            state   <= S_IDLE;
                            timer   <= 32'd0;
                            led_pin <= 1'b0;
                        end
                        else begin
                            timer <= timer + 1'b1;
                        end
                    end


                    /*
                     * ------------------------------------------------
                     * Normalmente não chegamos aqui pelo case,
                     * porque o erro grave é tratado antes.
                     *
                     * Este estado existe apenas para deixar a FSM
                     * completa e segura.
                     * ------------------------------------------------
                     */
                    S_FATAL: begin
                        state   <= S_IDLE;
                        timer   <= 32'd0;
                        led_pin <= 1'b0;
                    end


                    /*
                     * ------------------------------------------------
                     * Protecao contra estado desconhecido.
                     * ------------------------------------------------
                     */
                    default: begin
                        state   <= S_IDLE;
                        timer   <= 32'd0;
                        led_pin <= 1'b0;
                    end

                endcase
            end
        end
    end

endmodule