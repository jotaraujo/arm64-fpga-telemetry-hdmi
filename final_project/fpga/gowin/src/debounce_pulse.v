module debounce_pulse #(
    parameter integer CLK_HZ      = 25_200_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input wire clk,
    input wire rst_n,

    input wire button_in,

    output reg button_level,
    output reg pressed_pulse
);

    /*
     * Quantidade de ciclos durante a qual o novo nivel
     * precisa permanecer estavel.
     *
     * 25,2 MHz e 20 ms:
     *
     * 25.200.000 / 1000 * 20
     * = 504.000 ciclos
     */
    localparam integer LIMIT =
        (CLK_HZ / 1000) * DEBOUNCE_MS;

    localparam integer COUNT_W =
        $clog2(LIMIT + 1);

    reg [COUNT_W-1:0] count;


    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            button_level <= 1'b0;
            pressed_pulse <= 1'b0;
            count <= {COUNT_W{1'b0}};

        end else begin

            /*
             * pressed_pulse dura apenas um ciclo.
             */
            pressed_pulse <= 1'b0;


            /*
             * Se a entrada voltou a coincidir com o estado
             * ja aceito, nao existe mudanca para validar.
             */
            if (button_in == button_level) begin

                count <= {COUNT_W{1'b0}};

            end

            /*
             * O novo nivel permaneceu estavel durante
             * todo o periodo de debounce.
             */
            else if (count == LIMIT - 1) begin

                count <= {COUNT_W{1'b0}};
                button_level <= button_in;

                /*
                 * Gera pulso somente na transicao para pressionado.
                 */
                if (button_in)
                    pressed_pulse <= 1'b1;

            end

            else begin

                count <= count + 1'b1;

            end
        end
    end

endmodule