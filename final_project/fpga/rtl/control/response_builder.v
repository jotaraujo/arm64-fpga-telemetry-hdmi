module response_builder (
  input wire clk,
  input wire rst_n,
  input wire response_valid,
  input wire [7:0] response_seq,
  input wire [7:0] response_status,
  input wire [1:0] active_mode,
  input wire [15:0] error_count,
  output wire tx_data_valid,
  input wire tx_data_ready,
  output wire [7:0] tx_data,
  output reg dropped_response
);
  reg [7:0] packet [0:7];
  reg [2:0] index;
  reg sending;

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

  function [7:0] response_crc;
    input [7:0] sequence_value;
    input [7:0] status_value;
    input [7:0] mode_value;
    input [15:0] errors_value;
    reg [7:0] work;
    begin
      work = crc8_next(8'd0, 8'h01);
      work = crc8_next(work, sequence_value);

      work = crc8_next(work, status_value);
      work = crc8_next(work, mode_value);
      work = crc8_next(work, errors_value[7:0]);
      work = crc8_next(work, errors_value[15:8]);
      response_crc = work;
    end
  endfunction

  assign tx_data_valid = sending;
  assign tx_data = packet[index];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      index <= 3'd0;
      sending <= 1'b0;
      dropped_response <= 1'b0;
    end else begin
      dropped_response <= 1'b0;
      if (response_valid) begin
        if (!sending) begin
        packet[0] <= 8'h5A;
        packet[1] <= 8'h01;
        packet[2] <= response_seq;
        packet[3] <= response_status;
        packet[4] <= {6'd0, active_mode};
        packet[5] <= error_count[7:0];
        packet[6] <= error_count[15:8];
        packet[7] <= response_crc(
        response_seq, response_status, {6'd0, active_mode}, error_count
        );
        index <= 3'd0;
        sending <= 1'b1;
        end else begin
          dropped_response <= 1'b1;
        end
      end
      if (sending && tx_data_ready) begin
        if (index == 3'd7)
        sending <= 1'b0;
      else
        index <= index + 1'b1;
      end
    end
  end
endmodule