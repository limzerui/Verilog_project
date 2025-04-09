`timescale 1ns / 1ps

module keyboard(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    output        tx,
    output        [15:0] keyboard_data  // Expanded from 11 to 16 bits
);
    wire        tready;
    wire        ready;
    wire        tstart;
    reg         start=0;
    reg         CLK50MHZ=0;
    wire [31:0] tbuf;
    reg  [15:0] keycodev=0;
    wire [15:0] keycode;
    wire [ 7:0] tbus;
    reg  [ 2:0] bcount=0;
    wire        flag;
    reg         cn=0;
    
    always @(posedge(clk))begin
        CLK50MHZ<=~CLK50MHZ;
    end
    
    PS2Receiver uut (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );
    
    always@(keycode)
        casex (keycode[15:0])
            16'hxxf0: begin
                cn <= 1'b0;
                bcount <= 3'd0;
                end
            16'hf0xx: begin
                cn <= keycode != keycodev;
                bcount <= 3'd5;
                end
            default: begin
                cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
                bcount <= 3'd2;
            end
        endcase
    
    always@(posedge clk)
        if (flag == 1'b1 && cn == 1'b1) begin
            start <= 1'b1;
            keycodev <= keycode;
        end else
            start <= 1'b0;
            
    bin2ascii #(
        .NBYTES(2)
    ) conv (
        .I(keycodev),
        .O(tbuf)
    );
    
    uart_buf_con tx_con (
        .clk    (clk   ),
        .bcount (bcount),
        .tbuf   (tbuf  ),  
        .start  (start ), 
        .ready  (ready ), 
        .tstart (tstart),
        .tready (tready),
        .tbus   (tbus  )
    );
    
    uart_tx get_tx (
        .clk    (clk),
        .start  (tstart),
        .tbus   (tbus),
        .tx     (tx),
        .ready  (tready)
    );
    
    keyboard_controller kc_inst(
        .clk(clk),
        .keycode_in(keycodev),
        .key_valid(start),
        .keyboard_data(keyboard_data)
    );
    
endmodule

module keyboard_controller(
    input            clk,
    input      [15:0] keycode_in,
    input             key_valid,
    output reg [15:0] keyboard_data  // Expanded from 11 to 16 bits
);
    // Registers to hold the current and previous key pressed.
    reg [15:0] current_key = 16'd0;
    reg [15:0] prev_key    = 16'd0;
    
    always @(posedge clk) begin
        if (key_valid) begin
            // Detect a key release event: indicated by the upper byte equal to F0.
            if (keycode_in[15:8] == 8'hF0) begin
                // If the key being released is the current key
                if (keycode_in[7:0] == current_key[7:0]) begin
                    // Update current_key with prev_key if prev_key is non-zero.
                    current_key <= prev_key;
                    prev_key <= 16'd0;
                end
                // If the key being released is the previous key, clear it.
                else if (keycode_in[7:0] == prev_key[7:0]) begin
                    prev_key <= 16'd0;
                end
            end
            //key press event.
            else begin
                // if there's already a current key being held, store it as previous.
                if (current_key != 16'd0) begin
                    prev_key <= current_key;
                end
                // Update current_key with the new key press.
                current_key <= keycode_in;
            end
        end
    end
    
    // Write to register
    always @(posedge clk) begin
        // Clear all states
        keyboard_data <= 16'b0;
        case (current_key[7:0])
            // Keep existing key mappings
            8'h1D: keyboard_data[0]  <= 1'b1; // W key
            8'h1C: keyboard_data[1]  <= 1'b1; // A key
            8'h1B: keyboard_data[2]  <= 1'b1; // S key
            8'h23: keyboard_data[3]  <= 1'b1; // D key
            8'h24: keyboard_data[4]  <= 1'b1; // E key
            8'h5A: keyboard_data[5]  <= 1'b1; // ENTER key
            8'h29: keyboard_data[6]  <= 1'b1; // SPACE key
            
            // Add new key mappings
            8'h6B: keyboard_data[7]  <= 1'b1; // 4 key
            8'h73: keyboard_data[8]  <= 1'b1; // 5 key
            8'h74: keyboard_data[9]  <= 1'b1; // 6 key
            8'h75: keyboard_data[10] <= 1'b1; // 8 key
            8'h5B: keyboard_data[11] <= 1'b1; // } key
            8'h5D: keyboard_data[12] <= 1'b1; // \ key
            
            default: ; // No states for other keys
        endcase
    end

endmodule