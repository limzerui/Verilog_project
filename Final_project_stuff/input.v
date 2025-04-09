module game_character_health(
    input clk,
    input [6:0] data,        // {1'b0, character_reg[1:0], health_reg[3:0]}
    output [7:0] seg,        // 7-segment display
    output [3:0] an,         // 7-segment display anode
    output [7:0] led,        // LED outputs
    output [7:0] JB          // PMOD JB ports for OLED
);
    
    // Extract fields from data input
    wire [1:0] character_type = data[5:4];  // Character type (2 bits)
    wire [3:0] health_value = data[3:0];    // Health value (4 bits, 0-10)

    //--------------------------------------------------------------------------
    // OLED Display for Character
    //--------------------------------------------------------------------------
    wire clk6p25m;
    slowclock oled_clock (clk, 32'd7, clk6p25m);
    
    reg [15:0] oled_data;
    wire frame_begin, sendingpixels, samplepixel;
    wire [12:0] pixelindex;
    
    Oled_Display oled_display (
        .clk(clk6p25m), 
        .reset(0),
        .frame_begin(frame_begin),
        .sending_pixels(sendingpixels),
        .sample_pixel(samplepixel),
        .pixel_index(pixelindex),
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
    xyconverter xy_conv (pixelindex, x, y);
    
    // Fixed position for character display
    parameter CHAR_X_POS = 7'd40;
    parameter CHAR_Y_POS = 6'd20;
    
    // Relative coordinates for character sprites
    wire signed [6:0] rel_x = x - CHAR_X_POS;
    wire signed [5:0] rel_y = y - CHAR_Y_POS;
    
    // Character sprite data
    wire [15:0] mage_data, gunman_data, swordman_data, fistman_data;
    
    // Character direction (can be set based on game logic if needed)
    reg [1:0] char_direction = 2'b00; // Default: facing up
    
    // Character sprite BRAMs
    mage_bram mage_sprite (
        .clk(clk6p25m),
        .x(rel_x),
        .y(rel_y),
        .magedirection(char_direction),
        .pixel_data(mage_data)
    );
    
    gunman_bram gunman_sprite (
        .clk(clk6p25m),
        .x(rel_x),
        .y(rel_y),
        .gunmandirection(char_direction),
        .pixel_data(gunman_data)
    );
    
    swordman_bram swordman_sprite (
        .clk(clk6p25m),
        .x(rel_x),
        .y(rel_y),
        .swordmandirection(char_direction),
        .pixel_data(swordman_data)
    );
    
    fistman_bram fistman_sprite (
        .clk(clk6p25m),
        .x(rel_x),
        .y(rel_y),
        .fistmandirection(char_direction),
        .pixel_data(fistman_data)
    );
    
    // Select sprite based on character type
    always @(posedge clk6p25m) begin
        case(character_type)
            2'b00: oled_data <= (mage_data != 16'h0001) ? mage_data : 16'h0000;
            2'b01: oled_data <= (gunman_data != 16'h0001) ? gunman_data : 16'h0000;
            2'b10: oled_data <= (swordman_data != 16'h0001) ? swordman_data : 16'h0000;
            2'b11: oled_data <= (fistman_data != 16'h0001) ? fistman_data : 16'h0000;
            default: oled_data <= 16'h0000;
        endcase
    end
    
    //--------------------------------------------------------------------------
    // 7-Segment Health Display
    //--------------------------------------------------------------------------
    seven_seg_controller health_display (
        .clk(clk),
        .number({3'b000, health_value}),  // Convert 4-bit health to 7-bit number
        .seg(seg),
        .an(an)
    );
    
    //--------------------------------------------------------------------------
    // LED Health Indicator (10-health LEDs lit, flash when health = 1)
    //--------------------------------------------------------------------------
    wire [3:0] led_count = 4'd10 - health_value;  // Calculate how many LEDs to light
    
    led_health_indicator led_display (
        .clk(clk),
        .health({3'b000, led_count}),  // Using the 10-health value
        .led(led)
    );
    
endmodule

//--------------------------------------------------------------------------
// Support modules from ahmed-9apr.v
//--------------------------------------------------------------------------
module slowclock(
    input clk,
    input [31:0] m,
    output reg CLOCK
);
    reg [31:0] COUNT;

    initial begin
        CLOCK = 0;
        COUNT = 0;
    end

    always @ (posedge clk) begin
        if (COUNT == m) begin
            CLOCK <= ~CLOCK;
            COUNT <= 0;
        end
        else begin
            COUNT <= COUNT + 1;
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

//--------------------------------------------------------------------------
// Modified modules from health.v
//--------------------------------------------------------------------------
module seven_seg_controller(
    input clk,            
    input [6:0] number,   
    output reg [7:0] seg, 
    output reg [3:0] an   
);
    wire animation_clk;
    clk_divider cd(
        clk,
        animation_clk);   

    reg [1:0] digit;       
    reg [3:0] digit_value [3:0]; 

    // Calculate digit values to display
    always @(*) begin
        digit_value[0] = number / 10;           // Tens place
        digit_value[1] = number % 10;           // Ones place
        digit_value[2] = 0;                     // Not used
        digit_value[3] = 0;                     // Not used
    end

    always @(posedge animation_clk) begin
        digit <= digit + 1;
    end

    always @(*) begin
        // Display only on the two middle digits
        case(digit)
            2'b00: begin
                an  = 4'b1111;   // Leftmost digit off
                seg = 8'b11111111;
            end
            2'b01: begin
                an  = 4'b1011;   // Second digit (tens place)
                seg = seven_seg_display(digit_value[0]);
            end
            2'b10: begin
                an  = 4'b1101;   // Third digit (ones place)
                seg = seven_seg_display(digit_value[1]);
            end
            2'b11: begin
                an  = 4'b1111;   // Fourth digit off
                seg = 8'b11111111;
            end
            default: begin
                an  = 4'b1111;
                seg = 8'b11111111;
            end
        endcase
    end

    function [7:0] seven_seg_display;
        input [3:0] digit; 
        begin
            case(digit)
                4'b0000: seven_seg_display = 8'b11000000;  // Digit 0
                4'b0001: seven_seg_display = 8'b11111001;  // Digit 1
                4'b0010: seven_seg_display = 8'b10100100;  // Digit 2
                4'b0011: seven_seg_display = 8'b10110000;  // Digit 3
                4'b0100: seven_seg_display = 8'b10011001;  // Digit 4
                4'b0101: seven_seg_display = 8'b10010010;  // Digit 5
                4'b0110: seven_seg_display = 8'b10000010;  // Digit 6
                4'b0111: seven_seg_display = 8'b11111000;  // Digit 7
                4'b1000: seven_seg_display = 8'b10000000;  // Digit 8
                4'b1001: seven_seg_display = 8'b10010000;  // Digit 9
                default: seven_seg_display = 8'b11111111;  // Blank
            endcase
        end
    endfunction
endmodule

module clk_divider(
    input CLOCK,
    output reg SLOW_CLOCK3
);
    reg [18:0] COUNT3;

    initial begin
        SLOW_CLOCK3 = 0;
        COUNT3 = 0;
    end

    always @ (posedge CLOCK) begin
        if (COUNT3 == 149999) begin
            SLOW_CLOCK3 <= ~SLOW_CLOCK3;
            COUNT3 <= 0;
        end
        else begin
            COUNT3 <= COUNT3 + 1;
        end
    end
endmodule

module blink_clk_divider(
    input CLOCK,
    output reg SLOW_CLOCK
);
    reg [23:0] COUNT;
    
    initial begin
        SLOW_CLOCK = 0;
        COUNT = 0;
    end
    
    always @(posedge CLOCK) begin
        if (COUNT == 9999999) begin  // For 5Hz
            SLOW_CLOCK <= ~SLOW_CLOCK;
            COUNT <= 0;
        end
        else begin
            COUNT <= COUNT + 1;
        end
    end
endmodule

module led_health_indicator(
    input clk,
    input [6:0] health,
    output reg [7:0] led
);
    wire blink_clk;
    blink_clk_divider bcd(
        .CLOCK(clk),
        .SLOW_CLOCK(blink_clk)
    );
    
    reg blink_state;
    
    initial begin
        blink_state = 0;
    end
    
    always @(posedge blink_clk) begin
        blink_state <= ~blink_state;
    end
    
    always @(*) begin
        if (health == 4'd9) begin
            // Health critical (health=1) - 9 LEDs blink at 5Hz
            led = blink_state ? 8'b11111111 : 8'b00000000;
        end
        else begin
            // Normal health - LEDs light based on health
            case (health)
                4'd0: led = 8'b00000000;  // Health 10, 0 LEDs
                4'd1: led = 8'b00000001;  // Health 9, 1 LED
                4'd2: led = 8'b00000011;  // Health 8, 2 LEDs
                4'd3: led = 8'b00000111;  // Health 7, 3 LEDs
                4'd4: led = 8'b00001111;  // Health 6, 4 LEDs
                4'd5: led = 8'b00011111;  // Health 5, 5 LEDs
                4'd6: led = 8'b00111111;  // Health 4, 6 LEDs
                4'd7: led = 8'b01111111;  // Health 3, 7 LEDs
                4'd8: led = 8'b11111111;  // Health 2, 8 LEDs
                4'd10: led = 8'b11111111; // Health 0, all LEDs (fullly lit)
                default: led = 8'b00000000;
            endcase
        end
    end
endmodule