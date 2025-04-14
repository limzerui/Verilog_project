`timescale 1ns / 1ps

module keyboard(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
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

    reg [255:0] key_state = 0;  
    reg [255:0] prev_key_state = 0;
    
    reg [7:0] p1_dir_key = 0;
    reg [7:0] p2_dir_key = 0;
    
    // Define keys we care about
    localparam W_KEY     = 8'h1D;
    localparam A_KEY     = 8'h1C;
    localparam S_KEY     = 8'h1B;
    localparam D_KEY     = 8'h23;
    localparam E_KEY     = 8'h24;
    localparam SPACE_KEY = 8'h29;
    localparam KEY_4     = 8'h6B;
    localparam KEY_2     = 8'h72;
    localparam KEY_6     = 8'h74;
    localparam KEY_8     = 8'h75;
    localparam ZERO      = 8'h71;  // } key
    localparam PERIOD    = 8'h70;  // \ key
    
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
        
        // Save previous key state for edge detection
        prev_key_state <= key_state;
    end
    
    // Direction key selection logic with edge detection and priority fallback
    always @(posedge clk) begin
        // Player 1 direction key logic
        
        // Check for newly pressed keys (rising edge detection)
        if (!prev_key_state[W_KEY] && key_state[W_KEY])
            p1_dir_key <= W_KEY;
        else if (!prev_key_state[A_KEY] && key_state[A_KEY])
            p1_dir_key <= A_KEY;
        else if (!prev_key_state[S_KEY] && key_state[S_KEY])
            p1_dir_key <= S_KEY;
        else if (!prev_key_state[D_KEY] && key_state[D_KEY])
            p1_dir_key <= D_KEY;
        // If current direction key is released, check for fallback
        else if (p1_dir_key != 0 && !key_state[p1_dir_key]) begin
            if (key_state[W_KEY])
                p1_dir_key <= W_KEY;
            else if (key_state[A_KEY])
                p1_dir_key <= A_KEY;
            else if (key_state[S_KEY])
                p1_dir_key <= S_KEY;
            else if (key_state[D_KEY])
                p1_dir_key <= D_KEY;
            else
                p1_dir_key <= 8'h00;
        end
        
        // Player 2 direction key logic
        
        // Check for newly pressed keys (rising edge detection)
        if (!prev_key_state[KEY_8] && key_state[KEY_8])
            p2_dir_key <= KEY_8;
        else if (!prev_key_state[KEY_4] && key_state[KEY_4])
            p2_dir_key <= KEY_4;
        else if (!prev_key_state[KEY_2] && key_state[KEY_2])
            p2_dir_key <= KEY_2;
        else if (!prev_key_state[KEY_6] && key_state[KEY_6])
            p2_dir_key <= KEY_6;
        // If current direction key is released, check for fallback
        else if (p2_dir_key != 0 && !key_state[p2_dir_key]) begin
            if (key_state[KEY_8])
                p2_dir_key <= KEY_8;
            else if (key_state[KEY_4])
                p2_dir_key <= KEY_4;
            else if (key_state[KEY_2])
                p2_dir_key <= KEY_2;
            else if (key_state[KEY_6])
                p2_dir_key <= KEY_6;
            else
                p2_dir_key <= 8'h00;
        end
    end

    // Generate control outputs
    always @(posedge clk) begin
        // Default state - no attacks
        game_controls[9:8] <= 2'b00;
        game_controls[4:3] <= 2'b00;
        
        // Player 1 Movement based on direction key
        case(p1_dir_key)
            W_KEY: game_controls[2:0] <= 3'b001;
            A_KEY: game_controls[2:0] <= 3'b010;
            S_KEY: game_controls[2:0] <= 3'b011;
            D_KEY: game_controls[2:0] <= 3'b100;
            default: game_controls[2:0] <= 3'b000;
        endcase
        
        // Player 2 Movement based on direction key
        case(p2_dir_key)
            KEY_8: game_controls[7:5] <= 3'b001;
            KEY_4: game_controls[7:5] <= 3'b010;
            KEY_2: game_controls[7:5] <= 3'b011;
            KEY_6: game_controls[7:5] <= 3'b100;
            default: game_controls[7:5] <= 3'b000;
        endcase
        
        // Player 1 Attack (2 bits) - bits [4:3]
        if (key_state[E_KEY])
            game_controls[4:3] <= 2'b01;
        else if (key_state[SPACE_KEY])
            game_controls[4:3] <= 2'b10;
            
        // Player 2 Attack (2 bits) - bits [9:8]
        if (key_state[PERIOD])
            game_controls[9:8] <= 2'b01;
        else if (key_state[ZERO])
            game_controls[9:8] <= 2'b10;
    end
endmodule

module bin2ascii(
    input [NBYTES*8-1:0] I,
    output reg [NBYTES*16-1:0] O=0
    );
    parameter NBYTES=2;
    genvar i;
    generate for (i=0; i<NBYTES*2; i=i+1)
        always@(I)
        if (I[4*i+3:4*i] >= 4'h0 && I[4*i+3:4*i] <= 4'h9)
            O[8*i+7:8*i] = 8'd48 + I[4*i+3:4*i];
        else
            O[8*i+7:8*i] = 8'd55 + I[4*i+3:4*i];
    endgenerate
endmodule

module PS2Receiver(
    input clk,
    input kclk,
    input kdata,
    output reg [15:0] keycode=0,
    output reg oflag
    );
    
    wire kclkf, kdataf;
    reg [7:0]datacur=0;
    reg [7:0]dataprev=0;
    reg [3:0]cnt=0;
    reg flag=0;
    
debouncer #(
    .COUNT_MAX(19),
    .COUNT_WIDTH(5)
) db_clk(
    .clk(clk),
    .I(kclk),
    .O(kclkf)
);
debouncer #(
   .COUNT_MAX(19),
   .COUNT_WIDTH(5)
) db_data(
    .clk(clk),
    .I(kdata),
    .O(kdataf)
);
    
always@(negedge(kclkf))begin
    case(cnt)
    0:;//Start bit
    1:datacur[0]<=kdataf;
    2:datacur[1]<=kdataf;
    3:datacur[2]<=kdataf;
    4:datacur[3]<=kdataf;
    5:datacur[4]<=kdataf;
    6:datacur[5]<=kdataf;
    7:datacur[6]<=kdataf;
    8:datacur[7]<=kdataf;
    9:flag<=1'b1;
    10:flag<=1'b0;
    
    endcase
        if(cnt<=9) cnt<=cnt+1;
        else if(cnt==10) cnt<=0;
end

reg pflag;
always@(posedge clk) begin
    if (flag == 1'b1 && pflag == 1'b0) begin
        keycode <= {dataprev, datacur};
        oflag <= 1'b1;
        dataprev <= datacur;
    end else
        oflag <= 'b0;
    pflag <= flag;
end

endmodule

module debouncer(
    input clk,
    input I,
    output reg O
    );
    parameter COUNT_MAX=255, COUNT_WIDTH=8;
    reg [COUNT_WIDTH-1:0] count;
    reg Iv=0;
    always@(posedge clk)
        if (I == Iv) begin
            if (count == COUNT_MAX)
                O <= I;
            else
                count <= count + 1'b1;
        end else begin
            count <= 'b0;
            Iv <= I;
        end
    
endmodule


//`timescale 1ns / 1ps

//module keyboard(
//    input         clk,
//    input         PS2Data,
//    input         PS2Clk,
//    output        [9:0] game_controls
//);
//    wire        tready;
//    wire        ready;
//    wire        tstart;
//    reg         start=0;
//    reg         CLK50MHZ=0;
//    wire [31:0] tbuf;
//    reg  [15:0] keycodev=0;
//    wire [15:0] keycode;
//    wire [ 7:0] tbus;
//    reg  [ 2:0] bcount=0;
//    wire        flag;
//    reg         cn=0;
    
//    always @(posedge(clk))begin
//        CLK50MHZ<=~CLK50MHZ;
//    end
    
//    PS2Receiver uut (
//        .clk(CLK50MHZ),
//        .kclk(PS2Clk),
//        .kdata(PS2Data),
//        .keycode(keycode),
//        .oflag(flag)
//    );
    
//    always@(keycode)
//        casex (keycode[15:0])
//            16'hxxf0: begin
//                cn <= 1'b0;
//                bcount <= 3'd0;
//                end
//            16'hf0xx: begin
//                cn <= keycode != keycodev;
//                bcount <= 3'd5;
//                end
//            default: begin
//                cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
//                bcount <= 3'd2;
//            end
//        endcase
    
//    always@(posedge clk)
//        if (flag == 1'b1 && cn == 1'b1) begin
//            start <= 1'b1;
//            keycodev <= keycode;
//        end else
//            start <= 1'b0;
            
//    bin2ascii #(
//        .NBYTES(2)
//    ) conv (
//        .I(keycodev),
//        .O(tbuf)
//    );
    
//    keyboard_controller kc_inst(
//        .clk(clk),
//        .keycode_in(keycodev),
//        .key_valid(start),
//        .game_controls(game_controls)
//    );
    
//endmodule

//module keyboard_controller(
//    input            clk,
//    input      [15:0] keycode_in,
//    input             key_valid,
//    output reg [9:0]  game_controls  // {p2_attack[1:0], p2_move[2:0], p1_attack[1:0], p1_move[2:0]}
//);

//    reg [255:0] key_state = 0;  
//    reg [255:0] prev_key_state = 0;
    
//    reg [7:0] p1_dir_key = 0;
//    reg [7:0] p2_dir_key = 0;
    
//    // Define keys we care about
//    localparam W_KEY     = 8'h1D;
//    localparam A_KEY     = 8'h1C;
//    localparam S_KEY     = 8'h1B;
//    localparam D_KEY     = 8'h23;
//    localparam E_KEY     = 8'h24;
//    localparam SPACE_KEY = 8'h29;
//    localparam KEY_4     = 8'h6B;
//    localparam KEY_5     = 8'h73;
//    localparam KEY_6     = 8'h74;
//    localparam KEY_8     = 8'h75;
//    localparam RBRACE    = 8'h5B;  // } key
//    localparam BSLASH    = 8'h5D;  // \ key
    
//        // Track key states
//    always @(posedge clk) begin
//        if (key_valid) begin
//            // Key release event
//            if (keycode_in[15:8] == 8'hF0) begin
//                key_state[keycode_in[7:0]] <= 1'b0;
//            end
//            // Key press event
//            else begin
//                key_state[keycode_in[7:0]] <= 1'b1;
//            end
//        end
        
//        // Save previous key state for edge detection
//        prev_key_state <= key_state;
//    end
    
//    // Direction key selection logic with edge detection and priority fallback
//    always @(posedge clk) begin
//        // Player 1 direction key logic
        
//        // Check for newly pressed keys (rising edge detection)
//        if (!prev_key_state[W_KEY] && key_state[W_KEY])
//            p1_dir_key <= W_KEY;
//        else if (!prev_key_state[A_KEY] && key_state[A_KEY])
//            p1_dir_key <= A_KEY;
//        else if (!prev_key_state[S_KEY] && key_state[S_KEY])
//            p1_dir_key <= S_KEY;
//        else if (!prev_key_state[D_KEY] && key_state[D_KEY])
//            p1_dir_key <= D_KEY;
//        // If current direction key is released, check for fallback
//        else if (p1_dir_key != 0 && !key_state[p1_dir_key]) begin
//            if (key_state[W_KEY])
//                p1_dir_key <= W_KEY;
//            else if (key_state[A_KEY])
//                p1_dir_key <= A_KEY;
//            else if (key_state[S_KEY])
//                p1_dir_key <= S_KEY;
//            else if (key_state[D_KEY])
//                p1_dir_key <= D_KEY;
//            else
//                p1_dir_key <= 8'h00;
//        end
        
//        // Player 2 direction key logic
        
//        // Check for newly pressed keys (rising edge detection)
//        if (!prev_key_state[KEY_8] && key_state[KEY_8])
//            p2_dir_key <= KEY_8;
//        else if (!prev_key_state[KEY_4] && key_state[KEY_4])
//            p2_dir_key <= KEY_4;
//        else if (!prev_key_state[KEY_5] && key_state[KEY_5])
//            p2_dir_key <= KEY_5;
//        else if (!prev_key_state[KEY_6] && key_state[KEY_6])
//            p2_dir_key <= KEY_6;
//        // If current direction key is released, check for fallback
//        else if (p2_dir_key != 0 && !key_state[p2_dir_key]) begin
//            if (key_state[KEY_8])
//                p2_dir_key <= KEY_8;
//            else if (key_state[KEY_4])
//                p2_dir_key <= KEY_4;
//            else if (key_state[KEY_5])
//                p2_dir_key <= KEY_5;
//            else if (key_state[KEY_6])
//                p2_dir_key <= KEY_6;
//            else
//                p2_dir_key <= 8'h00;
//        end
//    end

//    // Generate control outputs
//    always @(posedge clk) begin
//        // Default state - no attacks
//        game_controls[9:8] <= 2'b00;
//        game_controls[4:3] <= 2'b00;
        
//        // Player 1 Movement based on direction key
//        case(p1_dir_key)
//            W_KEY: game_controls[2:0] <= 3'b001;
//            A_KEY: game_controls[2:0] <= 3'b010;
//            S_KEY: game_controls[2:0] <= 3'b011;
//            D_KEY: game_controls[2:0] <= 3'b100;
//            default: game_controls[2:0] <= 3'b000;
//        endcase
        
//        // Player 2 Movement based on direction key
//        case(p2_dir_key)
//            KEY_8: game_controls[7:5] <= 3'b001;
//            KEY_4: game_controls[7:5] <= 3'b010;
//            KEY_5: game_controls[7:5] <= 3'b011;
//            KEY_6: game_controls[7:5] <= 3'b100;
//            default: game_controls[7:5] <= 3'b000;
//        endcase
        
//        // Player 1 Attack (2 bits) - bits [4:3]
//        if (key_state[E_KEY])
//            game_controls[4:3] <= 2'b01;
//        else if (key_state[SPACE_KEY])
//            game_controls[4:3] <= 2'b10;
            
//        // Player 2 Attack (2 bits) - bits [9:8]
//        if (key_state[RBRACE])
//            game_controls[9:8] <= 2'b01;
//        else if (key_state[BSLASH])
//            game_controls[9:8] <= 2'b10;
//    end
//endmodule

//module bin2ascii(
//    input [NBYTES*8-1:0] I,
//    output reg [NBYTES*16-1:0] O=0
//    );
//    parameter NBYTES=2;
//    genvar i;
//    generate for (i=0; i<NBYTES*2; i=i+1)
//        always@(I)
//        if (I[4*i+3:4*i] >= 4'h0 && I[4*i+3:4*i] <= 4'h9)
//            O[8*i+7:8*i] = 8'd48 + I[4*i+3:4*i];
//        else
//            O[8*i+7:8*i] = 8'd55 + I[4*i+3:4*i];
//    endgenerate
//endmodule

//module PS2Receiver(
//    input clk,
//    input kclk,
//    input kdata,
//    output reg [15:0] keycode=0,
//    output reg oflag
//    );
    
//    wire kclkf, kdataf;
//    reg [7:0]datacur=0;
//    reg [7:0]dataprev=0;
//    reg [3:0]cnt=0;
//    reg flag=0;
    
//debouncer #(
//    .COUNT_MAX(19),
//    .COUNT_WIDTH(5)
//) db_clk(
//    .clk(clk),
//    .I(kclk),
//    .O(kclkf)
//);
//debouncer #(
//   .COUNT_MAX(19),
//   .COUNT_WIDTH(5)
//) db_data(
//    .clk(clk),
//    .I(kdata),
//    .O(kdataf)
//);
    
//always@(negedge(kclkf))begin
//    case(cnt)
//    0:;//Start bit
//    1:datacur[0]<=kdataf;
//    2:datacur[1]<=kdataf;
//    3:datacur[2]<=kdataf;
//    4:datacur[3]<=kdataf;
//    5:datacur[4]<=kdataf;
//    6:datacur[5]<=kdataf;
//    7:datacur[6]<=kdataf;
//    8:datacur[7]<=kdataf;
//    9:flag<=1'b1;
//    10:flag<=1'b0;
    
//    endcase
//        if(cnt<=9) cnt<=cnt+1;
//        else if(cnt==10) cnt<=0;
//end

//reg pflag;
//always@(posedge clk) begin
//    if (flag == 1'b1 && pflag == 1'b0) begin
//        keycode <= {dataprev, datacur};
//        oflag <= 1'b1;
//        dataprev <= datacur;
//    end else
//        oflag <= 'b0;
//    pflag <= flag;
//end

//endmodule

//module debouncer(
//    input clk,
//    input I,
//    output reg O
//    );
//    parameter COUNT_MAX=255, COUNT_WIDTH=8;
//    reg [COUNT_WIDTH-1:0] count;
//    reg Iv=0;
//    always@(posedge clk)
//        if (I == Iv) begin
//            if (count == COUNT_MAX)
//                O <= I;
//            else
//                count <= count + 1'b1;
//        end else begin
//            count <= 'b0;
//            Iv <= I;
//        end
    
//endmodule
