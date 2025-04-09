module top_module(
    input clk,              // Board clock
    input [5:0] sw,         // Switches: sw[5:4] for character, sw[3:0] for health
    input master,
    output [7:0] seg,       // 7-segment display segments
    output [3:0] an,        // 7-segment display anodes
    output [15:0] led,       // LEDs for health indication
    output [7:0] JB         // PMOD JB for OLED
);
    

    wire [6:0] this_player_packet = {1'b0, sw[5:4], sw[3:0]};
    wire [6:0] received_packet = 7'b0000000;
    
    // Instantiate the game_character_health module
    game_character_health gch(
        .clk(clk),
        .this_player_packet(this_player_packet),
        .received_packet(received_packet),
        .master(master),
        .seg(seg),
        .an(an),
        .led(led),
        .JB(JB)
    );
    
endmodule

module game_character_health(
    input clk,
    input [6:0] this_player_packet,  // Data from this player
    input [6:0] received_packet,     // Data received from other player
    input master,                   // Selection bit (1=master, 0=slave)
    output [7:0] seg,               // 7-segment display
    output [3:0] an,                // 7-segment display anode
    output [15:0] led,              // LED outputs
    output [7:0] JB                 // PMOD JB ports for OLED
);
    
    // Select which packet to use based on master bit
    wire [6:0] active_packet = master ? this_player_packet : received_packet;
    
    // Extract fields from active packet
    wire [1:0] character_type = active_packet[5:4];  // Character type (2 bits)
    wire [3:0] health_value = active_packet[3:0];    // Health value (4 bits, 0-10)

    wire clk6p25m;
    generic_timer #(.COUNT_MAX(7))
    oled_clock (
        .clk(clk),
        .clk_out(clk6p25m)
    );
    
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
    
    seven_seg_controller health_display (
        .clk(clk),
        .number({3'b000, health_value}),  // Convert 4-bit health to 7-bit number
        .seg(seg),
        .an(an)
    );
    
    wire [3:0] led_count = 4'd10 - health_value;  // Calculate how many LEDs to light
    
    led_health_indicator led_display (
        .clk(clk),
        .health(health_value),  // Using the 10-health value
        .led(led)
    );
    
endmodule


module xyconverter(
    input [12:0] pixelindex, 
    output [6:0] x,
    output [5:0] y
);
    assign x = pixelindex % 96;
    assign y = pixelindex / 96;
endmodule

module seven_seg_controller(
    input clk,            
    input [6:0] number,   
    output reg [7:0] seg, 
    output reg [3:0] an   
);
    wire animation_clk;
    generic_timer #(.COUNT_MAX(149999) ) seven_seg_timer (
    .clk(clk),
    .clk_out(animation_clk)
);

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

module led_health_indicator(
    input clk,
    input [3:0] health,        // Changed to 4-bit (0-10)
    output reg [15:0] led      // Expanded to 16 LEDs
);
    wire blink_clk;
    generic_timer #(
        .COUNT_MAX(9999999)    // For 5Hz with 100MHz clock
    ) blink_timer (
        .clk(clk),
        .clk_out(blink_clk)
    );
    
    reg blink_state;
    
    initial begin
        blink_state = 0;
    end
    
    always @(posedge blink_clk) begin
        blink_state <= ~blink_state;
    end
    
    always @(*) begin
        if (health == 4'd0) begin
            // Health 0 - all LEDs off
            led = 16'h0000;
        end
        else if (health == 4'd1) begin
            // Health 1 - blink all LEDs
            led = blink_state ? 16'hFFFF : 16'h0000;
        end
        else begin
            // Show number of LEDs equal to health value
            case (health)
                4'd2:  led = 16'h0003;    // 2 LEDs
                4'd3:  led = 16'h0007;    // 3 LEDs
                4'd4:  led = 16'h000F;    // 4 LEDs
                4'd5:  led = 16'h001F;    // 5 LEDs
                4'd6:  led = 16'h003F;    // 6 LEDs
                4'd7:  led = 16'h007F;    // 7 LEDs
                4'd8:  led = 16'h00FF;    // 8 LEDs
                4'd9:  led = 16'h01FF;    // 9 LEDs
                4'd10: led = 16'h03FF;    // 10 LEDs
                default: led = 16'h0000;
            endcase
        end
    end
endmodule