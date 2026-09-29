module coeff_rom (
    input  wire        clk,
    input  wire [5:0]  addr,
    output reg  signed [15:0] dout
);
    (* ram_style = "block" *)
    reg signed [15:0] mem [0:63];

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 16'sd15000 + i * 100;
    end

    always @(posedge clk) dout <= mem[addr];
endmodule