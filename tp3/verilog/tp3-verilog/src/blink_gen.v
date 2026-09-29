module blink_gen (
    input  wire       clk,        // 27 MHz onboard
    input  wire       rst_n,
    input  wire       error_latch,
    input  wire [1:0] led_result,
    output reg        led_pin
);
    reg [23:0] divider;
    wire slow_tick = divider[23]; // ~1.6 Hz  -> STATUS
    wire fast_tick = divider[19]; // ~25 Hz   -> ERROR

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) divider <= 24'd0;
        else        divider <= divider + 24'd1;
    end

    always @(*) begin
        if (error_latch) begin
            led_pin = fast_tick;
        end else begin
            case (led_result)
                2'b00:   led_pin = 1'b0;
                2'b01:   led_pin = 1'b1;
                2'b10:   led_pin = slow_tick;
                default: led_pin = 1'b0;
            endcase
        end
    end
endmodule