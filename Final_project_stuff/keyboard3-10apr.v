`timescale 1ns / 1ps

module keyboard(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    output        tx,
    output        [9:0] game_controls

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
        .game_controls(game_controls)
    );
    
endmodule

module keyboard_controller(
    input            clk,
    input      [15:0] keycode_in,
    input             key_valid,
    output reg [9:0]  game_controls  // {p2_attack[1:0], p2_move[2:0], p1_attack[1:0], p1_move[2:0]}
);
    // Use a bitmap to track the state of all keys
    reg [255:0] key_state = 256'b0;
    
    // Define keys we care about
    localparam W_KEY     = 8'h1D;
    localparam A_KEY     = 8'h1C;
    localparam S_KEY     = 8'h1B;
    localparam D_KEY     = 8'h23;
    localparam E_KEY     = 8'h24;
    localparam SPACE_KEY = 8'h29;
    localparam KEY_4     = 8'h6B;
    localparam KEY_5     = 8'h73;
    localparam KEY_6     = 8'h74;
    localparam KEY_8     = 8'h75;
    localparam RBRACE    = 8'h5B;  // } key
    localparam BSLASH    = 8'h5D;  // \ key
    
    // Track key states
    always @(posedge clk) begin
        if (key_valid) begin
            // Key release event
            if (keycode_in[15:8] == 8'hF0) begin
                key_state[keycode_in[7:0]] <= 1'b0;
            end
            // Key press event
            else begin
                key_state[keycode_in[7:0]] <= 1'b1;
            end
        end
    end

    // Generate control outputs
    always @(posedge clk) begin
        // Default state - no movements or attacks
        game_controls <= 10'b0;
        
        // Player 1 Movement (3 bits) - bits [2:0]
        if (key_state[W_KEY])
            game_controls[2:0] <= 3'b001;      // Up
        else if (key_state[A_KEY])
            game_controls[2:0] <= 3'b010;      // Left
        else if (key_state[S_KEY])
            game_controls[2:0] <= 3'b011;      // Down
        else if (key_state[D_KEY])
            game_controls[2:0] <= 3'b100;      // Right
        else
            game_controls[2:0] <= 3'b000;      // No movement
        
        // Player 1 Attack (2 bits) - bits [4:3]
        if (key_state[E_KEY])
            game_controls[4:3] <= 2'b01;       // E attack
        else if (key_state[SPACE_KEY])
            game_controls[4:3] <= 2'b10;       // Space attack
        else
            game_controls[4:3] <= 2'b00;       // No attack
        
        // Player 2 Movement (3 bits) - bits [7:5]
        if (key_state[KEY_8])
            game_controls[7:5] <= 3'b001;      // Up
        else if (key_state[KEY_4])
            game_controls[7:5] <= 3'b010;      // Left
        else if (key_state[KEY_5])
            game_controls[7:5] <= 3'b011;      // Down
        else if (key_state[KEY_6])
            game_controls[7:5] <= 3'b100;      // Right
        else
            game_controls[7:5] <= 3'b000;      // No movement
        
        // Player 2 Attack (2 bits) - bits [9:8]
        if (key_state[RBRACE])
            game_controls[9:8] <= 2'b01;       // } attack
        else if (key_state[BSLASH])
            game_controls[9:8] <= 2'b10;       // \ attack
        else
            game_controls[9:8] <= 2'b00;       // No attack
    end
endmodule
