`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 12:25:34 PM
// Design Name: 
// Module Name: test
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

`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025
// Module Name: uart_debug
// Description: UART debug module to test UART transmission
//////////////////////////////////////////////////////////////////////////////////

module uart_debug(
    input wire clk,      // System clock
    input wire rst_n,    // Active-low reset
    output wire tx       // UART TX line
);

    // --------------------------------------------------------
    // Parameters for UART
    // --------------------------------------------------------
    parameter BAUD = 115200;
    parameter CLOCK_FREQ = 100000000; // 50 MHz clock of FPGA
    localparam BAUD_TICK = CLOCK_FREQ / BAUD;

    // --------------------------------------------------------
    // Message to send
    // --------------------------------------------------------
    reg [7:0] message [0:5]; // "Hello\n"
    initial begin
        message[0] = "H";
        message[1] = "e";
        message[2] = "l";
        message[3] = "l";
        message[4] = "o";
        message[5] = 8'h0A; // Newline
    end

    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------
    reg start_tx;
    wire busy;
    reg [2:0] msg_index;

    // --------------------------------------------------------
    // UART transmitter instance
    // --------------------------------------------------------
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(message[msg_index]),
        .transmit(start_tx),
        .tx(tx),
        .busy(busy)
    );

    // --------------------------------------------------------
    // FSM for sending message
    // --------------------------------------------------------
    reg [1:0] state;
    parameter IDLE = 2'b00, SEND = 2'b01, WAIT = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            start_tx <= 0;
            msg_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    start_tx <= 0;
                    if (msg_index < 6) begin
                        start_tx <= 1;
                        state <= SEND;
                    end
                end

                SEND: begin
                    start_tx <= 0; // Pulse for 1 clock
                    state <= WAIT;
                end

                WAIT: begin
                    if (!busy) begin
                        msg_index <= msg_index + 1;
                        state <= IDLE;
                    end
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
    parameter CLOCK_FREQ = 100000000, // FPGA clock frequency
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

