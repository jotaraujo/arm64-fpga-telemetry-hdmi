module packet_parser (
  input wire clk,
  input wire rst_n,
  input wire byte_valid,
  input wire [7:0] byte_data,
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
  localparam STATUS_ACK = 8'd0;
  localparam STATUS_BAD_CRC = 8'd1;
  localparam STATUS_DUP_SEQ = 8'd2;
  localparam STATUS_BAD_CMD = 8'd3;
  localparam STATUS_BAD_LEN = 8'd4;

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
    integer bit_number;
    reg [7:0] work;
    begin
      work = old_crc ^ data;
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1)
        work = work[7] ? (work << 1) ^ 8'h07 : (work << 1);
      crc8_next = work;
    end
  endfunction

  function command_is_valid;
    input [7:0] value;
    begin
      command_is_valid =
        value == 8'h01 || value == 8'h02 || value == 8'h03 ||
        value == 8'h04 || value == 8'h05 || value == 8'h06 ||
        value == 8'h7f;
    end
  endfunction

  task reject_packet;
    input [7:0] status_value;
    begin
      response_valid <= 1'b1;
      response_seq <= seq_reg;
      response_status <= status_value;
      response_error_count <= error_count + 16'd1;
      error_count <= error_count + 16'd1;
      error_pulse <= 1'b1;
    end
  endtask

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
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
      if (byte_valid) begin
        if (!receiving) begin
          if (byte_data == 8'hA5) begin
            receiving <= 1'b1;
            index <= 4'd0;
            crc <= 8'd0;
            payload_reg <= 32'd0;
          end
        end else if (index < 4'd8) begin
        crc <= crc8_next(crc, byte_data);
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
    index <= index + 1'b1;

      end else begin
        receiving <= 1'b0;
        response_seq <= seq_reg;
        if (byte_data != crc) begin
          reject_packet(STATUS_BAD_CRC);
          end else if (version_reg != 8'h01 || !command_is_valid(cmd_reg)) begin
            reject_packet(STATUS_BAD_CMD);
          end else if (length_reg > 8'd4) begin
            reject_packet(STATUS_BAD_LEN);
          end else if (have_last_seq && seq_reg == last_seq) begin
            reject_packet(STATUS_DUP_SEQ);
          end else begin
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
    end
  end
endmodule