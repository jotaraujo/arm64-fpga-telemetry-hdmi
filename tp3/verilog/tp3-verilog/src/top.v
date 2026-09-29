module top (
    input  wire clk,
    input  wire usr_key_1,
    input  wire usr_key_2,
    output wire led_pin
);

    wire rst_n;
    por_reset u_por (.clk(clk), .rst_n(rst_n));

    wire key1_sync, key2_sync;
    wire key1_clean, key2_clean;
    wire key1_level;
    reg  [1:0] mode_reg;

    sync2ff #(.WIDTH(1)) s1 (.clk(clk), .rst_n(rst_n), .async_in(~usr_key_1), .sync_out(key1_sync));
    sync2ff #(.WIDTH(1)) s2 (.clk(clk), .rst_n(rst_n), .async_in(~usr_key_2), .sync_out(key2_sync));

    debounce db1 (.clk(clk), .rst_n(rst_n), .btn_in(key1_sync), .btn_clean(key1_clean), .btn_level(key1_level));
    debounce db2 (.clk(clk), .rst_n(rst_n), .btn_in(key2_sync), .btn_clean(key2_clean), .btn_level());

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mode_reg <= 2'b00;
        else if (key2_clean) mode_reg <= mode_reg + 2'b01;
    end

    wire busy, error_flag, error_latch;
    wire [1:0] led_result;

    fsm_control #(.STABLE_CYCLES(3)) u_fsm (
        .clk(clk), .rst_n(rst_n),
        .cmd_trigger_sync(key1_level),   // <-- agora e' NIVEL, nao pulso
        .cmd_data_sync(mode_reg),
        .busy(busy), .error_flag(error_flag), .error_latch(error_latch),
        .led_result(led_result)
    );

    blink_gen u_blink (
        .clk(clk), .rst_n(rst_n),
        .error_latch(error_latch), .led_result(led_result),
        .led_pin(led_pin)
    );

endmodule