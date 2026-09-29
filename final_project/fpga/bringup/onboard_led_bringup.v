module onboard_led_bringup (
    output wire led_pin
);

    /*
     * Bring-up isolado do LED onboard da Tang Nano 4K.
     *
     * Objetivo:
     *   - verificar se o bitstream foi realmente carregado;
     *   - verificar se o pino físico 10 está correto;
     *   - verificar se o LED onboard responde.
     *
     * Nesta placa já confirmamos experimentalmente:
     *
     *      led_pin = 1 -> LED aceso
     *      led_pin = 0 -> LED apagado
     *
     * Este módulo NÃO faz parte do top_final.
     */

    assign led_pin = 1'b1;

endmodule