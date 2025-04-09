module top_module(
    input clk,           
    output [7:0] seg,   
    output [3:0] an,
    output [7:0] led    // Add LED outputs
);

    reg [6:0] number;   
    
    initial begin
        number = 80;     
    end

    seven_seg_controller ssc (
        .clk(clk),
        .number(number),
        .seg(seg),
        .an(an)
    );
    
    // Add LED controller
    led_health_indicator lhi (
        .clk(clk),
        .health(number),
        .led(led)
    );

endmodule

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
    digit_value[0] = number / 100;          
    digit_value[1] = (number % 100) / 10;  
    digit_value[2] = number % 10;         
    digit_value[3] = 0; // Not used
  end

  always @(posedge animation_clk) begin
    digit <= digit + 1;
  end

  always @(*) begin
    if (number == 100) begin
      // For number = 100, display "100" on leftmost 3 digits
      case(digit)
        2'b00: begin
          an  = 4'b0111;   // Leftmost digit (displays "1")
          seg = seven_seg_display(digit_value[0]);
        end
        2'b01: begin
          an  = 4'b1011;   // Second digit (displays "0")
          seg = seven_seg_display(digit_value[1]);
        end
        2'b10: begin
          an  = 4'b1101;   // Third digit (displays "0")
          seg = seven_seg_display(digit_value[2]);
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
    else begin
      // For all other numbers, display only on the two middle digits
      case(digit)
        2'b00: begin
          an  = 4'b1111;   // Leftmost digit off
          seg = 8'b11111111;
        end
        2'b01: begin
          an  = 4'b1011;   // Second digit (tens place)
          seg = seven_seg_display(digit_value[1]);
        end
        2'b10: begin
          an  = 4'b1101;   // Third digit (ones place)
          seg = seven_seg_display(digit_value[2]);
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
        if (COUNT3 == 149999 ) begin
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
    
    // For 5Hz with 100MHz input clock: 100,000,000 / (2*5) = 10,000,000
    // For simulation or lower frequency base clocks, adjust accordingly
    reg [23:0] COUNT;
    
    initial begin
        SLOW_CLOCK = 0;
        COUNT = 0;
    end
    
    always @(posedge CLOCK) begin
        if (COUNT == 9999999) begin  // For 5Hz (adjust if your base clock differs)
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
    
    // 5Hz clock for blinking when health < 20
    wire blink_clk;
    blink_clk_divider bcd(
        .CLOCK(clk),
        .SLOW_CLOCK(blink_clk)
    );
    
    reg blink_state;
    
    // Initialize blink state
    initial begin
        blink_state = 0;
    end
    
    // Update blink state at 5Hz
    always @(posedge blink_clk) begin
        blink_state <= ~blink_state;
    end
    
    // LED control based on health
    always @(*) begin
        if (health < 20) begin
            // Health critical - all LEDs blink at 5Hz
            led = blink_state ? 8'b11111111 : 8'b00000000;
        end
        else begin
            // Normal health - LEDs light based on health decrease
            case ((100 - health) / 10)
                0: led = 8'b00000000;  // 100 health
                1: led = 8'b00000001;  // 90 health
                2: led = 8'b00000011;  // 80 health
                3: led = 8'b00000111;  // 70 health
                4: led = 8'b00001111;  // 60 health
                5: led = 8'b00011111;  // 50 health
                6: led = 8'b00111111;  // 40 health
                7: led = 8'b01111111;  // 30 health
                8: led = 8'b11111111;  // 20 health
                default: led = 8'b00000000;
            endcase
        end
    end
    
endmodule
