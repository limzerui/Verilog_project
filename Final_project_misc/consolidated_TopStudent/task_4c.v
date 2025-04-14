`timescale 1ns / 1ps

module task_4c (input reset, clk_mhz_6_25, clk_hz_45, btnC,
               input [5:0] y,
               input [6:0] x,
               output reg [15:0] oled_data);

    localparam pixel_index_width = $clog2(96*64);
    localparam x_width = $clog2(96);
    localparam y_width = $clog2(64);

    reg [x_width-1:0] x1_start = 85; // inclusive
    reg [x_width-1:0] x1_end = 95; // inclusive
    reg [y_width-1:0] y1_start = 0; // inclusive
    reg [y_width-1:0] y1_end = 10; // inclusive, to 63
    
    reg [x_width-1:0] x2_start = 85; // inclusive, to 41
    reg [x_width-1:0] x2_end = 95; // inclusive
    reg [y_width-1:0] y2_start = 53; // inclusive
    reg [y_width-1:0] y2_end = 63; // inclusive
    
    reg [x_width-1:0] x3_start = 41; // inclusive
    reg [x_width-1:0] x3_end = 51; // inclusive
    reg [y_width-1:0] y3_start = 53; // inclusive, to 26
    reg [y_width-1:0] y3_end = 63; // inclusive
    
    reg [x_width-1:0] x4_start = 41; // inclusive
    reg [x_width-1:0] x4_end = 51; // inclusive, to 72
    reg [y_width-1:0] y4_start = 26; // inclusive
    reg [y_width-1:0] y4_end = 36; // inclusive
    
    reg [x_width-1:0] x5_start = 60; // inclusive
    reg [x_width-1:0] x5_end = 70; // inclusive
    reg [y_width-1:0] y5_start = 26; // inclusive, to 0
    reg [y_width-1:0] y5_end = 36; // inclusive
    
    reg [x_width-1:0] x6_start = 60; // inclusive
    reg [x_width-1:0] x6_end = 70; // inclusive, to 95
    reg [y_width-1:0] y6_start = 0; // inclusive
    reg [y_width-1:0] y6_end = 10; // inclusive
    
    wire [15:0] orange_data = 16'b11111_101001_00000;
    initial oled_data = orange_data;
    
    reg [2:0] state = 3'b0;
    reg [1:0] slower_counter = 2'b0;
    
    always @ (posedge clk_mhz_6_25) begin
        if ((state >= 0) && (x >= x1_start) && (x <= x1_end) && (y >= y1_start) && (y <= y1_end)) begin
            oled_data <= orange_data;
        end else if ((state >= 2) && (x >= x2_start) && (x <= x2_end) && (y >= y2_start) && (y <= y2_end)) begin
            oled_data <= orange_data;
        end else if ((state >= 3) && (x >= x3_start) && (x <= x3_end) && (y >= y3_start) && (y <= y3_end)) begin
            oled_data <= orange_data;
        end else if ((state >= 4) && (x >= x4_start) && (x <= x4_end) && (y >= y4_start) && (y <= y4_end)) begin
            oled_data <= orange_data;
        end else if ((state >= 5) && (x >= x5_start) && (x <= x5_end) && (y >= y5_start) && (y <= y5_end)) begin
            oled_data <= orange_data;
        end else if ((state >= 6) && (x >= x6_start) && (x <= x6_end) && (y >= y6_start) && (y <= y6_end)) begin
            oled_data <= orange_data;
        end else begin
            oled_data <= {16{1'b0}};
        end
    end    
        
    always @ (posedge clk_hz_45) begin
        if (reset) begin
            state <= 3'd0;
            y1_end <= 10; // inclusive, to 63 
            x2_start <= 85; // inclusive, to 41
            y3_start <= 53; // inclusive, to 26
            x4_end <= 51; // inclusive, to 68
            y5_start <= 26; // inclusive, to 0
            x6_end <= 70; // inclusive, to 95
        end else begin
            case (state)
                3'd0: begin
                    if (btnC)
                        state <= 3'd1;
                end
                
                3'd1: begin // down
                    if (y1_end == 63)
                        state <= 3'd2;
                    else 
                        y1_end = y1_end + 1;
                end
                
                3'd2: begin // left
                    if (x2_start == 41)
                        state <= 3'd3;
                    else
                        x2_start <= x2_start - 1;
                end
                
                3'd3: begin // up slower
                    if (y3_start == 26) begin
                        state <= 3'd4;
                        slower_counter <= 2'd0;
                    end else if (slower_counter == 2'd2) begin
                        slower_counter <= 2'd0;
                        y3_start <= y3_start - 1;
                    end else begin
                        slower_counter <= slower_counter + 1;
                    end
                end
                
                3'd4: begin // right slower
                    if (x4_end == 70) begin
                        state <= 3'd5;
                        slower_counter <= 2'd0;                    
                    end else if (slower_counter == 2'd2) begin
                        slower_counter <= 2'd0;                        
                        x4_end <= x4_end + 1;
                    end else begin                        
                        slower_counter <= slower_counter + 1;
                    end                  
                end
                
                3'd5: begin // up slower                    
                    if (y5_start == 0) begin
                        state <= 3'd6;
                        slower_counter <= 2'd0;
                    end else if (slower_counter == 2'd2) begin
                        slower_counter <= 2'd0;
                        y5_start <= y5_start - 1;
                    end else begin
                        slower_counter <= slower_counter + 1;
                    end
                end
                
                3'd6: begin // right slower
                    if (x6_end == 95) begin                        
                        state <= 3'd7;
                        slower_counter <= 2'd0;                    
                    end else if (slower_counter == 2'd2) begin
                        slower_counter <= 2'd0;                        
                        x6_end <= x6_end + 1;
                    end else begin                        
                        slower_counter <= slower_counter + 1;
                    end
                end
                
                3'd7: begin
                    if (btnC) begin
                        state <= 3'd0;
                        y1_end <= 10; // inclusive, to 63 
                        x2_start <= 85; // inclusive, to 41
                        y3_start <= 53; // inclusive, to 26
                        x4_end <= 51; // inclusive, to 68
                        y5_start <= 26; // inclusive, to 0
                        x6_end <= 70; // inclusive, to 95
                    end
                end
            endcase
        end
    end
endmodule
