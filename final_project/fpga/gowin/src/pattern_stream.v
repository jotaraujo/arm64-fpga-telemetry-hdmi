module pattern_stream #(
  parameter H_VISIBLE = 640,
  parameter V_VISIBLE = 480
)(
  input wire clk,
  input wire rst_n,
  input wire [1:0] mode,
  input wire [23:0] base_color,
  input wire signed [15:0] telemetry_sample,
  input wire [9:0] telemetry_count,
  output wire [9:0] telemetry_addr,
  output wire frame_start,
  output wire out_axis_tvalid,
  input wire out_axis_tready,
  output reg [23:0] out_axis_tdata,
  output wire [0:0] out_axis_tuser
  );
  reg [9:0] x;
  reg [8:0] y;
  reg [7:0] red;
  reg [7:0] green;
  reg [7:0] blue;
  reg signed [17:0] graph_y;

  assign out_axis_tvalid = rst_n;
  assign out_axis_tuser[0] = (x == 0) && (y == 0);
  assign frame_start = out_axis_tvalid && out_axis_tready && (x == 0) && (y == 0);
  assign telemetry_addr = x;

  always @(*) begin
    red = 8'd0;
    green = 8'd0;
    blue = 8'd0;
    graph_y = 18'sd240 - (telemetry_sample >>> 2);

    // O active_mode escolhe o conteudo principal do HDMI.
    case (mode)
      2'd0: begin
        if (x < 10'd80) begin red=8'hff; green=8'hff; blue=8'hff; end
        else if (x < 10'd160) begin red=8'hff; green=8'hff; blue=8'h00; end
        else if (x < 10'd240) begin red=8'h00; green=8'hff; blue=8'hff; end
        else if (x < 10'd320) begin red=8'h00; green=8'hff; blue=8'h00; end
        else if (x < 10'd400) begin red=8'hff; green=8'h00; blue=8'hff; end
        else if (x < 10'd480) begin red=8'hff; green=8'h00; blue=8'h00; end
        else if (x < 10'd560) begin red=8'h00; green=8'h00; blue=8'hff; end
        else begin red=8'h10; green=8'h10; blue=8'h10; end
      end

      2'd1: begin
        if (x[5] ^ y[5]) begin
          red = base_color[23:16];
          green = base_color[15:8];
          blue = base_color[7:0];
        end else begin
          red = ~base_color[23:16];
          green = ~base_color[15:8];
          blue = ~base_color[7:0];
        end
      end

      2'd2: begin
        red = x[7:0];
        green = y[7:0];
        blue = x[7:0] + y[7:0];
      end

      default: begin
        red = 8'h08;
        green = 8'h10;
        blue = 8'h18;

        if (y == 9'd240 || x == 10'd0) begin
          red = 8'h50;
          green = 8'h50;
          blue = 8'h50;
        end

        if (x < telemetry_count && graph_y >= 18'sd2 && graph_y <= 18'sd477 &&
          y >= graph_y - 18'sd2 && y <= graph_y + 18'sd2) begin
          red = 8'h20;
          green = 8'hff;
          blue = 8'h40;
        end
      end
    endcase

    // Indicador binario do active_mode no canto superior direito.
    // Quadrado esquerdo = mode[1], quadrado direito = mode[0].
    // Branco significa bit 1; cinza escuro significa bit 0.
    if (y < 9'd32 && x >= 10'd560 && x < 10'd592) begin
      if (mode[1]) begin
        red = 8'hff; green = 8'hff; blue = 8'hff;
      end else begin
        red = 8'h20; green = 8'h20; blue = 8'h20;
      end
    end

    if (y < 9'd32 && x >= 10'd600 && x < 10'd632) begin
      if (mode[0]) begin
        red = 8'hff; green = 8'hff; blue = 8'hff;
      end else begin
        red = 8'h20; green = 8'h20; blue = 8'h20;
      end
    end

    // SVO espera a ordem blue, green, red.
    out_axis_tdata = {blue, green, red};
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x <= 10'd0;
      y <= 9'd0;
    end else if (out_axis_tvalid && out_axis_tready) begin
      if (x == H_VISIBLE - 1) begin
        x <= 10'd0;
        if (y == V_VISIBLE - 1)
        y <= 9'd0;
        else
        y <= y + 1'b1;
      end else begin
        x <= x + 1'b1;
      end
    end
  end
endmodule
