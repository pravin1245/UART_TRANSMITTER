

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

    // Baud rate generator
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD;
    reg [15:0] baud_count = 0;

    reg [3:0] bit_index = 0;
    reg [9:0] shift_reg = 10'b1111111111; // start+data+stop

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_count <= 0;
            tx <= 1'b1; // Idle state of UART is HIGH
            busy <= 0;
            shift_reg <= 10'b1111111111;
            bit_index <= 0;
        end else begin
            if (transmit && !busy) begin
                // Load shift register: start bit 
                shift_reg <= {1'b1, tx_data, 1'b0}; // LSB first
                busy <= 1;
                bit_index <= 0;
                baud_count <= 0;
            end else if (busy) begin
                if (baud_count < BAUD_TICKS-1) begin
                    baud_count <= baud_count + 1;
                end else begin
                    baud_count <= 0;
                    tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]}; // Shift right
                    if (bit_index == 9) begin
                        busy <= 0;
                        bit_index <= 0;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                end
            end
        end
    end
endmodule