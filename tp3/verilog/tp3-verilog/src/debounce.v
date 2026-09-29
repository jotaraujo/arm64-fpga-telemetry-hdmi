module debounce (
    input  wire clk,
    input  wire rst_n,
    input  wire btn_in,       // ja sincronizado (2FF), ainda com bounce
    output reg  btn_clean,    // pulso de 1 ciclo no aperto valido (borda)
    output wire btn_level     // nivel estavel debounced (1 enquanto pressionado)
);
    reg [19:0] counter;
    reg        btn_stable, btn_stable_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter      <= 0;
            btn_stable   <= 0;
            btn_stable_d <= 0;
            btn_clean    <= 0;
        end else begin
            if (btn_in != btn_stable) begin
                counter <= counter + 1;
                if (counter == 20'd540_000) begin // ~20ms @ 27MHz
                    btn_stable <= btn_in;
                    counter    <= 0;
                end
            end else begin
                counter <= 0;
            end

            btn_stable_d <= btn_stable;
            btn_clean    <= btn_stable & ~btn_stable_d; // borda de subida limpa
        end
    end

    assign btn_level = btn_stable;
endmodule