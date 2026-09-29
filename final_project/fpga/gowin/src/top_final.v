module top_final (
  input wire clk,
  input wire usr_key_1,
  input wire usr_key_2,
  output wire led_pin,
  output wire tmds_clk_n,
  output wire tmds_clk_p,
  output wire [2:0] tmds_d_n,
  output wire [2:0] tmds_d_p
  );
  wire clk_126;
  wire clk_pixel;
  wire pll_lock;
  wire rst_n;

  Gowin_PLLVR pll (
    .clkout(clk_126),
    .lock(pll_lock),
    .clkin(clk)
  );

  Gowin_CLKDIV divider (
    .clkout(clk_pixel),
    .hclkin(clk_126),
    .resetn(pll_lock)
  );

  reset_sync reset_release (
    .clk(clk_pixel),
    .async_ready(pll_lock),
    .rst_n(rst_n)
  );

  wire key1_sync;
  wire key2_sync;
  wire key1_level;
  wire key2_level;
  wire key1_pulse;
  wire key2_pulse;

  sync2ff key1_synchronizer (
    .clk(clk_pixel), .rst_n(rst_n), .async_in(~usr_key_1), .sync_out(key1_sync)
  );

  sync2ff key2_synchronizer (
    .clk(clk_pixel), .rst_n(rst_n), .async_in(~usr_key_2), .sync_out(key2_sync)
  );

  debounce_pulse key1_debounce (
    .clk(clk_pixel), .rst_n(rst_n), .button_in(key1_sync),
    .button_level(key1_level), .pressed_pulse(key1_pulse)
  );

  debounce_pulse key2_debounce (
    .clk(clk_pixel), .rst_n(rst_n), .button_in(key2_sync),
    .button_level(key2_level), .pressed_pulse(key2_pulse)
  );

  wire local_cmd_valid;
  wire local_cmd_ready;
  wire [7:0] local_cmd_id;
  wire [31:0] local_cmd_payload;

  button_commands local_commands (
    .clk(clk_pixel), .rst_n(rst_n),
    .key1_level(key1_level), .key2_level(key2_level),
    .key1_pulse(key1_pulse), .key2_pulse(key2_pulse),
    .cmd_ready(local_cmd_ready), .cmd_valid(local_cmd_valid),
    .cmd_id(local_cmd_id), .cmd_payload(local_cmd_payload)
  );

  wire frame_start;
  wire accepted_pulse;
  wire command_error_pulse;
  wire clear_pulse;
  wire mac_start;
  wire signed [15:0] mac_operand_a;
  wire signed [15:0] mac_operand_b;
  wire [1:0] active_mode;
  wire [23:0] active_color;
  wire signed [15:0] gain_q88;

  command_executor executor (
    .clk(clk_pixel), .rst_n(rst_n), .frame_start(frame_start),
    .cmd_valid(local_cmd_valid), .cmd_ready(local_cmd_ready),
    .cmd_id(local_cmd_id), .cmd_payload(local_cmd_payload),
    .accepted_pulse(accepted_pulse), .command_error_pulse(command_error_pulse),
    .clear_pulse(clear_pulse), .mac_start(mac_start),
    .mac_operand_a(mac_operand_a), .mac_operand_b(mac_operand_b),
    .active_mode(active_mode), .active_color(active_color), .gain_q88(gain_q88)
  );

  wire mac_done;
  wire signed [31:0] accumulator_q1616;
  wire signed [15:0] mac_result_q88;
  wire mac_overflow;

  mac_unit mac (
    .clk(clk_pixel), .rst_n(rst_n), .start(mac_start), .clear(clear_pulse),
    .operand_a_q88(mac_operand_a), .operand_b_q88(mac_operand_b),
    .done(mac_done), .accumulator_q1616(accumulator_q1616),
    .result_q88(mac_result_q88), .overflow(mac_overflow)
  );

  reg [9:0] telemetry_write_addr;
  reg [9:0] telemetry_count;
  wire [9:0] telemetry_read_addr;
  wire signed [15:0] telemetry_read_data;

  always @(posedge clk_pixel or negedge rst_n) begin
    if (!rst_n || clear_pulse) begin
      telemetry_write_addr <= 10'd0;
      telemetry_count <= 10'd0;
    end else if (mac_done) begin
      telemetry_write_addr <= telemetry_write_addr + 1'b1;
      if (telemetry_count != 10'h3ff)
        telemetry_count <= telemetry_count + 1'b1;
    end
  end

  telemetry_bram telemetry (
    .clk(clk_pixel), .write_en(mac_done),
    .write_addr(telemetry_write_addr), .write_data(mac_result_q88),
    .read_addr(telemetry_read_addr), .read_data(telemetry_read_data)
  );

  // O LED onboard agora e o unico indicador luminoso do sistema.
  // 1 piscada curta = comando aceito.
  // 2 piscadas = erro de comando/protocolo.
  // Piscada rapida continua = erro grave (MAC overflow) ate CLEAR.
  led_status status_indicator (
    .clk(clk_pixel),
    .rst_n(rst_n),
    .accepted_pulse(accepted_pulse),
    .protocol_error_pulse(command_error_pulse),
    .fatal_error(mac_overflow),
    .clear_pulse(clear_pulse),
    .led_pin(led_pin)
  );

  // O active_mode e exibido pelo HDMI: cada modo possui um padrao proprio
  // e dois quadrados no canto superior direito mostram mode[1:0].
  svo_hdmi_final video (
    .clk(clk_pixel), .resetn(rst_n),
    .clk_pixel(clk_pixel), .clk_5x_pixel(clk_126), .locked(pll_lock),
    .mode(active_mode), .base_color(active_color),
    .telemetry_sample(telemetry_read_data), .telemetry_count(telemetry_count),
    .telemetry_addr(telemetry_read_addr), .frame_start(frame_start),
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p),
    .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
  );
endmodule