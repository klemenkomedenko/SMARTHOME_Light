`timescale 1ns/1ps

module top_tb;

    // Parameters
    parameter CLK_PERIOD = 33.33333;

    // Signals
    reg i_clk;
    reg i_rst;
    wire [63:0] o_pwm;
    wire i_rx;
    wire o_tx;

    reg [7:0] i_tx_data;
    reg i_tx_start;
    wire [7:0] o_rx_data;
    wire o_rx_vld;
    wire o_tx_busy;

    // Instantiate the DUT (replace 'top' with your actual module name)
    top # (
        .g_CLK_FREQ(30_000_000),
        .g_BAUD_RATE(1_000_000),
        .g_BEAT_FREQ(100000)
    )
    top_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx(i_rx),
        .o_tx(o_tx),
        .o_pwm(o_pwm)
    );

    uart # (
    .g_CLK_FREQ(30_000_000),
    .g_BAUD_RATE(1_000_000)
    )
    uart_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx(o_tx),
        .o_tx(i_rx),
        .o_rx_data(o_rx_data),
        .o_rx_vld(o_rx_vld),
        .i_tx_data(i_tx_data),
        .i_tx_start(i_tx_start),
        .o_tx_busy(o_tx_busy)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Stimulus
    initial begin
        // Initialize inputs
        i_rst = 1;
        repeat (40) @(posedge clk);
        i_rst = 0;
        repeat (40) @(posedge clk);
        send_uart(8'h13); // 'K'
        $stop;
    end

    task automatic send_uart;
        input [7:0] data;
        begin
            @(posedge clk);
            i_tx_data = data;
            i_tx_start = 1;
            @(posedge clk);
            i_tx_start = 0;
            wait (o_tx_busy == 0);
        end
    endtask

    task automatic receive_uart;
        output [7:0] data;
        begin
            wait (o_rx_vld == 1);
            data = o_rx_data;
        end
    endtask

    task automatic en_pwm;
        input [63:0] en;
        begin
            send_uart(8'h4B);
            send_uart(8'h02);
            send_uart(8'h07);
            send_uart(en[7:0]);
            send_uart(en[15:8]);
            send_uart(en[23:16]);
            send_uart(en[31:24]);
            send_uart(en[39:32]);
            send_uart(en[47:40]);
            send_uart(en[55:48]);
            send_uart(en[63:56]);
            send_uart(8'h0D);
        end
    endtask

    task automatic en_pwm;
        input [63:0] en;
        begin
            send_uart(8'h4B);
            send_uart(8'h00);
            send_uart(8'h00);
            send_uart(8'h12)
            send_uart(8'h0D);
        end
    endtask



endmodule