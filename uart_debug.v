

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025
// Module Name: uart_debug
// Description: UART debug module to test UART transmission
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000, // FPGA system clock
    parameter BAUD       = 115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] tx_data,
    input  wire transmit,
    output reg tx,
    output reg busy
);

    // Baud rate division count
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD;

    reg [15:0] baud_count = 0;
    reg [3:0] bit_index = 0;

    // UART shift register (start + 8 data + stop)
    reg [9:0] shift_reg = 10'b1111111111;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_count <= 0;
            tx         <= 1'b1;      // idle HIGH
            busy       <= 0;
            shift_reg  <= 10'b1111111111;
            bit_index  <= 0;
        end 
        else begin

            // START TRANSMISSION
            if (transmit && !busy) begin
                shift_reg <= {1'b1, tx_data, 1'b0}; // {stop, data, start}
                busy       <= 1;
                bit_index  <= 0;
                baud_count <= 0;
            end 

            // SENDING BITS
            else if (busy) begin
                if (baud_count < BAUD_TICKS-1) begin
                    baud_count <= baud_count + 1;
                end 
                else begin
                    baud_count <= 0;

                    tx <= shift_reg[0];                   // output next bit
                    shift_reg <= {1'b1, shift_reg[9:1]}; // logical shift

                    if (bit_index == 9) begin
                        busy <= 0;      // done sending 1 frame
                        bit_index <= 0;
                    end 
                    else begin
                        bit_index <= bit_index + 1;
                    end
                end
            end
        end
    end

endmodule
