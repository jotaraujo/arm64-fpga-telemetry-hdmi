module command_executor (
  input wire                          clk,
  input wire                          rst_n,
  input wire                          frame_start,
  input wire                          cmd_valid,
  output wire                         cmd_ready,
  input wire [7:0]                    cmd_id,
  input wire [31:0]                   cmd_payload,
  output reg                          accepted_pulse,
  output reg                          command_error_pulse,
  output reg                          clear_pulse,
  output reg                          mac_start,
  output reg signed [15:0]            mac_operand_a,

  output reg signed [15:0]            mac_operand_b,
  output reg [1:0]                    active_mode,
  output reg [23:0]                   active_color,
  output reg signed [15:0]            gain_q88
);
  localparam CMD_SET_MODE     =       8'h01;
  localparam CMD_SET_COLOR    =       8'h02;
  localparam CMD_SET_GAIN     =       8'h03;
  localparam CMD_MAC_STEP     =       8'h04;
  localparam CMD_CLEAR        =       8'h05;
  localparam CMD_GET_STATUS   =       8'h06;
  localparam CMD_PING         =       8'h7f;

  reg [1:0]                            pending_mode;
  reg [23:0]                           pending_color;

  assign cmd_ready            =        1'b1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_mode <= 2'd0;
      active_mode <= 2'd0;
      pending_color <= 24'h204080;
      active_color <= 24'h204080;
      gain_q88 <= 16'sd256;
      accepted_pulse <= 1'b0;
      command_error_pulse <= 1'b0;
      clear_pulse <= 1'b0;
      mac_start <= 1'b0;
      mac_operand_a <= 16'sd0;
      mac_operand_b <= 16'sd0;
    end else begin
      accepted_pulse <= 1'b0;
      command_error_pulse <= 1'b0;
      clear_pulse <= 1'b0;
      mac_start <= 1'b0;
      if (frame_start) begin
        active_mode <= pending_mode;
        active_color <= pending_color;
      end
      if (cmd_valid && cmd_ready) begin
        case (cmd_id)
          CMD_SET_MODE: begin
            if (cmd_payload[7:0] <= 8'd3) begin
              pending_mode <= cmd_payload[1:0];
              accepted_pulse <= 1'b1;
            end else begin
              command_error_pulse <= 1'b1;
            end
          end

          CMD_SET_COLOR: begin
            pending_color <= {
              cmd_payload[7:0],
              cmd_payload[15:8],
              cmd_payload[23:16]
            };
            accepted_pulse <= 1'b1;
          end

          CMD_SET_GAIN: begin
            gain_q88 <= cmd_payload[15:0];
            accepted_pulse <= 1'b1;
          end

          CMD_MAC_STEP: begin
            mac_operand_a <= cmd_payload[15:0];
            mac_operand_b <= cmd_payload[31:16];
            mac_start <= 1'b1;
            accepted_pulse <= 1'b1;
          end

          CMD_CLEAR: begin
            clear_pulse <= 1'b1;
            accepted_pulse <= 1'b1;
          end

          CMD_GET_STATUS, CMD_PING: begin
            accepted_pulse <= 1'b1;
          end

          default: begin
            command_error_pulse <= 1'b1;
          end
        endcase
      end
    end
  end
endmodule