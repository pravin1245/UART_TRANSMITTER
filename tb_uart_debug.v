

//////////////////////////////////////////////////////////////////////////////////
// Testbench for uart_debug
//////////////////////////////////////////////////////////////////////////////////
module tb_uart_debug();

    // Clock and reset
    reg clk;
    reg rst_n;

    // Data sent to UART
    reg [7:0] data;

    // UART TX wire
    wire tx;

    // Instantiate the DUT (Device Under Test)
    uart_debug uut (
        .clk(clk),
        .rst_n(rst_n),
        .data(data),
        .tx(tx)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz (20 ns period)

    // Reset sequence
    initial begin
        rst_n = 0;
        data  = 8'h41;   // ASCII 'A' → 0x41
        #100;            // Hold reset for 100 ns
        rst_n = 1;       // Release reset
    end

    // Monitor the TX line
    initial begin
        $dumpfile("uart_debug_tb.vcd");
        $dumpvars(0, tb_uart_debug);
        $display("Time\tTX");
        $monitor("%0t\t%b", $time, tx);
    end

    // Run simulation long enough to see several UART frames
    initial begin
        #300000;   // 300 us
        $display("Simulation finished.");
        $finish;
    end

endmodule

