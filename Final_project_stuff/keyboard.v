`timescale 1ns / 1ps

module top(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    output        tx,
    output         [12:2] led
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
    //reg [31:0] debug_msg = 32'b0;
    
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
        if (keycode[7:0] == 8'hf0) begin
            cn <= 1'b0;
            bcount <= 3'd0;
            //debug_msg <= {8'd82, 8'd69, 8'd76, 8'd33};
        end else if (keycode[15:8] == 8'hf0) begin
            cn <= keycode != keycodev;
            bcount <= 3'd5;
            //debug_msg <= {8'd80, 8'd82, 8'd83, 8'd33};
        end else begin
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
            bcount <= 3'd2;
            //debug_msg <= {8'd78, 8'd77, 8'd76, 8'd33};
        end
    
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
    
    //wire [10:0] led_in;
    //assign led = led_in;
    
    led_controller led_inst(
        clk,
        keycodev,
        start,
        led
    );
    
endmodule

module led_controller(
    input            clk,
    input      [15:0] keycode_in,
    input            key_valid,  // A one-shot pulse when a key event occurs
    output reg [12:2] led
);
    // Use a bitmap to track the state of all keys we care about
    reg [255:0] key_state = 256'b0;
    
    always @(posedge clk) begin
        if (key_valid) begin
            // Key release event (F0 in upper byte)
            if (keycode_in[15:8] == 8'hF0) begin
                // Clear the bit for the released key
                key_state[keycode_in[7:0]] <= 1'b0;
            end
            // Key press event
            else begin
                // Set the bit for the pressed key
                key_state[keycode_in[7:0]] <= 1'b1;
            end
        end
    end

    // Update LEDs based on key_state bitmap
    always @(posedge clk) begin
        // Clear all LEDs first
        led <= 11'b0;
        
        // Set individual LEDs based on key state
        led[2]  <= key_state[8'h1D]; // W key
        led[3]  <= key_state[8'h1C]; // A key
        led[4]  <= key_state[8'h1B]; // S key
        led[5]  <= key_state[8'h23]; // D key
        led[6]  <= key_state[8'h24]; // E key
        led[7]  <= key_state[8'h5A]; // ENTER key
        led[8]  <= key_state[8'h29]; // SPACE key
        led[9]  <= key_state[8'h16]; // 1 key
        led[10] <= key_state[8'h1E]; // 2 key
        led[11] <= key_state[8'h26]; // 3 key
        led[12] <= key_state[8'h25]; // 4 key
    end
endmodule