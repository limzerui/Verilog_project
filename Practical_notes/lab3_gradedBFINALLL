module top_level (
    input  wire         CLOCK_100MHz,
    input  wire [2:0]   SW,    
    input  wire         BTN_C,   
    input  wire         BTN_L,       
    input  wire         BTN_R,  
    input  wire         BTN_U,      
    output reg  [15:0]  LED,
    output wire [6:0]   SEG,        
    output wire [3:0]   AN       
);

    // Function to convert an 8-bit ASCII code to a 7-segment pattern    
    function [6:0] char_to_seg;
        input [7:0] ch;        
        begin
            case (ch)                
                8'h63: char_to_seg = 7'b0100111; // 'c'
                8'h6C: char_to_seg = 7'b1001111; // 'l'                
                8'h75: char_to_seg = 7'b1100011; // 'u'
                8'h72: char_to_seg = 7'b0101111; // 'r'                
                default: char_to_seg = 7'b1111111; // blank
            endcase        
        end
    endfunction

    // Clock dividers    
    wire clk_1Hz, clk_10Hz, clk_100Hz;
    clock_div_1Hz   u_div1   (.CLOCK_100MHz(CLOCK_100MHz), .CLOCK_1Hz(clk_1Hz));    
    clock_div_10Hz  u_div10  (.CLOCK_100MHz(CLOCK_100MHz), .CLOCK_10Hz(clk_10Hz));
    clock_div_100Hz u_div100 (.CLOCK_100MHz(CLOCK_100MHz), .CLOCK_100Hz(clk_100Hz));

    // LED counting logic (for LEDs 0 to 10)    
    reg [3:0] led_count = 0;
    reg flag = 0;    

    always @(posedge clk_1Hz) begin
        if (led_count < 11) begin            
            led_count <= led_count + 1;
            flag <= 0;       
        end 
        else begin
            led_count <= 11;            
            flag <= 1;
        end    
    end

    // State machine for the unlock sequence
    reg [2:0] state, next_state;    

    localparam S_WAIT_LED = 3'd0,
               S_STEP1    = 3'd1,               
               S_STEP2    = 3'd2,
               S_STEP3    = 3'd3,               
               S_STEP4    = 3'd4,
               S_STEP5    = 3'd5,               
               S_STEP6    = 3'd6,
               S_UNLOCK   = 3'd7;

    // Synchronous state register    
    always @(posedge CLOCK_100MHz) begin
        state <= next_state;    
    end

    // Next-state combinational logic
    always @* begin        
        next_state = state;
        case (state)            
            S_WAIT_LED: begin
                if (led_count == 11) next_state = S_STEP1;
            end            
            S_STEP1: begin
                if (BTN_C) next_state = S_STEP2;
            end            
            S_STEP2: begin
                if (BTN_L) next_state = S_STEP3;
            end            
            S_STEP3: begin
                if (BTN_U) next_state = S_STEP4;
            end            
            S_STEP4: begin
                if (BTN_R) next_state = S_STEP5;
            end            
            S_STEP5: begin
                if (BTN_C) next_state = S_STEP6;
            end
            S_STEP6: begin                
                if (BTN_L) next_state = S_UNLOCK;
            end
            S_UNLOCK: begin                
                next_state = S_UNLOCK;
            end            
            default: next_state = S_WAIT_LED;
        endcase    
    end

    // LED control logic
    always @* begin        
        LED = 16'b0;  

        if (!flag) begin            
            case (led_count)
                1:  LED[0]      = 1'b1;                
                2:  LED[1:0]    = 2'b11;
                3:  LED[2:0]    = 3'b111;                
                4:  LED[3:0]    = 4'b1111;
                5:  LED[4:0]    = 5'b11111;                
                6:  LED[5:0]    = 6'b111111;
                7:  LED[6:0]    = 7'b1111111;                
                8:  LED[7:0]    = 8'b11111111;
                9:  LED[8:0]    = 9'b111111111;                
                10: LED[9:0]    = 10'b1111111111;
                11: LED[10:0]   = 11'b11111111111;                
                default: LED[10:0] = 11'b0;
            endcase        
        end

        else begin            
            LED[10:3] = 8'b11111111;  

            if (SW[2] == 1'b1)
                LED[2:0] = {clk_100Hz, 2'b11};            
            else if (SW[1] == 1'b1)
                LED[2:0] = {1'b1, clk_10Hz, 1'b1};            
            else if (SW[0] == 1'b1)
                LED[2:0] = {2'b11, clk_1Hz};            
            else 
                LED[2:0] = 3'b111;          
        end

        if (state == S_UNLOCK)            
            LED[15] = 1'b1;
        else            
            LED[15] = 1'b0;
    end    

    // 7-segment display logic
    reg [3:0] an_reg;        
    reg [6:0] seg_reg;

    always @* begin            
        an_reg  = 4'b1111;     
        seg_reg = 7'b111_1111;  
        
        case (state)
            S_WAIT_LED: begin                    
                seg_reg = 7'b111_1111;
                an_reg  = 4'b1111;                
            end
            S_STEP1: begin                    
                seg_reg = char_to_seg(8'h63);  
                an_reg  = 4'b1110;                              
            end
            S_STEP2: begin                    
                seg_reg = char_to_seg(8'h6C);  
                an_reg  = 4'b1101;                             
            end
            S_STEP3: begin                    
                seg_reg = char_to_seg(8'h75);  
                an_reg  = 4'b1011;                             
            end
            S_STEP4: begin                    
                seg_reg = char_to_seg(8'h72);  
                an_reg  = 4'b0111;                              
            end
            S_STEP5: begin                    
                seg_reg = char_to_seg(8'h63);  
                an_reg  = 4'b1110;                              
            end
            S_STEP6: begin                    
                seg_reg = char_to_seg(8'h6C);  
                an_reg  = 4'b1101;                             
            end
            S_UNLOCK: begin                    
                seg_reg = char_to_seg(8'h63);  
                an_reg  = 4'b1110;                
            end
            default: begin                    
                seg_reg = 7'b111_1111;
                an_reg  = 4'b1111;
            end            
        endcase
    end    

    assign AN  = an_reg;        
    assign SEG = seg_reg;

endmodule

module clock_div_1Hz (
    input  CLOCK_100MHz,
    output reg CLOCK_1Hz
    
);
    reg [25:0] count = 0;
    always @(posedge CLOCK_100MHz) begin
        if (count == 50_000_000 - 1) begin
            count     <= 0;
            CLOCK_1Hz <= ~CLOCK_1Hz;
        end else begin
            count <= count + 1;
        end
    end
endmodule

module clock_div_10Hz (
    input  CLOCK_100MHz,
    output reg CLOCK_10Hz
);
    reg [22:0] count = 0;
    always @(posedge CLOCK_100MHz) begin
        if (count == 5_000_000 - 1) begin
            count      <= 0;
            CLOCK_10Hz <= ~CLOCK_10Hz;
        end else begin
            count <= count + 1;
        end
    end
endmodule

module clock_div_100Hz (
    input  CLOCK_100MHz,
    output reg CLOCK_100Hz
);
    reg [18:0] count = 0;
    always @(posedge CLOCK_100MHz) begin
        if (count == 500_000 - 1) begin
            count       <= 0;
            CLOCK_100Hz <= ~CLOCK_100Hz;
        end else begin
            count <= count + 1;
        end
    end
endmodule

