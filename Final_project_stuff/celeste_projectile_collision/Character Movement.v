`timescale 1ns / 1ps

module charactermovement #(
    parameter startx = 10,
    parameter starty = 10
)(
    input debouncingclock,
    input btnU, btnD, btnL, btnR,
    
    // Collision detection inputs
    input [9:0] wxcharacter,  // Current x position (input)
    input [9:0] wycharacter,  // Current y position (input)
    input move_allowed,       // Signal from collision detector
    
    // Outputs
    output reg [1:0] chardirection,
    output [9:0] xcharacter,  // New x position (output)
    output [9:0] ycharacter,  // New y position (output)
    
    // Test position outputs for collision detection
    output reg [9:0] test_x,
    output reg [9:0] test_y,
    output reg test_active    // Signal when testing a new position
);

    reg [9:0] x_pos;
    reg [9:0] y_pos;
    reg wait_for_collisions = 0;

    localparam xlimit = 319;
    localparam ylimit = 239;
    localparam CHARACTER_WIDTH = 20;
    localparam CHARACTER_HEIGHT = 20;
    
    initial begin
        x_pos = startx;
        y_pos = starty;
        chardirection = 2'b00;
        test_active = 0;
    end
    
    always @(posedge debouncingclock) begin
        // === STEP 1: Handle new button presses ===
        if (!test_active) begin
            if (btnL && x_pos > 0) begin
                test_x <= x_pos - 1;
                test_y <= y_pos;
                test_active <= 1;
                chardirection <= 2'b10; // Left
            end
            else if (btnR && x_pos < xlimit - CHARACTER_WIDTH) begin
                test_x <= x_pos + 1;
                test_y <= y_pos;
                test_active <= 1;
                chardirection <= 2'b11; // Right
            end
            else if (btnU && y_pos > 0) begin
                test_x <= x_pos;
                test_y <= y_pos - 1;
                test_active <= 1;
                chardirection <= 2'b00; // Up
            end
            else if (btnD && y_pos < ylimit - CHARACTER_HEIGHT) begin
                test_x <= x_pos;
                test_y <= y_pos + 1;
                test_active <= 1;
                chardirection <= 2'b01; // Down
            end
            wait_for_collisions <= 1;
        end else begin
            // === STEP 2: Wait for collision to be calculated ===
            if (wait_for_collisions) begin
                wait_for_collisions <= 0;
            // === STEP 3: Handle collision response ===
            end else begin
                if (move_allowed) begin
                    // Update character position
                    x_pos <= test_x;
                    y_pos <= test_y;
                end else begin
                    test_x <= x_pos;
                    test_y <= y_pos;
                end
                
                // Reset flags regardless of whether move was allowed
                test_active <= 0;
                wait_for_collisions <= 1;
            end
        end
    end
    
    // Assign the output positions
    assign xcharacter = x_pos;
    assign ycharacter = y_pos;

endmodule


module projectilemovement (
    input btnC,
    input debouncingclock,
    input [1:0] chardirection,
    input [9:0] xcharacter,
    input [9:0] ycharacter,
    
    output reg [1:0] projectiledirection,
    output reg [9:0] xprojectile,
    output reg [9:0] yprojectile,
    output reg projectileactive,
    
    input [9:0] xmage, 
    input [9:0] ymage,
    input [9:0] xgunman, 
    input [9:0] ygunman,
    input [9:0] xswordman, 
    input [9:0] yswordman,
    input [9:0] xfistman, 
    input [9:0] yfistman,
    
    // Projectile collision outputs
    // mage gunman swordsman fistman
    output reg [3:0] collisions
);
    
localparam xlimit = 319;
localparam ylimit = 239;
localparam PROJECTILE_WIDTH = 20;
localparam PROJECTILE_HEIGHT = 20;
localparam CHARACTER_WIDTH = 20;
localparam CHARACTER_HEIGHT = 20;

// Function to detect collision between two objects
function collision;
    input [9:0] x1;
    input [9:0] y1;
    input [9:0] width1;
    input [9:0] height1;
    input [9:0] x2;
    input [9:0] y2;
    input [9:0] width2;
    input [9:0] height2;
    begin
        collision = (x1 < x2 + width2) && 
                   (x1 + width1 > x2) && 
                   (y1 < y2 + height2) && 
                   (y1 + height1 > y2);
    end
endfunction

initial begin
    projectiledirection = 0;
    xprojectile = 0;
    yprojectile = 0;
    projectileactive = 0;
end

reg projectilestart = 0;
reg prev_btnC = 0;
reg wait_for_collisions = 0;

// moving the projectile
always @ (posedge debouncingclock) begin
    
    if (~prev_btnC & btnC & ~projectileactive) begin
        projectilestart <= 1'b1;
        projectileactive <= 1'b1;
    end
    
    prev_btnC <= btnC;

    if (projectilestart) begin
        // creating projectile
        case (chardirection)
            2'b00: begin
                projectiledirection <= 2'b00; //projectile above
                xprojectile <= xcharacter;
                yprojectile <= ycharacter - 20;
            end
            2'b01: begin
                projectiledirection <= 2'b01; //projectile below
                xprojectile <= xcharacter;
                yprojectile <= ycharacter + 20;
            end
            2'b10: begin
                projectiledirection <= 2'b10;  //projectile to the left
                xprojectile <= xcharacter - 20;
                yprojectile <= ycharacter;
            end
            2'b11: begin
                projectiledirection <= 2'b11; //projectile to the right
                xprojectile <= xcharacter + 20;
                yprojectile <= ycharacter;
            end
        endcase
        
        collisions <= 4'b0000;
        projectilestart <= 0;
        wait_for_collisions <= 1;
        
    end else if (projectileactive) begin
        if (wait_for_collisions) begin
            // 0: mage 1: gunman 2: swordsman 3: fistman
            // check for collisions
            collisions[0] <= collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
            collisions[1] <= collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
            collisions[2] <= collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
            collisions[3] <= collision(xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
            
            wait_for_collisions <= 0;
        end else begin                       
            if (collisions > 0) begin       // when u hit a player with a projectile, it disappears
                projectileactive <= 1'b0;
            end else begin                  //otherwise, move projectile
                case (projectiledirection)  //projectile also dies if it hits the walls
                    2'b00: begin // up
                        if (yprojectile > 0) begin
                            yprojectile <= yprojectile - 1;
                        end else begin
                            projectileactive <= 1'b0;
                        end
                    end
                    2'b01: begin // down
                        if (yprojectile < ylimit - PROJECTILE_HEIGHT) begin
                            yprojectile <= yprojectile + 1;
                        end else begin
                            projectileactive <= 1'b0;
                        end
                    end
                    2'b10: begin // left
                        if (xprojectile > 0) begin
                            xprojectile <= xprojectile - 1;
                        end else begin
                            projectileactive <= 1'b0;
                        end
                    end
                    2'b11: begin // right
                        if (xprojectile < xlimit - PROJECTILE_WIDTH) begin
                            xprojectile <= xprojectile + 1;
                       end else begin
                            projectileactive <= 1'b0;
                        end
                    end
                endcase
            end
            wait_for_collisions <= 1;
        end
    end
end

endmodule

module healthmanager(
    input debouncingclock,
    input [15:0] collisions, // 16-bit register representing collisions for 4 characters over 4 intervals
    output reg [5:0] healthmage,
    output reg [5:0] healthgunman,
    output reg [5:0] healthswordman,
    output reg [5:0] healthfistman
);

    // Holds the count of collisions for each character
    wire [3:0] mage_hits;
    wire [3:0] gunman_hits;
    wire [3:0] swordman_hits;
    wire [3:0] fistman_hits;
    
    initial begin // initialise health
        healthmage = {2'b00, 4'd12};     // ID=00, health=10
        healthgunman = {2'b01, 4'd12};   // ID=01, health=10
        healthswordman = {2'b10, 4'd15}; // ID=10, health=10
        healthfistman = {2'b11, 4'd15};  // ID=11, health=10
    end

    reg [15:0] prev_collisions;
    wire [15:0] new_hits = collisions & ~prev_collisions; // to prevent double counting due to clock cycles difference
    
    always @ (posedge debouncingclock) begin
        // Deduct health for each character
        healthmage <= {healthmage[5:4],
                      (healthmage[3:0] == 0) ? 4'd0 : 
                      healthmage[3:0] - (new_hits[0] | new_hits[4] | new_hits[8] | new_hits[12])};
                      
        healthgunman <= {healthgunman[5:4], 
                        (healthgunman[3:0] == 0) ? 4'd0 : 
                        healthgunman[3:0] - (new_hits[1] | new_hits[5] | new_hits[9] | new_hits[13])};
                        
        healthswordman <= {healthswordman[5:4], 
                          (healthswordman[3:0] == 0) ? 4'd0 : 
                          healthswordman[3:0] - (new_hits[2] | new_hits[6] | new_hits[10] | new_hits[14])};
                          
        healthfistman <= {healthfistman[5:4], 
                         (healthfistman[3:0] == 0) ? 4'd0 : 
                         healthfistman[3:0] - (new_hits[3] | new_hits[7] | new_hits[11] | new_hits[15])};
                     
        prev_collisions <= collisions;
    end
endmodule

