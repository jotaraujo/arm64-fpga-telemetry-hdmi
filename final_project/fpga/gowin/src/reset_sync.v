module reset_sync (
  input wire clk,
  input wire async_ready,
  output wire rst_n
);
  reg [3:0] sync = 4'b0000;
  
  always @(posedge clk or negedge async_ready) begin
    if (!async_ready)
      sync <= 4'b0000;
    else
      sync <= {sync[2:0], 1'b1};
  end

  assign rst_n = sync[3];
endmodule
