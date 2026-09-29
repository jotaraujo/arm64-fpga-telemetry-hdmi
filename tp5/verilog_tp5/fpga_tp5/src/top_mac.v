module top_mac (
    input  wire clk,
    input  wire usr_key_1,
    input  wire usr_key_2,
    output wire led_pin
);
    wire rst_n;
    por_reset u_por (.clk(clk), .rst_n(rst_n));

    wire key1_sync, key2_sync, key1_clean, key2_clean;
    sync2ff #(.WIDTH(1)) s1 (.clk(clk),.rst_n(rst_n),.async_in(~usr_key_1),.sync_out(key1_sync));
    sync2ff #(.WIDTH(1)) s2 (.clk(clk),.rst_n(rst_n),.async_in(~usr_key_2),.sync_out(key2_sync));
    debounce db1 (.clk(clk),.rst_n(rst_n),.btn_in(key1_sync),.btn_clean(key1_clean),.btn_level());
    debounce db2 (.clk(clk),.rst_n(rst_n),.btn_in(key2_sync),.btn_clean(key2_clean),.btn_level());

    wire [5:0] addr;
    wire mac_en, clear_acc;
    mac_control u_ctrl (
        .clk(clk),.rst_n(rst_n),
        .step_pulse(key1_clean),.reset_pulse(key2_clean),
        .addr(addr),.mac_en(mac_en),.clear_acc(clear_acc)
    );

    wire signed [15:0] coeff_dout, sample_dout;
    coeff_rom u_coeff (.clk(clk),.addr(addr),.dout(coeff_dout));
    sample_rom u_sample (.clk(clk),.addr(addr),.dout(sample_dout));

    wire signed [31:0] acc;
    wire overflow;
    wire signed [15:0] acc_q88;

    mac_unit #(.FRAC_BITS(8)) u_mac (
        .clk(clk),.rst_n(rst_n),.oe(rst_n),
        .a(coeff_dout),.b(sample_dout),
        .mac_en(mac_en),.clear_acc(clear_acc),
        .acc(acc),.overflow(overflow),.acc_q88(acc_q88)
    );

    reg [23:0] divider;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) divider <= 24'd0;
        else        divider <= divider + 24'd1;

    wire fast_tick = divider[19];
    reg [23:0] flash_cnt;
    reg flash_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin flash_cnt<=0; flash_active<=0; end
        else if (mac_en) begin flash_cnt<=0; flash_active<=1; end
        else if (flash_active) begin
            if (flash_cnt==24'd10_800_000) flash_active<=0;
            else flash_cnt<=flash_cnt+1;
        end
    end

    assign led_pin = overflow ? fast_tick : (flash_active ? 1'b1 : 1'b0);
endmodule