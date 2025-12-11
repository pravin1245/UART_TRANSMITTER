`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 12:51:59 PM
// Design Name: 
// Module Name: project_UART1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_debug(
    input wire clk,       // System clock
    input wire rst_n,     // Active-low reset
    input wire [7:0] data_in, // 8-bit data input from user
    input wire send,          // Pulse to send the data
    output wire tx            // UART TX line
);

    // --------------------------------------------------------
    // Parameters for UART
    // --------------------------------------------------------
    parameter BAUD = 115200;
    parameter CLOCK_FREQ = 100_000_000; // 100 MHz clock
    localparam BAUD_TICK = CLOCK_FREQ / BAUD;

    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------
    reg start_tx;
    wire busy;

    // --------------------------------------------------------
    // UART transmitter instance
    // --------------------------------------------------------
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(data_in),
        .transmit(start_tx),
        .tx(tx),
        .busy(busy)
    );

    // --------------------------------------------------------
    // FSM for sending data
    // --------------------------------------------------------
    reg [1:0] state;
    parameter IDLE = 2'b00, SEND = 2'b01, WAIT = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            start_tx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    start_tx <= 0;
                    if (send && !busy) begin
                        start_tx <= 1;
                        state <= SEND;
                    end
                end

                SEND: begin
                    start_tx <= 0; // Pulse for 1 clock
                    state <= WAIT;
                end

                WAIT: begin
                    if (!busy)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


//////////////////////////////////////////////////////////////////////////////////
// UART Transmitter Module
//////////////////////////////////////////////////////////////////////////////////
module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000, // FPGA clock frequency
    parameter BAUD = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire transmit,
    output reg tx,
    output reg busy
);

    localparam BAUD_TICKS = CLOCK_FREQ / BAUD;
    reg [15:0] baud_count;
    reg [3:0] bit_index;
    reg [9:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_count <= 0;
            tx <= 1'b1; // Idle state HIGH
            busy <= 0;
            shift_reg <= 10'b1111111111;
            bit_index <= 0;
        end else begin
            if (transmit && !busy) begin
                // Load shift register: start(0), data LSB first, stop(1)
                shift_reg <= {1'b1, tx_data, 1'b0};
                busy <= 1;
                bit_index <= 0;
                baud_count <= 0;
            end else if (busy) begin
                if (baud_count < BAUD_TICKS-1) begin
                    baud_count <= baud_count + 1;
                end else begin
                    baud_count <= 0;
                    tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    if (bit_index == 9)
                        busy <= 0;
                    bit_index <= bit_index + 1;
                end
            end
        end
    end

endmodule
