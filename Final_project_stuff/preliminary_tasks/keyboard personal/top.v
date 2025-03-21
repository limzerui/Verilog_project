`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc 
// Engineer: Arthur Brown
// 
// Create Date: 07/27/2016 02:04:01 PM
// Design Name: Basys3 Keyboard Demo
// Module Name: top
// Project Name: Keyboard
// Target Devices: Basys3
// Tool Versions: 2016.X
// Description: 
//     Receives input from USB-HID in the form of a PS/2, displays keyboard key presses and releases over USB-UART.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//     Known issue, when multiple buttons are pressed and one is released, the scan code of the one still held down is ometimes re-sent.
// The `top` module interfaces a PS/2 keyboard with a UART transmitter.
// It captures key presses, converts them to ASCII, and transmits them over UART.
//////////////////////////////////////////////////////////////////////////////////


module top(
    input         clk,      // System clock signal
    input         PS2Data,  // PS/2 keyboard data line
    input         PS2Clk,   // PS/2 keyboard clock line
    output        tx        // UART serial transmit output
);
    wire        tready;   // UART transmission ready flag
    wire        ready;    // UART buffer ready flag
    wire        tstart;   // Start signal for UART transmission
    reg         start=0;  // Indicates when to start UART transmission
    reg         CLK50MHZ=0; // Internal 50MHz clock for PS/2 receiver
    wire [31:0] tbuf;     // Buffer to hold ASCII-converted keycode for UART
    reg  [15:0] keycodev=0; // Stores the last received keycode
    wire [15:0] keycode;  // Current keycode received from PS2Receiver
    wire [ 7:0] tbus;     // Data bus carrying the character to transmit via UART
    reg  [ 2:0] bcount=0; // Counter for tracking the number of bytes to transmit
    wire        flag;     // Flag indicating when a new keycode is available
    reg         cn=0;     // Change flag indicating whether the keycode has changed
    
    // Generate a 50MHz clock signal by toggling CLK50MHZ on each rising edge of clk
    always @(posedge(clk)) begin
        CLK50MHZ <= ~CLK50MHZ;
    end
    
    // Instantiate the PS2Receiver module to decode PS/2 keyboard data
    PS2Receiver uut (
        .clk(CLK50MHZ),  // Use the 50MHz clock for stable operation
        .kclk(PS2Clk),   // PS/2 keyboard clock input
        .kdata(PS2Data), // PS/2 keyboard data input
        .keycode(keycode), // Output decoded keycode
        .oflag(flag)     // Output flag indicating when a new key is received
    );
    
    // Determine whether a key has been pressed or released
    always@(keycode)
        if (keycode[7:0] == 8'hf0) begin
            // Key release detected (f0 indicates a key release)
            cn <= 1'b0;  // Reset change flag
            bcount <= 3'd0; // No characters need to be sent
        end else if (keycode[15:8] == 8'hf0) begin
            // New key press detected, check if it differs from the previous key
            cn <= keycode != keycodev; // Set change flag if different
            bcount <= 3'd5; // Set count for transmission
        end else begin
            // Normal key press event
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
            bcount <= 3'd2; // Default transmission count
        end
    
    // Trigger UART transmission when a new key is detected
    always@(posedge clk)
        if (flag == 1'b1 && cn == 1'b1) begin
            start <= 1'b1; // Start UART transmission
            keycodev <= keycode; // Store the new keycode
        end else
            start <= 1'b0; // Reset start signal if no new key
            
    // Convert the binary keycode to ASCII for UART transmission
    bin2ascii #(
        .NBYTES(2) // Convert two bytes of data
    ) conv (
        .I(keycodev), // Input: binary keycode
        .O(tbuf)      // Output: ASCII representation of keycode
    );
    
    // Manage UART buffer and transmission control
    uart_buf_con tx_con (
        .clk    (clk   ), // System clock
        .bcount (bcount), // Byte count for transmission
        .tbuf   (tbuf  ), // Data buffer
        .start  (start ), // Start transmission signal
        .ready  (ready ), // UART buffer ready flag
        .tstart (tstart), // UART start transmission signal
        .tready (tready), // UART transmission ready flag
        .tbus   (tbus  )  // Byte to transmit
    );
    
    // UART transmission module to send data serially
    uart_tx get_tx (
        .clk    (clk),    // System clock
        .start  (tstart), // Start signal for UART transmission
        .tbus   (tbus),   // Data byte to transmit
        .tx     (tx),     // UART transmit output
        .ready  (tready)  // UART ready flag
    );
    
endmodule`
