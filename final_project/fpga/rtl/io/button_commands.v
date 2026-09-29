module button_commands (
  input wire        clk,
  input wire        rst_n,
  input wire        key1_level,
  input wire        key2_level,
  input wire        key1_pulse,
  input wire        key2_pulse,
  input wire        cmd_ready,
  output reg        cmd_valid,
  output reg [7:0]  cmd_id,
  output reg [31:0] cmd_payload
);

  localparam CMD_SET_MODE = 8'h01;
  localparam CMD_MAC_STEP = 8'h04;
  localparam CMD_CLEAR    = 8'h05;

  reg [1:0] next_mode;
  reg [2:0] sample_index;
  reg       both_latched;

  function signed [15:0] sample_value;
    input [1:0] index;
    begin
      case (index)
        3'd0: sample_value = 16'sd256; 
        3'd1: sample_value = 16'sd128; 
        3'd2: sample_value = -16'sd192; 
        3'd3: sample_value = 16'sd384; 
        3'd4: sample_value = -16'sd256; 
        3'd5: sample_value = 16'sd64; 
        3'd6: sample_value = 16'sd512; 
        default: sample_value = -16'sd128;
      endcase
    end
  endfunction

  function signed [15:0] coeff_value;
    input [2:0] index;
    begin
      case (index)
        3'd0: coeff_value = 16'sd128; 
        3'd1: coeff_value = 16'sd256; 
        3'd2: coeff_value = -16'sd64; 
        3'd3: coeff_value = 16'sd192; 
        3'd4: coeff_value = 16'sd320; 
        3'd5: coeff_value = -16'sd256; 
        3'd6: coeff_value = 16'sd64; 
        default: coeff_value = 16'sd384;
      endcase
    end
  endfunction
  
  always @(posedge clj or negedge rst_n) begin
    if (!rst_n) begin
      next_mode <= 2'd0;
      sample_index <= 3'd0;
      both_latched <= 1'b0;
      cmd_valid <= 1'b0;
      cmd_id <= 8'd0;
      cmd_payload <= 32'd0;
    end else begin
      if (cmd_valid && cmd_ready)
        cmd_valid <= 1'b0;
      
      if (!(key1_level && key2_level))
        both_latched <= 1'b0;
      
      if (!cmd_valid) begin
        if (key1_level && key2_level && !both_latched) begin
          cmd_valid <= 1'b1;
          cmd_id <= CMD_CLEAR;
          cmd_payload <= 32'd0;
          sample_index <= 3'd0;
          both_latched <= 1'b1;
        end else if (key1_pulse && !key2_level) begin
          cmd_valid <= 1'b1;
          cmd_id <= CMD_SET_MODE;
          cmd_payload <= {30'd0, next_mode +  2'd1};
          next_mode <= next_mode + 2'd1;
        end else if (key2_pulse && !key1_level) begin
          cmd_valid <= 1'b1;
          cmd_id <= CMD_MAC_STEP;
          cmd_payload <= {coeff_value(sample_index), sample_value(sample_index)};
          sample_index <= sample_index + 3'd1;
        end
      end
    end
  end
endmodule