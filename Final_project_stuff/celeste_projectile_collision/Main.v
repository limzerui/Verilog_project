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

wire debouncingclock1;
flexible_clock_divider dut1 (clk, 32'd100000, debouncingclock1); //1ms
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
reg [9:0] test_x;
reg [9:0] test_y;
reg [1:0] character_to_move;
wire move_allowed;

// Character test positions
wire [9:0] mage_test_x;
wire [9:0] mage_test_y;
wire mage_test_active;
wire [9:0] gunman_test_x;
wire [9:0] gunman_test_y; 
wire gunman_test_active;
wire [9:0] swordman_test_x;
wire [9:0] swordman_test_y;
wire swordman_test_active;
wire [9:0] fistman_test_x;
wire [9:0] fistman_test_y;
wire fistman_test_active;

// Character hit signals
wire [3:0] collisions0;
wire [3:0] collisions1;
wire [3:0] collisions2;
wire [3:0] collisions3;

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
    
    .CHARACTER_WIDTH(CHARACTER_WIDTH),
    .CHARACTER_HEIGHT(CHARACTER_HEIGHT),
    .test_x(test_x),
    .test_y(test_y),
    .character_to_move(character_to_move),
    
    .move_allowed(move_allowed)
);


// Collision detection multiplexer (add this before the character movement modules)
always @(*) begin
    if (mage_test_active) begin
        test_x <= mage_test_x;
        test_y <= mage_test_y;
        character_to_move <= 2'b00;
    end
    else if (gunman_test_active) begin
        test_x <= gunman_test_x;
        test_y <= gunman_test_y;
        character_to_move <= 2'b01;
    end
    else if (swordman_test_active) begin
        test_x <= swordman_test_x;
        test_y <= swordman_test_y;
        character_to_move <= 2'b10;
    end
    else if (fistman_test_active) begin
        test_x <= fistman_test_x;
        test_y <= fistman_test_y;
        character_to_move <= 2'b11;
    end
    else begin
        test_x <= 0;
        test_y <= 0;
        character_to_move <= 2'b00;
    end
end

charactermovement #(
    .startx(20),
    .starty(20)
) mage1 (
    .debouncingclock(debouncingclock1),
    .btnU(all_keyboard_data[2:0] == 3'b001),
    .btnD(all_keyboard_data[2:0] == 3'b011),
    .btnL(all_keyboard_data[2:0] == 3'b010),
    .btnR(all_keyboard_data[2:0] == 3'b100),
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
    .startx(100),
    .starty(20)
) gunman1 (
    .debouncingclock(debouncingclock2),
    .btnU(all_keyboard_data[7:5] == 3'b001),
    .btnD(all_keyboard_data[7:5] == 3'b011),
    .btnL(all_keyboard_data[7:5] == 3'b010),
    .btnR(all_keyboard_data[7:5] == 3'b100),
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
    .startx(20),
    .starty(70)
) swordman1 (
    .debouncingclock(debouncingclock3),
    .btnU(all_keyboard_data[12:10] == 3'b001),
    .btnD(all_keyboard_data[12:10] == 3'b011),
    .btnL(all_keyboard_data[12:10] == 3'b010),
    .btnR(all_keyboard_data[12:10] == 3'b100),
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
    .startx(100),
    .starty(100)
) fistman1 (
    .debouncingclock(debouncingclock4),
    .btnU(all_keyboard_data[17:15] == 3'b001),
    .btnD(all_keyboard_data[17:15] == 3'b011),
    .btnL(all_keyboard_data[17:15] == 3'b010),
    .btnR(all_keyboard_data[17:15] == 3'b100),
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
    .btnC(all_keyboard_data[4]),
    .debouncingclock(debouncingclock5),
    .chardirection(magedirection),
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

projectilemovement gunman2(
    .btnC(all_keyboard_data[9]),
    .debouncingclock(debouncingclock6),
    .chardirection(gunmandirection),
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

projectilemovement swordman2(
    .btnC(all_keyboard_data[14]),
    .debouncingclock(debouncingclock7),
    .chardirection(swordmandirection),
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

projectilemovement fistman2(
    .btnC(all_keyboard_data[19]),
    .debouncingclock(debouncingclock8),
    .chardirection(fistmandirection),
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

healthmanager healthmanager1(
    .debouncingclock(debouncingclock9),
    .collisions({collisions3, collisions2, collisions1, collisions0}), // 16-bit register representing collisions for 4 characters over 4 intervals
    .healthmage(healthmage),
    .healthgunman(healthgunman),
    .healthswordman(healthswordman),
    .healthfistman(healthfistman)
);

wire [17:0] magedata;
wire [17:0] gunmandata;
wire [17:0] swordmandata;
wire [17:0] fistmandata;
wire [17:0] mageprojectiledata;
wire [17:0] gunmanprojectiledata;
wire [17:0] swordmanprojectiledata;
wire [17:0] fistmanprojectiledata;
wire [17:0] battlearenadata;

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

battlearena_bram battlearena (
    .clk(clk6p25m),
    .x(x),
    .y(y),
    .pixel_data(battlearenadata)
);

wire [17:0] tombstonedata1;
wire [17:0] tombstonedata2;
wire [17:0] tombstonedata3;
wire [17:0] tombstonedata4;

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
    else if (magedata != 18'b000000000000000001 && magedata !=18'b0)
        oled_data = magedata;
    else if (gunmandata != 18'b000000000000000001 && gunmandata != 18'b0)
        oled_data = gunmandata;
    else if (swordmandata != 18'b000000000000000001 && swordmandata != 18'b0)
        oled_data = swordmandata;
    else if (fistmandata != 18'b000000000000000001 && fistmandata != 18'b0)
        oled_data = fistmandata;
    else if (mageprojectileactive != 1'b0 && mageprojectiledata != 18'b0000000000000001 && mageprojectiledata != 18'b0)
        oled_data = mageprojectiledata;
    else if (swordmanprojectileactive != 1'b0 && swordmanprojectiledata != 18'b0000000000000001 && swordmanprojectiledata != 18'b0)
         oled_data = swordmanprojectiledata;
    else if (gunmanprojectileactive != 1'b0 && gunmanprojectiledata != 18'b0000000000000001 && gunmanprojectiledata != 18'b0)
         oled_data = gunmanprojectiledata;
    else if (fistmanprojectileactive != 1'b0 && fistmanprojectiledata != 18'b0000000000000001 && fistmanprojectiledata != 18'b0)
         oled_data = fistmanprojectiledata;
    else
        oled_data = battlearenadata;  // Default black background
end

endmodule