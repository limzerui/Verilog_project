`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.02.2025 22:11:49
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main (
    input CLOCK,
    input btnL,
    input btnC,
    input btnR,
    input[2:0] sw,
    output[7:0] led,
    output[7:0] seg,
    output [3:0] an
    );
        
    parameter   STEP1 = 0,
                STEP2 = 1,
                STEP3 = 2,
                STEP4 = 3,
                STEP5 = 4,
                UNLOCKED = 5;
                
    parameter   SEG_L = 8'b11001111,
                SEG_C = 8'b10100111,
                SEG_R = 8'b10101111,
                AN_1 = 4'b1110,
                AN_2 = 4'b1101,
                AN_3 = 4'b1011,
                AN_4 = 4'b0111,
                AN_5 = 4'b1011;
                
    parameter   TICKS_FOR_PULSE_MS_500 = 50000000,
                TICKS_FOR_PULSE_MS_50 = 5000000,
                TICKS_FOR_PULSE_MS_5 = 500000,
                TICKS_FOR_PULSE_MS_860 = 86000000;
                
    parameter   LED_INIT = 0,
                LED_DONE = 1,
                MAX_LEDS = 7;
    
    reg [26:0] ticks_threshold;
    wire slow_clk;
    slow_clock sc1(CLOCK, ticks_threshold, slow_clk);
    
    reg led_state;
    reg [2:0] led_init_counter;
    reg [6:0] led_out;
    reg led_end;
    assign led[6:0] = led_out;
    assign led[7] = led_end;
    
    reg [2:0] seg_state;
    reg [7:0] seg_out;
    reg [3:0] an_out;
    assign seg = seg_out;
    assign an = an_out;
    
    initial begin
        ticks_threshold = TICKS_FOR_PULSE_MS_860;
        
        led_state = LED_INIT;
        led_init_counter = 0;
        led_out = 0;
        led_end = 0;
        
        seg_state = STEP1;
        seg_out = 8'b11111111;
        an_out = 4'b1111;
    end
    
    always @(posedge CLOCK) begin
        case (led_state)
            LED_INIT:
                begin
                    if (slow_clk) begin
                        led_out <= (led_out << 1) | 1'b1;
                        led_init_counter <= led_init_counter + 1;
                        led_state <= (led_init_counter == MAX_LEDS - 1) ? LED_DONE : led_state;
                    end
                end
            LED_DONE:
                begin
                    if (sw[2])
                        led_out[2:0] <= {(slow_clk ? ~led[2] : led[2]), 2'b11};
                    else if (sw[1])
                        led_out[2:0] <= {1'b1, (slow_clk ? ~led[1] : led[1]), 1'b1};
                    else if (sw[0])
                        led_out[2:0] <= {2'b11, (slow_clk ? ~led[0] : led[0])};
                    else
                        led_out[2:0] <= 3'b111;
                        
                    case (seg_state)
                        STEP1:
                            begin
                                seg_out <= SEG_L;
                                an_out <= AN_1;
                                seg_state <= btnL ? seg_state + 1 : seg_state;
                            end
                        STEP2:
                            begin
                                seg_out <= SEG_R;
                                an_out <= AN_2;
                                seg_state <= btnR ? seg_state + 1 : seg_state;
                            end
                        STEP3:
                            begin
                                seg_out <= SEG_L;
                                an_out <= AN_3;
                                seg_state <= btnL ? seg_state + 1 : seg_state;
                            end
                        STEP4:
                            begin
                                seg_out <= SEG_C;
                                an_out <= AN_4;
                                seg_state <= btnC ? seg_state + 1 : seg_state;
                            end
                        STEP5:
                            begin
                                seg_out <= SEG_L;
                                an_out <= AN_5;
                                seg_state <= btnL ? seg_state + 1 : seg_state;
                            end
                        UNLOCKED:
                            begin
                                seg_out <= SEG_L;
                                an_out <= AN_1;
                                led_end <= 1'b1; 
                            end
                    endcase
                end
        endcase
    end
    
    always @(sw) begin
        case (led_state)
            LED_DONE:
                begin
                    if (sw[2])
                        ticks_threshold <= TICKS_FOR_PULSE_MS_5;
                    else if (sw[1])
                        ticks_threshold <= TICKS_FOR_PULSE_MS_50;
                    else if (sw[0])
                        ticks_threshold <= TICKS_FOR_PULSE_MS_500;
                    else
                        ticks_threshold <= TICKS_FOR_PULSE_MS_5;
                end
        endcase
    end
    
endmodule

module slow_clock (
    input clk,
    input[26:0] ticks_threshold,
    output out
    );
    
    reg [26:0] slow_clk_counter;
    reg slow_clk;
    assign out = slow_clk;
    
    initial begin
        slow_clk_counter = 0;
        slow_clk = 0;
    end
    
    always @(posedge clk) begin        
        slow_clk_counter <= slow_clk_counter >= ticks_threshold ? 0: slow_clk_counter + 1;
        slow_clk <= slow_clk_counter == (ticks_threshold-1) ? 1'b1: 1'b0;
    end
        
endmodule