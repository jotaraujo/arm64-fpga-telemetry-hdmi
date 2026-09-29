module mac_control (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       step_pulse,
    input  wire       reset_pulse,
    output reg  [5:0] addr,
    output reg        mac_en,
    output reg        clear_acc
);
    localparam S_IDLE = 2'b00;
    localparam S_LOAD = 2'b01;
    localparam S_MAC  = 2'b10;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            addr      <= 6'd0;
            mac_en    <= 1'b0;
            clear_acc <= 1'b0;
        end else begin
            mac_en    <= 1'b0;
            clear_acc <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (reset_pulse) begin
                        addr      <= 6'd0;
                        clear_acc <= 1'b1;
                    end else if (step_pulse) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: state <= S_MAC;

                S_MAC: begin
                    mac_en <= 1'b1;
                    addr   <= addr + 6'd1;
                    state  <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule