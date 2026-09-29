/*
* Adaptacao do Simple Video Out usado no exemplo oficial da Sipeed.
* O aviso de licenca dos arquivos SVO originais deve permanecer no projeto.
*/
`timescale 1ns / 1ps
`include "hdmi/svo_defines.vh"

module svo_hdmi_final (
  input wire clk,
  input wire resetn,
  input wire clk_pixel,
  input wire clk_5x_pixel,
  input wire locked,
  input wire [1:0] mode,
  input wire [23:0] base_color,
  input wire signed [15:0] telemetry_sample,
  input wire [9:0] telemetry_count,
  output wire [9:0] telemetry_addr,
  output wire frame_start,
  output wire tmds_clk_n,
  output wire tmds_clk_p,
  output wire [2:0] tmds_d_n,
  output wire [2:0] tmds_d_p
);
  parameter SVO_MODE = "640x480V";

  parameter SVO_FRAMERATE = 60;
  parameter SVO_BITS_PER_PIXEL = 24;
  parameter SVO_BITS_PER_RED = 8;
  parameter SVO_BITS_PER_GREEN = 8;
  parameter SVO_BITS_PER_BLUE = 8;
  parameter SVO_BITS_PER_ALPHA = 0;

  wire source_tvalid;
  wire source_tready;
  wire [SVO_BITS_PER_PIXEL-1:0] source_tdata;
  wire [0:0] source_tuser;
  wire video_enc_tvalid;
  wire video_enc_tready;
  wire [SVO_BITS_PER_PIXEL-1:0] video_enc_tdata;
  wire [3:0] video_enc_tuser;
  wire [2:0] tmds_d;
  wire [2:0] tmds_d0, tmds_d1, tmds_d2, tmds_d3, tmds_d4;
  wire [2:0] tmds_d5, tmds_d6, tmds_d7, tmds_d8, tmds_d9;
  reg [3:0] resetn_clk_pixel_q;

  always @(posedge clk_pixel) begin
    if (!resetn)
    resetn_clk_pixel_q <= 4'b0000;
    else
    resetn_clk_pixel_q <= {resetn_clk_pixel_q[2:0], 1'b1};
  end
  wire clk_pixel_resetn = locked && resetn_clk_pixel_q[3];

  pattern_stream pattern_source (
    .clk(clk_pixel),
    .rst_n(clk_pixel_resetn),
    .mode(mode),
    .base_color(base_color),
    .telemetry_sample(telemetry_sample),
    .telemetry_count(telemetry_count),
    .telemetry_addr(telemetry_addr),
    .frame_start(frame_start),
    .out_axis_tvalid(source_tvalid),
    .out_axis_tready(source_tready),
    .out_axis_tdata(source_tdata),
    .out_axis_tuser(source_tuser)
  );

  svo_enc #( `SVO_PASS_PARAMS ) encoder (
    .clk(clk_pixel),
    .resetn(clk_pixel_resetn),
    .in_axis_tvalid(source_tvalid),
    .in_axis_tready(source_tready),
    .in_axis_tdata(source_tdata),
    .in_axis_tuser(source_tuser),
    .out_axis_tvalid(video_enc_tvalid),
    .out_axis_tready(video_enc_tready),
    .out_axis_tdata(video_enc_tdata),
    .out_axis_tuser(video_enc_tuser)
  );
  assign video_enc_tready = 1'b1;

  svo_tmds tmds_channel_0 (
    .clk(clk_pixel), .resetn(clk_pixel_resetn),
    .de(!video_enc_tuser[3]), .ctrl(video_enc_tuser[2:1]),
    .din(video_enc_tdata[23:16]),
    .dout({tmds_d9[0],tmds_d8[0],tmds_d7[0],tmds_d6[0],tmds_d5[0],
    tmds_d4[0],tmds_d3[0],tmds_d2[0],tmds_d1[0],tmds_d0[0]})
  );

  svo_tmds tmds_channel_1 (
    .clk(clk_pixel), .resetn(clk_pixel_resetn),
    .de(!video_enc_tuser[3]), .ctrl(2'b00),
    .din(video_enc_tdata[15:8]),
    .dout({tmds_d9[1],tmds_d8[1],tmds_d7[1],tmds_d6[1],tmds_d5[1],
    tmds_d4[1],tmds_d3[1],tmds_d2[1],tmds_d1[1],tmds_d0[1]})
  );

  svo_tmds tmds_channel_2 (
    .clk(clk_pixel), .resetn(clk_pixel_resetn),
    .de(!video_enc_tuser[3]), .ctrl(2'b00),
    .din(video_enc_tdata[7:0]),
    .dout({tmds_d9[2],tmds_d8[2],tmds_d7[2],tmds_d6[2],tmds_d5[2],
    tmds_d4[2],tmds_d3[2],tmds_d2[2],tmds_d1[2],tmds_d0[2]})
  );

  OSER10 serializers [2:0] (
    .Q(tmds_d), .D0(tmds_d0), .D1(tmds_d1), .D2(tmds_d2),
    .D3(tmds_d3), .D4(tmds_d4), .D5(tmds_d5), .D6(tmds_d6),
    .D7(tmds_d7), .D8(tmds_d8), .D9(tmds_d9),
    .PCLK(clk_pixel), .FCLK(clk_5x_pixel), .RESET(~clk_pixel_resetn)
  );

  ELVDS_OBUF differential_outputs [3:0] (
    .I({clk_pixel, tmds_d}),
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
  );
endmodule