module top_module(
    input clk,              // Board clock
    input [13:0] sw,        // Switches: {char1[1:0], health1[3:0], char2[1:0], health2[3:0]}
    output [7:0] seg,       // 7-segment display segments
    output [3:0] an,        // 7-segment display anodes
    output [15:0] led,      // LEDs for health indication
    output [7:0] JB         // PMOD JB for shared OLED
);
    
    // Pass the full 14 bits to the game_character_health module
    wire [13:0] data = sw;
    
    // Instantiate the game_character_health module
    game_character_health gch(
        .clk(clk),
        .data(data),
        .seg(seg),
        .an(an),
        .led(led),
        .JB(JB)
    );
    
endmodule

module game_character_health(
    input clk,
    input [11:0] data,     
    output [7:0] seg,      
    output [3:0] an,       
    output [15:0] led,     
    output [7:0] JB        
);

  // Extract player 1 data
wire [1:0] player1_character = data[11:10];
wire [3:0] player1_health = data[9:6];
    
// Extract player 2 data
wire [1:0] player2_character = data[5:4]; 
wire [3:0] player2_health = data[3:0];

    // Clock generation for OLED
    wire clk6p25m;
    generic_timer #(.COUNT_MAX(7))
    oled_clock (
        .clk(clk),
        .clk_out(clk6p25m)
    );

    wire [15:0] oled_data;
    wire [12:0] pixel_index;
    
    Oled_Display oled_display (
        .clk(clk6p25m), 
        .reset(0),
        .pixel_index(pixel_index),
        .pixel_data(oled_data),
        .cs(JB[0]),
        .sdin(JB[1]),
        .sclk(JB[3]),
        .d_cn(JB[4]),
        .resn(JB[5]),
        .vccen(JB[6]),
        .pmoden(JB[7])
    );
    
    // Convert pixel index to x,y coordinates
    wire [6:0] x;
    wire [5:0] y;
    
    xyconverter xy_converter (pixel_index, x, y);
    
    // Determine which side of the screen we're rendering
    wire is_player1_side = (x < 48);  // Left half for Player 1
    
    wire is_player2_side = (x >= 48); // Right half for Player 2    
    // Character direction (fixed since characters are stationary)
    reg [1:0] char_direction = 2'b00; // Default: facing up

        // Fixed position for character display (adjusted for split screen)
    // For 20×20 pixel sprites
    parameter P1_CHAR_X_POS = 7'd24;  // Center of left half
    parameter P2_CHAR_X_POS = 7'd72;  // Center of right half
    parameter CHAR_Y_POS = 6'd32;     // Vertically centered
    
    // Character sprites need coordinates relative to sprite center
    parameter SPRITE_WIDTH = 20;
    parameter SPRITE_HEIGHT = 20;
    parameter SPRITE_HALF_WIDTH = SPRITE_WIDTH / 2;
    parameter SPRITE_HALF_HEIGHT = SPRITE_HEIGHT / 2;
    
    // Calculate relative coordinates for the appropriate character
    // For 20×20 sprites, the range is -10 to +9 in both dimensions
    wire signed [6:0] rel_x = is_player1_side ? 
                             (x - P1_CHAR_X_POS + SPRITE_HALF_WIDTH) : 
                             (x - P2_CHAR_X_POS + SPRITE_HALF_WIDTH);
    wire signed [5:0] rel_y = y - CHAR_Y_POS + SPRITE_HALF_HEIGHT;
    
    assign oled_data = 
    (current_character == 2'b00) ? ((mage_data != 16'h0001) ? mage_data : 16'h0000) :
    (current_character == 2'b01) ? ((gunman_data != 16'h0001) ? gunman_data : 16'h0000) :
    (current_character == 2'b10) ? ((swordman_data != 16'h0001) ? swordman_data : 16'h0000) :
    ((fistman_data != 16'h0001) ? fistman_data : 16'h0000);

    wire [15:0] mage_data, gunman_data, swordman_data, fistman_data;
    
    // Character sprites (single instance of each)
    mage_bram mage (
        .clk(clk6p25m), 
        .x(rel_x), 
        .y(rel_y),
        .magedirection(char_direction), 
        .pixel_data(mage_data)
    );
    
    gunman_bram gunman (
        .clk(clk6p25m), 
        .x(rel_x), 
        .y(rel_y),
        .gunmandirection(char_direction), 
        .pixel_data(gunman_data)
    );
    
    swordman_bram swordman (
        .clk(clk6p25m), 
        .x(rel_x), 
        .y(rel_y),
        .swordmandirection(char_direction), 
        .pixel_data(swordman_data)
    );
    
    fistman_bram fistman (
        .clk(clk6p25m), 
        .x(rel_x), 
        .y(rel_y),
        .fistmandirection(char_direction), 
        .pixel_data(fistman_data)
    );
    
    // Character selection based on which side of screen we're on
    wire [1:0] current_character = is_player1_side ? player1_character : player2_character;
    

    
    // Display both players' health on 7-segment display
    dual_player_health_display health_display (
        .clk(clk),
        .player1_health(player1_health),
        .player2_health(player2_health),
        .seg(seg),
        .an(an)
    );
    
    // Control LEDs based on player health
    dual_player_led_control led_control (
        .clk(clk),
        .player1_health(player1_health),
        .player2_health(player2_health),
        .led(led)
    );
    
endmodule

module dual_player_health_display(
    input clk,
    input [3:0] player1_health,
    input [3:0] player2_health,
    output reg [7:0] seg,
    output reg [3:0] an
);
    wire animation_clk;
    generic_timer #(.COUNT_MAX(149999)) seven_seg_timer (
        .clk(clk),
        .clk_out(animation_clk)
    );
    
    reg [1:0] digit_select;
    reg [3:0] digit_value;
    
    always @(posedge animation_clk) begin
        digit_select <= digit_select + 1;
    end
    
    always @(*) begin
        case(digit_select)
            2'b00: begin  // Leftmost digit - Player 1 tens place
                an = 4'b0111;
                digit_value = player1_health / 10;
            end
            2'b01: begin  // Second digit - Player 1 ones place
                an = 4'b1011;
                digit_value = player1_health % 10;
            end
            2'b10: begin  // Third digit - Player 2 tens place
                an = 4'b1101;
                digit_value = player2_health / 10;
            end
            2'b11: begin  // Rightmost digit - Player 2 ones place
                an = 4'b1110;
                digit_value = player2_health % 10;
            end
        endcase
        
        // Decode the digit value to 7-segment display pattern
        case(digit_value)
            4'b0000: seg = 8'b11000000;  // Digit 0
            4'b0001: seg = 8'b11111001;  // Digit 1
            4'b0010: seg = 8'b10100100;  // Digit 2
            4'b0011: seg = 8'b10110000;  // Digit 3
            4'b0100: seg = 8'b10011001;  // Digit 4
            4'b0101: seg = 8'b10010010;  // Digit 5
            4'b0110: seg = 8'b10000010;  // Digit 6
            4'b0111: seg = 8'b11111000;  // Digit 7
            4'b1000: seg = 8'b10000000;  // Digit 8
            4'b1001: seg = 8'b10010000;  // Digit 9
            default: seg = 8'b11111111;  // Blank
        endcase
    end
endmodule

module dual_player_led_control(
    input clk,
    input [3:0] player1_health,
    input [3:0] player2_health,
    output reg [15:0] led
);
    wire blink_clk;
    generic_timer #(.COUNT_MAX(9999999)) blink_timer (
        .clk(clk),
        .clk_out(blink_clk)
    );
    
    reg blink_state = 0;
    
    always @(posedge blink_clk) begin
        blink_state <= ~blink_state;
    end
    
    always @(*) begin
        if (player1_health == 4'd1 && player2_health == 4'd1) begin
            // Both players at critical health - blink all LEDs
            led = blink_state ? 16'hFFFF : 16'h0000;
        end
        else if (player1_health == 4'd1) begin
            // Player 1 at critical health - blink upper 8 LEDs
            led = {blink_state ? 8'hFF : 8'h00, 8'h00};
        end
        else if (player2_health == 4'd1) begin
            // Player 2 at critical health - blink lower 8 LEDs
            led = {8'h00, blink_state ? 8'hFF : 8'h00};
        end
        else begin
            // No critical health - all LEDs off
            led = 16'h0000;
        end
    end
endmodule

module xyconverter(
    input [12:0] pixelindex, 
    output [6:0] x,
    output [5:0] y
);
    assign x = pixelindex % 96;
    assign y = pixelindex / 96;
endmodule

module generic_timer #(
    parameter COUNT_MAX = 49999999  // Default for ~1Hz with 100MHz clock
)(
    input clk,
    output reg clk_out
);
    reg [31:0] count;

    initial begin
        clk_out = 0;
        count = 0;
    end

    always @(posedge clk) begin
        if (count >= COUNT_MAX) begin
            clk_out <= ~clk_out;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
endmodule