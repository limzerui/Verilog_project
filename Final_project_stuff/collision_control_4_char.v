module Main(
    input clk, btnU, btnD, btnL, btnR,
    input PS2Data, PS2Clk,

    output [7:0]JB
    );
    
wire clk6p25m;
slowclock dut0 (clk, 32'd7, clk6p25m);
wire debouncingclock;
slowclock dut1 (clk, 32'd100000, debouncingclock); //1ms


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
xyconverter dut3(pixelindex,x,y);   

reg [6:0] xmage;
reg [5:0] ymage;
reg [6:0] xgunman;
reg [5:0] ygunman;
reg [6:0] xswordman;
reg [5:0] yswordman;
reg [6:0] xfistman;
reg [5:0] yfistman;
reg [1:0] magedirection; //up, down, left, right
reg [1:0] gunmandirection;
reg [1:0] swordmandirection;
reg [1:0] fistmandirection;

initial begin
    xmage = 7'd10;
    ymage = 6'd10;
    xgunman = 7'd60;
    ygunman = 6'd10;
    xswordman = 7'd10;
    yswordman = 6'd40;
    xfistman = 7'd60;
    yfistman = 6'd40;

    //addition

end

reg [7:0] debounce_counter;   
reg debounce_active;         
reg btnU_prev, btnC_prev, btnD_prev;

localparam xlimit = 95;
localparam ylimit = 63;
localparam CHARACTER_WIDTH = 20;
localparam CHARACTER_HEIGHT = 20;

// Keyboard interface components
reg CLK50MHZ = 0;
wire [15:0] keycode;
wire flag;
reg [15:0] keycodev = 0;
reg start = 0;
reg cn = 0;

// Key state bitmap to track pressed keys
reg [255:0] key_state = 256'b0;

// Generate 50MHz clock for PS2 receiver
always @(posedge clk) begin
    CLK50MHZ <= ~CLK50MHZ;
end

// Add this function to detect collisions between two characters
function collision;
    input [6:0] x1;
    input [5:0] y1;
    input [6:0] x2;
    input [5:0] y2;
    begin
        collision = (x1 < x2 + CHARACTER_WIDTH) && 
                   (x1 + CHARACTER_WIDTH > x2) && 
                   (y1 < y2 + CHARACTER_HEIGHT) && 
                   (y1 + CHARACTER_HEIGHT > y2);
    end
endfunction

// Add these wire declarations after your character position declarations
wire mage_gunman_collision, mage_swordman_collision, mage_fistman_collision;
wire gunman_swordman_collision, gunman_fistman_collision;
wire swordman_fistman_collision;

// Calculate all possible collisions
assign mage_gunman_collision = collision(xmage, ymage, xgunman, ygunman);
assign mage_swordman_collision = collision(xmage, ymage, xswordman, yswordman);
assign mage_fistman_collision = collision(xmage, ymage, xfistman, yfistman);
assign gunman_swordman_collision = collision(xgunman, ygunman, xswordman, yswordman);
assign gunman_fistman_collision = collision(xgunman, ygunman, xfistman, yfistman);
assign swordman_fistman_collision = collision(xswordman, yswordman, xfistman, yfistman);

// PS2 keyboard receiver
PS2Receiver keyboard_receiver (
    .clk(CLK50MHZ),
    .kclk(PS2Clk),
    .kdata(PS2Data),
    .keycode(keycode),
    .oflag(flag)
);

// Process raw keycodes
always @(keycode) begin
    if (keycode[7:0] == 8'hf0) begin
        cn <= 1'b0;
    end else if (keycode[15:8] == 8'hf0) begin
        cn <= keycode != keycodev;
    end else begin
        cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
    end
end

// Register valid keycodes
always @(posedge clk) begin
    if (flag == 1'b1 && cn == 1'b1) begin
        start <= 1'b1;
        keycodev <= keycode;
    end else
        start <= 1'b0;
end

// Update key state bitmap
always @(posedge clk) begin
    if (start) begin
        // Key release event (F0 in upper byte)
        if (keycodev[15:8] == 8'hF0) begin
            // Clear the bit for the released key
            key_state[keycodev[7:0]] <= 1'b0;
        end
        // Key press event
        else begin
            // Set the bit for the pressed key
            key_state[keycodev[7:0]] <= 1'b1;
        end
    end
end

    reg [6:0] next_xmage;
    reg [5:0] next_ymage;
    reg [6:0] next_xgunman;
    reg [5:0] next_ygunman;

always @ (posedge debouncingclock) begin

    if (debounce_active) begin
        if (debounce_counter > 0)
            debounce_counter <= debounce_counter-1;
        else
        debounce_active <= 0;
    end
    
    // else begin
    //     if(btnL) begin
    //         if(xmage > 0) begin
    //             xmage <= xmage - 1;
    //             end
    //         else begin
    //             xmage <= 0;
    //             end
    //     magedirection <= 10;
    //     end
        
    //     else if (btnR) begin
    //         if(xmage < xlimit-20) begin
    //             xmage <= xmage + 1;
    //             end
    //         else begin
    //             xmage <= xlimit-20;
    //             end
    //     magedirection <= 11;
    //     end
    
    //     else if (btnU) begin
    //         if(ymage > 0) begin
    //             ymage <= ymage - 1;
    //             end
    //         else begin
    //             ymage <= 0;
    //             end
    //     magedirection <= 00;
    //     end
        
    //     else if (btnD) begin
    //         if (ymage < ylimit-20) begin
    //             ymage <= ymage + 1;
    //             end
    //         else begin
    //             ymage <= ylimit-20;
    //             end
    //     magedirection <= 01;
    //     end
    //     debounce_active <= 1;
    // end
  // Inside your (posedge debouncingclock) block, replace the movement logic:


end

wire signed [6:0] xrmage = x - xmage;
wire signed [5:0] yrmage = y - ymage;
wire [15:0] magedata;
wire [15:0] gunmandata;
wire [15:0] swordmandata;
wire [15:0] fistmandata;

mage_bram char1 (
    .clk(clk6p25m),
    .x(xrmage),
    .y(yrmage),
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

always @( posedge clk) begin
    if(magedata != 16'b0000000000000001)
        oled_data = magedata;
    else if (gunmandata != 16'b0000000000000001)
        oled_data = gunmandata;
    else if (swordmandata != 16'b0000000000000001)
        oled_data = swordmandata;
    else if (fistmandata != 16'b0000000000000001)
        oled_data = fistmandata;
    else
        oled_data = 16'b0000000000000000;  // Default black background
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

module PS2Receiver(
    input clk,
    input kclk,
    input kdata,
    output reg [15:0] keycode = 0,
    output reg oflag
    );
    
    reg [7:0] datacur = 0;
    reg [7:0] dataprev = 0;
    reg [3:0] cnt = 0;
    reg flag = 0;
    
    reg [21:0] timeout = 0;
    
    reg [2:0] ps2_clk_sync = 0;
    
    always @(posedge clk) begin
        ps2_clk_sync <= {ps2_clk_sync[1:0], kclk};
    end
    
    wire fall_edge = (ps2_clk_sync[2:1] == 2'b10);
    
    always @(posedge clk) begin
        if (fall_edge) begin
            if (cnt == 0 && kdata == 0) begin
                cnt <= cnt + 1;
                flag <= 1;
            end else if (cnt > 0 && cnt < 9) begin
                datacur[cnt-1] <= kdata;
                cnt <= cnt + 1;
            end else if (cnt == 9) begin
                cnt <= 0;
                flag <= 0;
                dataprev <= datacur;
                keycode <= {dataprev, datacur};
                oflag <= 1;
            end
        end else if (oflag == 1) begin
            oflag <= 0;
        end
    end
endmodule