module fsm_control #(
    parameter STABLE_CYCLES = 3
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cmd_trigger_sync,
    input  wire [1:0] cmd_data_sync,
    output wire       busy,
    output wire       error_flag,   // pulso combinacional, so em S_ERROR
    output wire       error_latch,  // persistente, para exibicao no LED
    output wire [1:0] led_result
);

    // ---- Estados ----
    localparam S_IDLE         = 3'b000;
    localparam S_SYNC_CAPTURE = 3'b001;
    localparam S_VALIDATE     = 3'b010;
    localparam S_EXECUTE      = 3'b011;
    localparam S_ERROR        = 3'b100;
    localparam S_WAIT_RELEASE = 3'b101;

    reg [2:0] state, next_state;
    reg [3:0] stable_cnt;
    reg [1:0] cmd_reg;
    reg [1:0] led_result_reg;
    reg       error_latch_reg;

    // ---------- LOGICA DE TRANSICAO (sequencial) ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:
                if (cmd_trigger_sync) next_state = S_SYNC_CAPTURE;

            S_SYNC_CAPTURE:
                if (!cmd_trigger_sync)                   next_state = S_IDLE;
                else if (stable_cnt >= STABLE_CYCLES-1)   next_state = S_VALIDATE;

            S_VALIDATE:
                next_state = (cmd_reg == 2'b11) ? S_ERROR : S_EXECUTE;

            S_EXECUTE:
                next_state = S_WAIT_RELEASE;

            S_ERROR:
                next_state = S_WAIT_RELEASE;

            S_WAIT_RELEASE:
                if (!cmd_trigger_sync) next_state = S_IDLE;

            default: next_state = S_IDLE;
        endcase
    end

    // ---------- DATAPATH ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) stable_cnt <= 4'd0;
        else if (state == S_SYNC_CAPTURE) stable_cnt <= stable_cnt + 4'd1;
        else stable_cnt <= 4'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cmd_reg <= 2'b00;
        else if (state == S_SYNC_CAPTURE) cmd_reg <= cmd_data_sync;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) led_result_reg <= 2'b00;
        else if (state == S_EXECUTE) led_result_reg <= cmd_reg;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) error_latch_reg <= 1'b0;
        else if (state == S_ERROR)   error_latch_reg <= 1'b1;
        else if (state == S_EXECUTE) error_latch_reg <= 1'b0;
    end

    // ---------- LOGICA DE SAIDA (combinacional) ----------
    assign busy        = (state != S_IDLE);
    assign error_flag  = (state == S_ERROR);
    assign error_latch = error_latch_reg;
    assign led_result  = led_result_reg;

endmodule