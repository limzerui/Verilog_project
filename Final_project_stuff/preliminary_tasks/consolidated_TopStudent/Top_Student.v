`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: Lim Zerui
//  STUDENT B NAME: Ahmed Saheer
//  STUDENT C NAME: Celeste Tan
//  STUDENT D NAME: Heng Teng Yi
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input clk, btnU, btnD, btnL, btnR, btnC,
    input [15:0] sw,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an,
    output [7:0] JB
);    
    
    localparam pixel_index_width = $clog2(96*64);
    localparam x_width = $clog2(96);
    localparam y_width = $clog2(64);

    seven_seg_controller ssc1(clk, seg, an);
    
    wire [7:0] oledJ = JB;
    wire clk_mhz_6_25, clk_hz_45, clk_khz_1, clk_hz_5, clk_hz_10, clk_hz_9, clk_hz_1;
    
    clk_divider cd1 (clk, 3'd7, clk_mhz_6_25);
    clk_divider cd2 (clk, 32'd1111110, clk_hz_45);
    clk_divider cd3 (clk, 32'd49999, clk_khz_1);
    clk_divider cd4 (clk, 32'd49999999, clk_hz_1);
    clk_divider cd5 (clk, 32'd9999999, clk_hz_5);
    clk_divider cd6 (clk, 32'd5555555, clk_hz_9);
    clk_divider cd7 (clk, 32'd4999999, clk_hz_10);
    
    //Zerui: 0 3 4 12
    //Ahmed: 0 1 3 8 9 13
    //Celeste C: 0 1 3 5 9 14
    //Teng Yi D: 0 3 4 8 9 15
                
    localparam  TASK_NONE = 0,
                TASK_A = 1,
                TASK_B = 2,
                TASK_C = 3,
                TASK_D = 4;
                
    reg[2:0] sub_task = TASK_NONE;
    
    always @(posedge clk) begin
        case (sw)
            16'b0001_0000_0001_1001: sub_task <= TASK_A;
            16'b0010_0011_0000_1011: sub_task <= TASK_B;
            16'b0100_0010_0010_1011: sub_task <= TASK_C;
            16'b1000_0011_0001_1001: sub_task <= TASK_D;
            default: sub_task <= TASK_NONE;
        endcase
    end
    
    blinking_leds bl(sub_task, sw, clk_hz_5, clk_hz_1, clk_hz_10, clk_hz_9, led);
    
    wire[15:0] oled_data;
    wire frame_begin, sending_pixels, sample_pixel;
    wire [pixel_index_width-1:0] pixel_index;
    wire[x_width-1:0] x;
    wire[y_width-1:0] y;
    assign x = pixel_index % 96;
    assign y = pixel_index / 96;
    
    Oled_Display(   .clk(clk_mhz_6_25),
                    .reset(1'b0),
                    .pixel_data(oled_data),
                    .frame_begin(frame_begin),
                    .sending_pixels(sending_pixels),
                    .sample_pixel(sample_pixel),
                    .pixel_index(pixel_index),
                    .cs(oledJ[0]),
                    .sdin(oledJ[1]),
                    .sclk(oledJ[3]),
                    .d_cn(oledJ[4]),
                    .resn(oledJ[5]),
                    .vccen(oledJ[6]),
                    .pmoden(oledJ[7])
                );
    
    wire[15:0]  oled_data_t0,
            oled_data_t1, 
            oled_data_t2, 
            oled_data_t3, 
            oled_data_t4;
                
    wire    reset_t1,
            reset_t2,
            reset_t3,
            reset_t4;
    
    assign oled_data =  (sub_task == TASK_A) ? oled_data_t1 :
                        (sub_task == TASK_B) ? oled_data_t2 :
                        (sub_task == TASK_C) ? oled_data_t3 :
                        (sub_task == TASK_D) ? oled_data_t4 : oled_data_t0;
                        
    assign reset_t1 = sub_task != TASK_A;
    assign reset_t2 = sub_task != TASK_B;
    assign reset_t3 = sub_task != TASK_C;
    assign reset_t4 = sub_task != TASK_D;
    
    task_4a t1(
            clk_mhz_6_25,
            btnU,
            btnD, 
            btnL, 
            btnR, 
            btnC, 
            reset_t1, 
            x, 
            y, 
            oled_data_t1
    );
    
    task_4b t2(
        clk_mhz_6_25,
        clk_khz_1,
        btnU,
        btnD,
        btnC,
        x,
        y,
        reset_t2,
        oled_data_t2
    );
        
    task_4c t3 (.reset(reset_t3),
                .btnC(btnC),
                .clk_mhz_6_25(clk_mhz_6_25),
                .clk_hz_45(clk_hz_45),
                .y(y),
                .x(x),
                .oled_data(oled_data_t3)
    );

    task_4d t4( reset_t4, 
                clk, 
                clk_mhz_6_25,
                btnU,
                btnD, 
                btnL, 
                btnR, 
                y, 
                x, 
                frame_begin,
                oled_data_t4
    );
    
    default_number t0(  .clk_mhz_6_25(clk_mhz_6_25),
                        .x(x),
                        .y(y),
                        .oled_data(oled_data_t0));
endmodule

module clk_divider(input clk, input[31:0] threshold, output reg div_clk);
    reg [31:0] counter = 0;
    initial div_clk = 0;
    
    always @(posedge clk) begin
        counter <= (counter == threshold) ? 0 : counter + 1;
        div_clk <= (counter == threshold) ? ~div_clk : div_clk;
    end
endmodule

module seven_seg_controller(
    input clk,          
    output reg [7:0] seg,
    output reg [3:0] an  
);

  
  wire slow_clk;
  clk_divider cd (
        .clk(clk),
        .threshold(149999),
        .div_clk(slow_clk)
  );
  
  reg [1:0] digit;
  
  always @(posedge slow_clk) begin
    digit <= digit + 1;
  end
  
  always @(*) begin
    case(digit)
      2'b00: begin
        an  = 4'b1110;  
        seg = 8'b11111001;
      end
      2'b01: begin
        an  = 4'b1101;  
        seg = 8'b11111001;
      end
      2'b10: begin
        an  = 4'b1011;
        seg = 8'b00110000;
      end
      2'b11: begin
        an  = 4'b0111;
        seg = 8'b10010010;
      end
      default: begin
        an  = 4'b1111;
        seg = 8'b1111111;
      end
    endcase
  end
endmodule

module default_number (input clk_mhz_6_25,
                       input [6:0] x,
                       input [5:0] y,
                       output reg [15:0] oled_data);
                       
    wire [15:0] white_data = 16'b11111_111111_11111;
    
    always @ (posedge clk_mhz_6_25) begin
        if ((x >= 40) && (x <= 45) && (y >= 10) && (y <= 50))
            oled_data <= white_data;
        else if ((x >= 60) && (x <= 65) && (y >= 10) && (y <= 50))
            oled_data <= white_data;
        else
            oled_data <= {16{1'b0}};
    end
    
endmodule

module blinking_leds (input [2:0] sub_task, 
                      input [15:0] sw,
                      input clk_hz_a, clk_hz_b, clk_hz_c, clk_hz_d,
                      output [15:0] led);
    assign led = (sub_task == 1) ? {4'hF, {12{clk_hz_a}}} & sw :
                  (sub_task == 2) ? {4'hF, {12{clk_hz_b}}} & sw :
                  (sub_task == 3) ? {4'hF, {12{clk_hz_c}}} & sw :
                  (sub_task == 4) ? {4'hF, {12{clk_hz_d}}} & sw :
                  sw;
endmodule