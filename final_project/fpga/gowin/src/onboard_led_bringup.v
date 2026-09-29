module onboard_led_bringup (
 output wire led_pin
);
 // Nivel logico 1 acende o LED onboard.
 assign led_pin = 1'b0;
endmodule