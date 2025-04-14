`timescale 1ns / 1ps

module task_4d(
    input reset, clk, pixel_clk, btnU, btnD, btnL, btnR,
    input [$clog2(64)-1:0] y,
    input [$clog2(96)-1:0] x,
    input frame_begin,
    output reg [15:0] oled_data
);
    
    localparam x_width = $clog2(96);
    localparam y_width = $clog2(64);
    
    localparam green_l = 10, green_h = 10, red_l = 30, red_h = 30;
    reg [x_width-1:0] green_x = 0, red_x = 66, buffer_green_x = 0;
    reg [y_width-1:0] green_y = 54, red_y = 0, buffer_green_y = 54;
    
    always @(posedge frame_begin) begin
        if (reset) begin
            green_x <= 0;
            green_y <= 54;
        end else begin
            green_x <= buffer_green_x;
            green_y <= buffer_green_y;
        end
    end
    
    always @(posedge pixel_clk) begin
        if (x <= green_x + green_l - 1 && x >= green_x && y <= green_y + green_h - 1 && y >= green_y) begin
            oled_data <= 16'b00000_111111_00000;
        end else if (x <= red_x + red_l - 1 && x >= red_x && y <= red_y + red_h - 1 && y >= red_y) begin
            oled_data <= 16'b11111_000000_00000;
        end else begin
            oled_data <= 16'b00000_000000_00000;
        end
    end
    
    localparam  NO_MOVE = 0,
                LEFT = 1,
                RIGHT = 2,
                UP = 3, 
                DOWN = 4;

    reg [3:0] direction = NO_MOVE;
    reg [3:0] prev_btn_state;
    
    wire movement_clk;
    clk_divider cd2(clk, 1666666, movement_clk);
    
    always @(posedge clk) begin
        prev_btn_state <= {btnL, btnR, btnU, btnD};
        
        if (reset) begin
            direction <= NO_MOVE;
        end else if (prev_btn_state[3] != btnL && btnL) begin
            direction <= LEFT;
        end else if (prev_btn_state[2] != btnR && btnR) begin
            direction <= RIGHT;
        end else if (prev_btn_state[1] != btnU && btnU) begin
            direction <= UP;
        end else if (prev_btn_state[0] != btnD && btnD) begin
            direction <= DOWN;
        end else if (btnL) begin
            direction <= LEFT;
        end else if (btnR) begin
            direction <= RIGHT;
        end else if (btnU) begin
            direction <= UP;
        end else if (btnD) begin
            direction <= DOWN;
        end        
    end

    always @(posedge movement_clk) begin
        if (reset) begin
            buffer_green_x <= 0;
            buffer_green_y <= 54;
        end else begin 
            case (direction)
                UP: begin
                    if (buffer_green_y > 0 && (buffer_green_x + green_l <= red_x || buffer_green_y > red_y + red_h)) begin
                        buffer_green_y <= buffer_green_y - 1;
                    end
                end
                DOWN: begin
                    if (buffer_green_y + green_h - 1 < 63) begin
                        buffer_green_y <= buffer_green_y + 1;
                    end
                end
                LEFT: begin
                    if (buffer_green_x > 0) begin
                        buffer_green_x <= buffer_green_x - 1;
                    end
                end
                RIGHT: begin
                    if (buffer_green_x + green_l - 1 < 95 && (buffer_green_x + green_l < red_x || buffer_green_y >= red_y + red_h)) begin
                        buffer_green_x <= buffer_green_x + 1;
                    end
                end
            endcase 
        end
    end

endmodule