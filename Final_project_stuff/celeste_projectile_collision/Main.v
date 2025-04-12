`timescale 1ns / 1ps

module Main(
    input [15:0] sw,
    input clk, btnU, btnD, btnL, btnR, btnC,
    input PS2Data, PS2Clk,
    input [7:0] JXADC,
    output [7:0] JA, [7:0] JB,
    output Hsync, Vsync,
    output [3:0] vgaRed, vgaGreen, vgaBlue,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
    
wire clk6p25m;
flexible_clock_divider dut0 (clk, 32'd7, clk6p25m);

wire debouncingclock;
flexible_clock_divider dut1 (clk, 32'd100000, debouncingclock); //1ms
wire debouncingclock2;
flexible_clock_divider dut2 (clk, 32'd100000, debouncingclock2); //1ms
wire debouncingclock3;
flexible_clock_divider dut3 (clk, 32'd100000, debouncingclock3); //1ms
wire debouncingclock4;
flexible_clock_divider dut4 (clk, 32'd100000, debouncingclock4); //1ms

wire debouncingclock5;
flexible_clock_divider dut5 (clk, 32'd49999, debouncingclock5); //1ms
wire debouncingclock6;
flexible_clock_divider dut6 (clk, 32'd49999, debouncingclock6); //1ms
wire debouncingclock7;
flexible_clock_divider dut7 (clk, 32'd49999, debouncingclock7); //1ms
wire debouncingclock8;
flexible_clock_divider dut8 (clk, 32'd49999, debouncingclock8); //1ms
wire debouncingclock9;
flexible_clock_divider dut9 (clk, 32'd49999, debouncingclock9);  //1ms

reg [17:0] oled_data;
wire frame_begin, sendingpixels, samplepixel;

wire [9:0] x;
wire [9:0] y; 
wire [9:0] xnext;
wire [9:0] ynext;
wire new_frame_next;
wire clk_mhz_25;

pixel_clk sc1(clk, clk_mhz_25);
vga_display vd1(
    clk_mhz_25, 
    oled_data, 
    y,
    x, 
    ynext, 
    xnext, 
    new_frame_next, Hsync, Vsync, 
    vgaRed, vgaGreen, vgaBlue
);

wire [9:0] xmage;
wire [9:0] ymage;
wire [9:0] xgunman;
wire [9:0] ygunman;
wire [9:0] xswordman;
wire [9:0] yswordman;
wire [9:0] xfistman;
wire [9:0] yfistman;

wire [9:0] xmageprojectile;
wire [9:0] ymageprojectile;
wire [9:0] xgunmanprojectile;
wire [9:0] ygunmanprojectile;
wire [9:0] xswordmanprojectile;
wire [9:0] yswordmanprojectile;
wire [9:0] xfistmanprojectile;
wire [9:0] yfistmanprojectile;

wire [9:0] ult_xmageprojectile;
wire [9:0] ult_ymageprojectile;
wire [9:0] ult_xgunmanprojectile;
wire [9:0] ult_ygunmanprojectile;
wire [9:0] ult_xswordmanprojectile;
wire [9:0] ult_yswordmanprojectile;
wire [9:0] ult_xfistmanprojectile;
wire [9:0] ult_yfistmanprojectile;

wire [1:0] magedirection; //up, down, left, right
wire [1:0] gunmandirection;
wire [1:0] swordmandirection;
wire [1:0] fistmandirection;

wire [1:0] mageprojectiledirection; //up, down, left, right
wire [1:0] gunmanprojectiledirection;
wire [1:0] swordmanprojectiledirection;
wire [1:0] fistmanprojectiledirection;

wire [1:0] ult_mageprojectiledirection; //up, down, left, right
wire [1:0] ult_gunmanprojectiledirection;
wire [1:0] ult_swordmanprojectiledirection;
wire [1:0] ult_fistmanprojectiledirection;

wire mageprojectileactive;
wire gunmanprojectileactive;
wire swordmanprojectileactive;
wire fistmanprojectileactive;

wire ult_mageprojectileactive;
wire ult_gunmanprojectileactive;
wire ult_swordmanprojectileactive;
wire ult_fistmanprojectileactive;

// Character hit signals
wire [3:0] collisions0;
wire [3:0] collisions1;
wire [3:0] collisions2;
wire [3:0] collisions3;
wire [3:0] ult_collisions0;
wire [3:0] ult_collisions1;
wire [3:0] ult_collisions2;
wire [3:0] ult_collisions3;

wire [5:0] healthmage;
wire [5:0] healthgunman;
wire [5:0] healthswordman;
wire [5:0] healthfistman;

localparam CHARACTER_WIDTH = 20;
localparam CHARACTER_HEIGHT = 20;
localparam PROJECTILE_WIDTH = 8;
localparam PROJECTILE_HEIGHT = 8;

wire [9:0] raw_keyboard_data;
wire [19:0] part_raw_keyboard_data;
wire [19:0] all_keyboard_data;
wire [23:0] all_health_data;
wire [11:0] other_health_data;
wire master = sw[15];

assign all_health_data = {  healthfistman,
                            healthswordman,
                            healthgunman,
                            healthmage};

wire p1_clear_ult, p2_clear_ult;

assign all_keyboard_data = {
    (healthfistman[3:0] == 0 ? 3'b000 : part_raw_keyboard_data[19:15]),
    (healthswordman[3:0] == 0 ? 3'b000 : part_raw_keyboard_data[14:10]),
    (healthgunman[3:0] == 0 ? 3'b000 : part_raw_keyboard_data[9:5]),
    (healthmage[3:0] == 0 ? 3'b000 : part_raw_keyboard_data[4:0])};

//for master: sends health data for other 2 players, receives keyboard data for other 2 players
//for slave, sends keyboard for 2 players, receives health data for 2 players from master
get_required_data grd1(
    .clk(clk),
    .PS2Data(PS2Data),
    .PS2Clk(PS2Clk),
    .master(master),
    .sw(sw),
    .health_data_in(all_health_data[23:12]),
    .JXADC(JXADC),
    .JA(JA),
    .other_health_data(other_health_data),
    .raw_keyboard_data(raw_keyboard_data),
    .all_keyboard_data(part_raw_keyboard_data),
    .p1_clear_ult(p1_clear_ult),
    .p2_clear_ult(p2_clear_ult)
);

//handles health display, ult meter output (& logic, oops) and OLED display
display_character_and_health ch1(
    .clk(clk),
    .keyboard_data(raw_keyboard_data),
    .health_data(master ? all_health_data[11:0] : other_health_data),
    .seg(seg),
    .an(an),
    .JB(JB),
    .led(led),
    .p1_clear_ult(p1_clear_ult),
    .p2_clear_ult(p2_clear_ult)
);

charactermovement #(
    .startx(60),
    .starty(40)
) mage1 (
    .debouncingclock(debouncingclock),
    .btnU(all_keyboard_data[2:0] == 3'b001),
    .btnD(all_keyboard_data[2:0] == 3'b011),
    .btnL(all_keyboard_data[2:0] == 3'b010),
    .btnR(all_keyboard_data[2:0] == 3'b100),
    .wxcharacter(xmage),
    .wycharacter(ymage),
    .wxother1(xgunman),
    .wyother1(ygunman),
    .wxother2(xfistman),
    .wyother2(yfistman),
    .wxother3(xswordman),
    .wyother3(yswordman),
    .chardirection(magedirection),
    .xcharacter(xmage),
    .ycharacter(ymage),
    .reset(btnC)
);

charactermovement #(
    .startx(240),
    .starty(40)
) gunman1 (
    .debouncingclock(debouncingclock2),
    .btnU(all_keyboard_data[7:5] == 3'b001),
    .btnD(all_keyboard_data[7:5] == 3'b011),
    .btnL(all_keyboard_data[7:5] == 3'b010),
    .btnR(all_keyboard_data[7:5] == 3'b100),
    .wxcharacter(xgunman),
    .wycharacter(ygunman),
    .wxother1(xmage),
    .wyother1(ymage),
    .wxother2(xfistman),
    .wyother2(yfistman),
    .wxother3(xswordman),
    .wyother3(yswordman),
    .chardirection(gunmandirection),
    .xcharacter(xgunman),
    .ycharacter(ygunman),
    .reset(btnC)
);

charactermovement #(
    .startx(60),
    .starty(180)
) swordman1 (
    .debouncingclock(debouncingclock3),
    .btnU(all_keyboard_data[12:10] == 3'b001),
    .btnD(all_keyboard_data[12:10] == 3'b011),
    .btnL(all_keyboard_data[12:10] == 3'b010),
    .btnR(all_keyboard_data[12:10] == 3'b100),
    .wxcharacter(xswordman),
    .wycharacter(yswordman),
    .wxother1(xgunman),
    .wyother1(ygunman),
    .wxother2(xfistman),
    .wyother2(yfistman),
    .wxother3(xmage),
    .wyother3(ymage),
    .chardirection(swordmandirection),
    .xcharacter(xswordman),
    .ycharacter(yswordman),
    .reset(btnC)
);

charactermovement #(
    .startx(240),
    .starty(180)
) fistman1 (
    .debouncingclock(debouncingclock4),
    .btnU(all_keyboard_data[17:15] == 3'b001),
    .btnD(all_keyboard_data[17:15] == 3'b011),
    .btnL(all_keyboard_data[17:15] == 3'b010),
    .btnR(all_keyboard_data[17:15] == 3'b100),
    .wxcharacter(xfistman),
    .wycharacter(yfistman),
    .wxother1(xgunman),
    .wyother1(ygunman),
    .wxother2(xmage),
    .wyother2(ymage),
    .wxother3(xswordman),
    .wyother3(yswordman),
    .chardirection(fistmandirection),
    .xcharacter(xfistman),
    .ycharacter(yfistman),
    .reset(btnC)
);

projectilemovement #(.LIFETIME(100)) mage2(
    .btnC(all_keyboard_data[4]), // todo change back
    .debouncingclock(debouncingclock5),
    .chardirection(magedirection),
    .currentcharacter(2'b00),
    .xcharacter(xmage),
    .ycharacter(ymage),
    .projectiledirection(mageprojectiledirection),
    .xprojectile(xmageprojectile),
    .yprojectile(ymageprojectile),
    .projectileactive(mageprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(collisions0)
);

projectilemovement #(.LIFETIME(100)) mage3(
    .btnC(all_keyboard_data[3]), // todo change back
    .debouncingclock(debouncingclock5),
    .chardirection(magedirection),
    .currentcharacter(2'b00),
    .xcharacter(xmage),
    .ycharacter(ymage),
    .projectiledirection(ult_mageprojectiledirection),
    .xprojectile(ult_xmageprojectile),
    .yprojectile(ult_ymageprojectile),
    .projectileactive(ult_mageprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(ult_collisions0)
);

projectilemovement #(.LIFETIME(150)) gunman2(
    .btnC(all_keyboard_data[9]),
    .debouncingclock(debouncingclock6),
    .chardirection(gunmandirection),
    .currentcharacter(2'b01),
    .xcharacter(xgunman),
    .ycharacter(ygunman),
    .projectiledirection(gunmanprojectiledirection),
    .xprojectile(xgunmanprojectile),
    .yprojectile(ygunmanprojectile),
    .projectileactive(gunmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(collisions1)
);

projectilemovement #(.LIFETIME(150)) gunman3(
    .btnC(all_keyboard_data[8]),
    .debouncingclock(debouncingclock6),
    .chardirection(gunmandirection),
    .currentcharacter(2'b01),
    .xcharacter(xgunman),
    .ycharacter(ygunman),
    .projectiledirection(ult_gunmanprojectiledirection),
    .xprojectile(ult_xgunmanprojectile),
    .yprojectile(ult_ygunmanprojectile),
    .projectileactive(ult_gunmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(ult_collisions1)
);

projectilemovement #(.LIFETIME(100)) swordman2(
    .btnC(all_keyboard_data[14]),
    .debouncingclock(debouncingclock7),
    .chardirection(swordmandirection),
    .currentcharacter(2'b10),
    .xcharacter(xswordman),
    .ycharacter(yswordman),
    .projectiledirection(swordmanprojectiledirection),
    .xprojectile(xswordmanprojectile),
    .yprojectile(yswordmanprojectile),
    .projectileactive(swordmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(collisions2)
);

projectilemovement #(.LIFETIME(100)) swordman3(
    .btnC(all_keyboard_data[13]),
    .debouncingclock(debouncingclock7),
    .chardirection(swordmandirection),
    .currentcharacter(2'b10),
    .xcharacter(xswordman),
    .ycharacter(yswordman),
    .projectiledirection(ult_swordmanprojectiledirection),
    .xprojectile(ult_xswordmanprojectile),
    .yprojectile(ult_yswordmanprojectile),
    .projectileactive(ult_swordmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(ult_collisions2)
);

projectilemovement #(.LIFETIME(50)) fistman2(
    .btnC(all_keyboard_data[19]),
    .debouncingclock(debouncingclock8),
    .chardirection(fistmandirection),
    .currentcharacter(2'b11),
    .xcharacter(xfistman),
    .ycharacter(yfistman),
    .projectiledirection(fistmanprojectiledirection),
    .xprojectile(xfistmanprojectile),
    .yprojectile(yfistmanprojectile),
    .projectileactive(fistmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(collisions3)
);

projectilemovement #(.LIFETIME(50)) fistman3(
    .btnC(all_keyboard_data[18]),
    .debouncingclock(debouncingclock8),
    .chardirection(fistmandirection),
    .currentcharacter(2'b11),
    .xcharacter(xfistman),
    .ycharacter(yfistman),
    .projectiledirection(ult_fistmanprojectiledirection),
    .xprojectile(ult_xfistmanprojectile),
    .yprojectile(ult_yfistmanprojectile),
    .projectileactive(ult_fistmanprojectileactive),
    .xmage(xmage),
    .ymage(ymage),
    .xgunman(xgunman),
    .ygunman(ygunman),
    .xswordman(xswordman),
    .yswordman(yswordman),
    .xfistman(xfistman),
    .yfistman(yfistman),
    .collisions(ult_collisions3)
);

healthmanager healthmanager1(
    .debouncingclock(debouncingclock9),
    .collisions({collisions3, collisions2, collisions1, collisions0}), // 16-bit register representing collisions for 4 characters over 4 intervals
    .ult_collisions({ult_collisions3, ult_collisions2, ult_collisions1, ult_collisions0}), // 16-bit register representing collisions for 4 characters over 4 intervals
    .healthmage(healthmage),
    .healthgunman(healthgunman),
    .healthswordman(healthswordman),
    .healthfistman(healthfistman),
    .reset(btnC)
);

wire [17:0] magedata;
wire [17:0] gunmandata;
wire [17:0] swordmandata;
wire [17:0] fistmandata;

wire [17:0] mageprojectiledata;
wire [17:0] gunmanprojectiledata;
wire [17:0] swordmanprojectiledata;
wire [17:0] fistmanprojectiledata;

wire [17:0] ult_mageprojectiledata;
wire [17:0] ult_gunmanprojectiledata;
wire [17:0] ult_swordmanprojectiledata;
wire [17:0] ult_fistmanprojectiledata;

wire [17:0] battlearenadata;

wire [17:0] tombstonedata1;
wire [17:0] tombstonedata2;
wire [17:0] tombstonedata3;
wire [17:0] tombstonedata4;

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
    .x(x - xmageprojectile),
    .y(y - ymageprojectile),
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

mageprojectile_bram proj5 (
    .clk(clk6p25m),
    .x(x - ult_xmageprojectile),
    .y(y - ult_ymageprojectile),
    .mageprojectiledirection(ult_mageprojectiledirection),
    .pixel_data(ult_mageprojectiledata)
);

gunmanprojectile_bram proj6 (
    .clk(clk6p25m),
    .x(x - ult_xgunmanprojectile),
    .y(y - ult_ygunmanprojectile),
    .gunmanprojectiledirection(ult_gunmanprojectiledirection),
    .pixel_data(ult_gunmanprojectiledata)
);

swordmanprojectile_bram proj7 (
    .clk(clk6p25m),
    .x(x - ult_xswordmanprojectile),
    .y(y - ult_yswordmanprojectile),
    .swordmanprojectiledirection(ult_swordmanprojectiledirection),
    .pixel_data(ult_swordmanprojectiledata)
);

fistmanprojectile_bram proj8 (
    .clk(clk6p25m),
    .x(x - ult_xfistmanprojectile),
    .y(y - ult_yfistmanprojectile),
    .fistmanprojectiledirection(ult_fistmanprojectiledirection),
    .pixel_data(ult_fistmanprojectiledata)
);

battlearena_bram battlearena (
    .clk(clk6p25m),
    .x(x),
    .y(y),
    .pixel_data(battlearenadata)
);

tombstone_bram tomb1 (
    .clk(clk6p25m),
    .x(x - xmage),
    .y(y - ymage),
    .pixel_data(tombstonedata1)
);

tombstone_bram tomb2 (
    .clk(clk6p25m),
    .x(x - xgunman),
    .y(y - ygunman),
    .pixel_data(tombstonedata2)
);

tombstone_bram tomb3 (
    .clk(clk6p25m),
    .x(x - xswordman),
    .y(y - yswordman),
    .pixel_data(tombstonedata3)
);

tombstone_bram tomb4 (
    .clk(clk6p25m),
    .x(x - xfistman),
    .y(y - yfistman),
    .pixel_data(tombstonedata4)
);

always @(posedge clk) begin
    if (healthmage[3:0] == 0 && tombstonedata1 != 18'b000000000000000001 && tombstonedata1 !=18'b0)
        oled_data = tombstonedata1;
    else if (healthgunman[3:0] == 0 && tombstonedata2 != 18'b000000000000000001 && tombstonedata2 !=18'b0)
        oled_data = tombstonedata2;
    else if (healthswordman[3:0] == 0 && tombstonedata3 != 18'b000000000000000001 && tombstonedata3 !=18'b0)
        oled_data = tombstonedata3;
    else if (healthfistman[3:0] == 0 && tombstonedata4 != 18'b000000000000000001 && tombstonedata4 !=18'b0)
        oled_data = tombstonedata4;
        
    else if (healthmage[3:0] != 0 && magedata != 18'b000000000000000001 && magedata !=18'b0)
        oled_data = magedata;
    else if (healthgunman[3:0] != 0 && gunmandata != 18'b000000000000000001 && gunmandata != 18'b0)
        oled_data = gunmandata;
    else if (healthswordman[3:0] != 0 && swordmandata != 18'b000000000000000001 && swordmandata != 18'b0)
        oled_data = swordmandata;
    else if (healthfistman[3:0] != 0 && fistmandata != 18'b000000000000000001 && fistmandata != 18'b0)
        oled_data = fistmandata;
        
    else if (ult_mageprojectileactive != 1'b0 && ult_mageprojectiledata != 18'b0000000000000001 && ult_mageprojectiledata != 18'b0)
         oled_data = {ult_mageprojectiledata << 5, 5'b11111};
    else if (ult_swordmanprojectileactive != 1'b0 && ult_swordmanprojectiledata != 18'b0000000000000001 && ult_swordmanprojectiledata != 18'b0)
         oled_data = {ult_swordmanprojectiledata << 5, 5'b11111};
    else if (ult_gunmanprojectileactive != 1'b0 && ult_gunmanprojectiledata != 18'b0000000000000001 && ult_gunmanprojectiledata != 18'b0)
         oled_data = {ult_gunmanprojectiledata << 5, 5'b11111};
    else if (ult_fistmanprojectileactive != 1'b0 && ult_fistmanprojectiledata != 18'b0000000000000001 && ult_fistmanprojectiledata != 18'b0)
         oled_data = {ult_fistmanprojectiledata << 5, 5'b11111};
         
    else if (mageprojectileactive != 1'b0 && mageprojectiledata != 18'b0000000000000001 && mageprojectiledata != 18'b0)
        oled_data = mageprojectiledata;
    else if (swordmanprojectileactive != 1'b0 && swordmanprojectiledata != 18'b0000000000000001 && swordmanprojectiledata != 18'b0)
         oled_data = swordmanprojectiledata;
    else if (gunmanprojectileactive != 1'b0 && gunmanprojectiledata != 18'b0000000000000001 && gunmanprojectiledata != 18'b0)
         oled_data = gunmanprojectiledata;
    else if (fistmanprojectileactive != 1'b0 && fistmanprojectiledata != 18'b0000000000000001 && fistmanprojectiledata != 18'b0)
         oled_data = fistmanprojectiledata;
         
    else
        oled_data = battlearenadata;  // Default background
end

endmodule