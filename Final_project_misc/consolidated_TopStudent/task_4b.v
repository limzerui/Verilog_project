`timescale 1ns / 1ps

module task_4b (
    input clk_mhz_6_25,
    input clk_khz_1,
    input btnU,
    input btnD,
    input btnC,
    input [6:0]x,
    input [5:0]y,
    input reset_task,
    output reg [15:0] oled_data
);
  
    reg [2:0] squareupflag;
    reg [2:0] squarecentreflag;
    reg [2:0] squaredownflag;
    reg [1:0] circleflag;
    
    localparam white = 16'd65535;
    localparam red = 16'd63488;
    localparam green = 16'd2016;
    localparam blue = 16'd31;
    localparam orange = 16'd64512;
    localparam black = 16'b0;

    initial begin
        squareupflag = 3'b0;
        squarecentreflag = 3'b0;
        squaredownflag = 3'b0;
        circleflag = 2'b0;
    end

    reg [7:0] debounce_counter;   
    reg debounce_active;         
    reg btnU_prev, btnC_prev, btnD_prev;

    always @ (posedge clk_khz_1) begin
        if (reset_task == 1) begin
            squareupflag = 3'b0;
            squarecentreflag = 3'b0;
            squaredownflag = 3'b0;
            circleflag = 2'b0;
        end else begin
            if (debounce_active) begin
                if (debounce_counter > 0)
                    debounce_counter <= debounce_counter - 1;
                else
                    debounce_active <= 0;
            end else begin         
                if (btnU && !btnU_prev) begin
                    if (squareupflag == 3'd5) begin
                        squareupflag <= squareupflag - 5;
                        end
                    else begin
                        squareupflag <= squareupflag + 1;
                    end
                    debounce_active <= 1;
                    debounce_counter <= 200;
                end
                
                if (btnC && !btnC_prev) begin
                    if (squarecentreflag == 3'd5) begin
                        squarecentreflag <= squarecentreflag - 5;
                    end else begin
                        squarecentreflag <= squarecentreflag + 1;
                    end
                    debounce_active <= 1;
                    debounce_counter <= 200;
                end
                
                if (btnD && !btnD_prev) begin
                    if (squaredownflag == 3'd5) begin
                        squaredownflag <= squaredownflag - 5;
                    end else begin
                        squaredownflag <= squaredownflag + 1;
                    end
                    debounce_active <= 1;
                    debounce_counter <= 200;
                end
            end
            btnU_prev <= btnU;
            btnC_prev <= btnC;
            btnD_prev <= btnD;
        end
    end

    always @ (posedge clk_mhz_6_25) begin
        if ((x>40) && (x<54) && (y>0) && (y<14)) begin
            case (squareupflag)
                0: oled_data <= white;
                1: oled_data <= red;
                2: oled_data <= green;
                3: oled_data <= blue;
                4: oled_data <= orange;
                default: oled_data <= black;
            endcase
        end else if ((x>40) && (x<54) && (y>15) && (y<29)) begin
            case (squarecentreflag)
                0: oled_data <= white;
                1: oled_data <= red;
                2: oled_data <= green;
                3: oled_data <= blue;
                4: oled_data <= orange;
                default: oled_data <= black;
            endcase
        end
        
        if ((x>40) && (x<54) && (y>30) && (y<44)) begin
            case (squaredownflag)
                0: oled_data <= white;
                1: oled_data <= red;
                2: oled_data <= green;
                3: oled_data <= blue;
                4: oled_data <= orange;
                default: oled_data <= black;
            endcase
        end
        
        if ( (((x - 47) * (x - 47)) + ((y - 52) * (y - 52))) < 43) begin
            if (squareupflag == 1 && squarecentreflag == 1 && squaredownflag == 1) begin
                oled_data = red;
            end else if (squareupflag == 4 && squarecentreflag == 4 && squaredownflag == 4)begin
                oled_data = orange;
            end else begin
                oled_data = black;
            end
        end else begin
            oled_data = black;
        end
    end
endmodule