module telemetry_bram #(
  parameter ADDR_W = 10
)(
  input wire                clk,
  input wire                write_en,
  input wire [ADDR_W-1:0]   write_addr,
  input wire signed [15:0]  write_data,
  input wire [ADDR_W-1:0]   read_addr,
  output reg signed [15:0]  read_data
);
  (* syn_ramstyle = "block_ram", ram_style = "block" *)
  reg signed [15:0] memory [0:(1<<ADDR_W)-1];

  always @(posedge clk) begin
    if (write_en)
      memory[write_addr] <= write_data;
    read_data <= memory[read_addr];
  end
endmodule
