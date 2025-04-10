`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 00:01:47
// Design Name: 
// Module Name: Main
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


module Main(
    input clk, btnU, btnD, btnL, btnR, btnC,
    output [7:0]JB
    );
    
wire clk6p25m;
slowclock dut0 (clk, 32'd7, clk6p25m);
wire debouncingclock1;
slowclock dut1 (clk, 32'd100000, debouncingclock1); //1ms
wire debouncingclock2;
slowclock dut2 (clk, 32'd100000, debouncingclock2); //1ms
wire debouncingclock3;
slowclock dut3 (clk, 32'd100000, debouncingclock3); //1ms
wire debouncingclock4;
slowclock dut4 (clk, 32'd100000, debouncingclock4); //1ms
wire debouncingclock5;
slowclock dut5 (clk, 32'd100000, debouncingclock5); //1ms
wire debouncingclock6;
slowclock dut6 (clk, 32'd100000, debouncingclock6); //1ms
wire debouncingclock7;
slowclock dut7 (clk, 32'd100000, debouncingclock7); //1ms
wire debouncingclock8;
slowclock dut8 (clk, 32'd100000, debouncingclock8); //1ms

reg [15:0] oled_data;
wire frame_begin, sendingpixels, samplepixel;
wire [12:0] pixelindex;
Oled_Display oledunit1 (
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
    
wire [6:0] x;
wire [5:0] y;
xyconverter dutdut(pixelindex,x,y);   

wire [6:0] xmage;
wire [5:0] ymage;
wire [6:0] xgunman;
wire [5:0] ygunman;
wire [6:0] xswordman;
wire [5:0] yswordman;
wire [6:0] xfistman;
wire [5:0] yfistman;



wire [6:0] xmageprojectile;
wire [5:0] ymageprojectile;
wire [6:0] xgunmanprojectile;
wire [5:0] ygunmanprojectile;
wire [6:0] xswordmanprojectile;
wire [5:0] yswordmanprojectile;
wire [6:0] xfistmanprojectile;
wire [5:0] yfistmanprojectile;

wire [1:0] magedirection; //up, down, left, right
wire [1:0] gunmandirection;
wire [1:0] swordmandirection;
wire [1:0] fistmandirection;

wire [1:0] mageprojectiledirection; //up, down, left, right
wire [1:0] gunmanprojectiledirection;
wire [1:0] swordmanprojectiledirection;
wire [1:0] fistmanprojectiledirection;

wire mageprojectileactive;
wire gunmanprojectileactive;
wire swordmanprojectileactive;
wire fistmanprojectileactive;


// Collision detection signals
reg [6:0] test_x;
reg [5:0] test_y;
reg [1:0] character_to_move;
wire move_allowed;

// Character test positions
wire [6:0] mage_test_x;
wire [5:0] mage_test_y;
wire mage_test_active;
wire [6:0] gunman_test_x;
wire [5:0] gunman_test_y; 
wire gunman_test_active;
wire [6:0] swordman_test_x;
wire [5:0] swordman_test_y;
wire swordman_test_active;
wire [6:0] fistman_test_x;
wire [5:0] fistman_test_y;
wire fistman_test_active;

// Character hit signals
wire mage_hit, gunman_hit, swordman_hit, fistman_hit;

localparam CHARACTER_WIDTH = 20;
localparam CHARACTER_HEIGHT = 20;
localparam PROJECTILE_WIDTH = 8;
localparam PROJECTILE_HEIGHT = 8;

// Instantiate the collision detector
CollisionDetector collision_detector (
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    
    .xmageprojectile(xmageprojectile),
    .ymageprojectile(ymageprojectile),
    .xgunmanprojectile(xgunmanprojectile),
    .ygunmanprojectile(ygunmanprojectile),
    .xswordmanprojectile(xswordmanprojectile),
    .yswordmanprojectile(yswordmanprojectile),
    .xfistmanprojectile(xfistmanprojectile),
    .yfistmanprojectile(yfistmanprojectile),
    
    .mageprojectileactive(mageprojectileactive),
    .gunmanprojectileactive(gunmanprojectileactive),
    .swordmanprojectileactive(swordmanprojectileactive),
    .fistmanprojectileactive(fistmanprojectileactive),
    
    .CHARACTER_WIDTH(CHARACTER_WIDTH),
    .CHARACTER_HEIGHT(CHARACTER_HEIGHT),
    .PROJECTILE_WIDTH(PROJECTILE_WIDTH),
    .PROJECTILE_HEIGHT(PROJECTILE_HEIGHT),
    
    .test_x(test_x),
    .test_y(test_y),
    .character_to_move(character_to_move),
    
    .move_allowed(move_allowed),
    .mage_hit(mage_hit),
    .gunman_hit(gunman_hit),
    .swordman_hit(swordman_hit),
    .fistman_hit(fistman_hit)
);

// Collision detection multiplexer (add this before the character movement modules)
always @(*) begin
    if (mage_test_active) begin
        test_x = mage_test_x;
        test_y = mage_test_y;
        character_to_move = 2'b00;
    end
    else if (gunman_test_active) begin
        test_x = gunman_test_x;
        test_y = gunman_test_y;
        character_to_move = 2'b01;
    end
    else if (swordman_test_active) begin
        test_x = swordman_test_x;
        test_y = swordman_test_y;
        character_to_move = 2'b10;
    end
    else if (fistman_test_active) begin
        test_x = fistman_test_x;
        test_y = fistman_test_y;
        character_to_move = 2'b11;
    end
    else begin
        test_x = 0;
        test_y = 0;
        character_to_move = 2'b00;
    end
end

charactermovement #(
    .startx(10),
    .starty(10)
) mage1 (
    .debouncingclock(debouncingclock1),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .wxcharacter(xmage),
    .wycharacter(ymage),
    .move_allowed(move_allowed),    
    .chardirection(magedirection),
    .xcharacter(xmage),
    .ycharacter(ymage),
    .test_x(mage_test_x),
    .test_y(mage_test_y),
    .test_active(mage_test_active)
);

charactermovement #(
    .startx(10),
    .starty(40)
) gunman1 (
    .debouncingclock(debouncingclock2),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .wxcharacter(xgunman),
    .wycharacter(ygunman),
    .move_allowed(move_allowed),
    .chardirection(gunmandirection),
    .xcharacter(xgunman),
    .ycharacter(ygunman),
    .test_x(gunman_test_x),
    .test_y(gunman_test_y),
    .test_active(gunman_test_active)
);

charactermovement #(
    .startx(40),
    .starty(10)
) swordman1 (
    .debouncingclock(debouncingclock3),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .wxcharacter(xswordman),
    .wycharacter(yswordman),
    .move_allowed(move_allowed),
    .chardirection(swordmandirection),
    .xcharacter(xswordman),
    .ycharacter(yswordman),
    .test_x(swordman_test_x),
    .test_y(swordman_test_y),
    .test_active(swordman_test_active)
);

charactermovement #(
    .startx(40),
    .starty(40)
) fistman1 (
    .debouncingclock(debouncingclock4),
    .btnU(btnU),
    .btnD(btnD),
    .btnL(btnL),
    .btnR(btnR),
    .wxcharacter(xfistman),
    .wycharacter(yfistman),
    .move_allowed(move_allowed),
    .chardirection(fistmandirection),
    .xcharacter(xfistman),
    .ycharacter(yfistman),
    .test_x(fistman_test_x),
    .test_y(fistman_test_y),
    .test_active(fistman_test_active)
);

projectilemovement mage2(
    .btnC(btnC),
    .debouncingclock(debouncingclock5),
    .chardirection(magedirection),
    .xcharacter(xmage),
    .ycharacter(ymage),
    .projectiledirection(mageprojectiledirection),
    .xprojectile(xmageprojectile),
    .yprojectile(ymageprojectile),
    .projectileactive(mageprojectileactive)
);

projectilemovement gunman2(
    .btnC(btnC),
    .debouncingclock(debouncingclock6),
    .chardirection(gunmandirection),
    .xcharacter(xgunman),
    .ycharacter(ygunman),
    .projectiledirection(gunmanprojectiledirection),
    .xprojectile(xgunmanprojectile),
    .yprojectile(ygunmanprojectile),
    .projectileactive(gunmanprojectileactive)
);

projectilemovement swordman2(
    .btnC(btnC),
    .debouncingclock(debouncingclock7),
    .chardirection(swordmandirection),
    .xcharacter(xswordman),
    .ycharacter(yswordman),
    .projectiledirection(swordmanprojectiledirection),
    .xprojectile(xswordmanprojectile),
    .yprojectile(yswordmanprojectile),
    .projectileactive(swordmanprojectileactive)
);

projectilemovement fistman2(
    .btnC(btnC),
    .debouncingclock(debouncingclock8),
    .chardirection(fistmandirection),
    .xcharacter(xfistman),
    .ycharacter(yfistman),
    .projectiledirection(fistmanprojectiledirection),
    .xprojectile(xfistmanprojectile),
    .yprojectile(yfistmanprojectile),
    .projectileactive(fistmanprojectileactive)
);



wire [15:0] magedata;
wire [15:0] gunmandata;
wire [15:0] swordmandata;
wire [15:0] fistmandata;
wire [15:0] mageprojectiledata;
wire [15:0] gunmanprojectiledata;
wire [15:0] swordmanprojectiledata;
wire [15:0] fistmanprojectiledata;
wire [15:0] battlearenadata;

mage_bram char1 (
    .clk(clk6p25m),
    .x(x - xmage),
    .y(y - ymage),
    .magedirection(magedirection),
    .pixel_data(magedata)
);

gunman_bram char2 (
    .clk(clk6p25m),
    .x(x - xgunman),
    .y(y - ygunman),
    .gunmandirection(gunmandirection),
    .pixel_data(gunmandata)
);

swordman_bram char3 (
    .clk(clk6p25m),
    .x(x - xswordman),
    .y(y - yswordman),
    .swordmandirection(swordmandirection),
    .pixel_data(swordmandata)
);

fistman_bram char4 (
    .clk(clk6p25m),
    .x(x - xfistman),
    .y(y - yfistman),
    .fistmandirection(fistmandirection),
    .pixel_data(fistmandata)
);

mageprojectile_bram proj1 (
    .clk(clk6p25m),
    .x(x-xmageprojectile),
    .y(y-ymageprojectile),
    .mageprojectiledirection(mageprojectiledirection),
    .pixel_data(mageprojectiledata)
);

gunmanprojectile_bram proj2 (
    .clk(clk6p25m),
    .x(x - xgunmanprojectile),
    .y(y - ygunmanprojectile),
    .gunmanprojectiledirection(gunmanprojectiledirection),
    .pixel_data(gunmanprojectiledata)
);

swordmanprojectile_bram proj3 (
    .clk(clk6p25m),
    .x(x - xswordmanprojectile),
    .y(y - yswordmanprojectile),
    .swordmanprojectiledirection(swordmanprojectiledirection),
    .pixel_data(swordmanprojectiledata)
);

fistmanprojectile_bram proj4 (
    .clk(clk6p25m),
    .x(x - xfistmanprojectile),
    .y(y - yfistmanprojectile),
    .fistmanprojectiledirection(fistmanprojectiledirection),
    .pixel_data(fistmanprojectiledata)
);

battlearena_bram battlearena (
    .clk(clk6p25m),
    .x(x),
    .y(y),
    .pixel_data(battlearenadata)
);

always @(clk) begin
    if(magedata != 16'b0000000000000001 && magedata !=16'b0)
        oled_data = magedata;
    else if (gunmandata != 16'b0000000000000001 && gunmandata != 16'b0)
        oled_data = gunmandata;
    else if (swordmandata != 16'b0000000000000001 && swordmandata != 16'b0)
        oled_data = swordmandata;
    else if (fistmandata != 16'b0000000000000001 && fistmandata != 16'b0)
        oled_data = fistmandata;
    else if (mageprojectileactive != 1'b0 && mageprojectiledata != 16'b0000000000000001 && mageprojectiledata != 18'b0)
         oled_data = mageprojectiledata;
    else if (swordmanprojectileactive != 1'b0 && swordmanprojectiledata != 16'b0000000000000001 && swordmanprojectiledata != 18'b0)
         oled_data = swordmanprojectiledata;
    else if (gunmanprojectileactive != 1'b0 && gunmanprojectiledata != 16'b0000000000000001 && gunmanprojectiledata != 18'b0)
         oled_data = gunmanprojectiledata;
    else if (fistmanprojectileactive != 1'b0 && fistmanprojectiledata != 16'b0000000000000001 && fistmanprojectiledata != 18'b0)
         oled_data = fistmanprojectiledata;
    else
        oled_data = battlearenadata;  // Default black background
end
    
endmodule

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

module xyconverter (
    input [12:0] pixelindex, 
    output [6:0] x,
    output [5:0] y
    );
    assign x = pixelindex % 96;
    assign y = pixelindex / 96;
endmodule