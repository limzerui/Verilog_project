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
    input [9:0] wxother1, 
    input [9:0] wyother1,
    input [9:0] wxother2, 
    input [9:0] wyother2,
    input [9:0] wxother3, 
    input [9:0] wyother3,
    
    // Outputs
    output reg [1:0] chardirection,
    output [9:0] xcharacter,    // New x position (output)
    output [9:0] ycharacter,     // New y position (output)
    
    input reset
);

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

    reg [2:0] collisions = 3'b000;

    reg [9:0] x_pos = startx, y_pos = starty, test_x = 0, test_y = 0;
    reg wait_for_collisions = 0;
    reg test_active = 0;

    localparam xlimit = 319;
    localparam ylimit = 239;
    localparam CHARACTER_WIDTH = 20;
    localparam CHARACTER_HEIGHT = 20;
    
    initial begin
        chardirection = 2'b00;
    end
    
    always @(posedge debouncingclock) begin
        if (reset) begin
            x_pos = startx;
            y_pos = starty;
            test_x = 0;
            test_y = 0;
        // === STEP 1: Handle new button presses ===
        end else if (!test_active) begin
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
            collisions <= 3'b000;
            wait_for_collisions <= 1;
        end else begin
            // === STEP 2: Wait for collision to be calculated ===
            if (wait_for_collisions) begin
                collisions[0] <= collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                    wxother1, wyother1, CHARACTER_WIDTH, CHARACTER_HEIGHT);
                collisions[1] <= collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                    wxother2, wyother2, CHARACTER_WIDTH, CHARACTER_HEIGHT);
                collisions[2] <= collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                    wxother3, wyother3, CHARACTER_WIDTH, CHARACTER_HEIGHT);
                wait_for_collisions <= 0;
            
            // === STEP 3: Handle collision response ===
            end else begin
                if (collisions == 3'b000) begin
                    // Update character position
                    x_pos <= test_x;
                    y_pos <= test_y;
                end else begin
                    test_x <= x_pos;
                    test_y <= y_pos;
                end
                
                // Reset flags regardless of whether move was allowed
                test_active <= 0;
            end
        end
    end
    
    // Assign the output positions
    assign xcharacter = x_pos;
    assign ycharacter = y_pos;

endmodule


module projectilemovement
#(
    parameter LIFETIME = 100
)
 (
    input btnC,
    input debouncingclock,
    input [1:0] chardirection,
    input [1:0] currentcharacter,
    input [9:0] xcharacter,
    input [9:0] ycharacter,
    
    output reg [1:0] projectiledirection,
    output reg [9:0] xprojectile,
    output reg [9:0] yprojectile,
    output reg projectilestart,
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

reg [7:0] lifetime_counter = 0;
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
        lifetime_counter <= 0;
        
    end else if (projectileactive) begin
        lifetime_counter <= lifetime_counter + 1;
        
        if (lifetime_counter == LIFETIME) begin
            projectileactive <= 1'b0;
        end else if (wait_for_collisions) begin
            // 0: mage 1: gunman 2: swordsman 3: fistman
            // check for collisions
            collisions[0] <= collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT) & ~(currentcharacter == 2'b00);
            collisions[1] <= collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT) & ~(currentcharacter == 2'b01);
            collisions[2] <= collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT) & ~(currentcharacter == 2'b10);
            collisions[3] <= collision(xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                xprojectile, yprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT) & ~(currentcharacter == 2'b11);
            
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
    input reset,
    input [15:0] collisions, // 16-bit register representing collisions for 4 characters over 4 intervals
    input [15:0] ult_collisions,
    output reg [5:0] healthmage,
    output reg [5:0] healthgunman,
    output reg [5:0] healthswordman,
    output reg [5:0] healthfistman,
    output game_over
);

    
  
    reg [15:0] prev_collisions, prev_ult_collisions;
    
    wire [15:0] new_hits = collisions & ~prev_collisions;
    wire [15:0] new_ult_hits = ult_collisions & ~prev_ult_collisions;
  
    initial begin // initialise health
        healthmage = {2'b00, 4'd12};     // ID=00, health=10
        healthgunman = {2'b01, 4'd10};   // ID=01, health=10
        healthswordman = {2'b10, 4'd14}; // ID=10, health=10
        healthfistman = {2'b11, 4'd15};  // ID=11, health=10
        prev_collisions = 0;
        prev_ult_collisions = 0;
    end
    
    assign game_over =  ((healthmage[3:0] == 0) +
                        (healthgunman[3:0] == 0) +
                        (healthswordman[3:0] == 0) +
                        (healthfistman[3:0] == 0)) >= 3;
    
    wire [3:0] damagemage = new_hits[0] + new_hits[4] + new_hits[8] + new_hits[12] + 
                            ((new_ult_hits[0] + new_ult_hits[4] + new_ult_hits[8] + new_ult_hits[12]) << 1);
    
    wire [3:0] damagegunman = new_hits[1] + new_hits[5] + new_hits[9] + new_hits[13] + 
                            ((new_ult_hits[1] + new_ult_hits[5] + new_ult_hits[9] + new_ult_hits[13]) << 1);
    
    wire [3:0] damageswordman = new_hits[2] + new_hits[6] + new_hits[10] + new_hits[14] + 
                            ((new_ult_hits[2] + new_ult_hits[6] + new_ult_hits[10] + new_ult_hits[14]) << 1);
                                
    wire [3:0] damagefistman = new_hits[3] + new_hits[7] + new_hits[11] + new_hits[15] + 
                            ((new_ult_hits[3] + new_ult_hits[7] + new_ult_hits[11] + new_ult_hits[15]) << 1);                           
    
    always @ (posedge debouncingclock) begin
        
        if (reset) begin
            healthmage <= {2'b00, 4'd12};     // ID=00, health=10
            healthgunman <= {2'b01, 4'd12};   // ID=01, health=10
            healthswordman <= {2'b10, 4'd15}; // ID=10, health=10
            healthfistman <= {2'b11, 4'd15};  // ID=11, health=10
        end else begin
            // Deduct health for each character
            healthmage <= {healthmage[5:4],
                          (damagemage >= healthmage[3:0]) ? 4'd0 : healthmage[3:0] - damagemage};
                          
            healthgunman <= {healthgunman[5:4], 
                            (damagegunman >= healthgunman[3:0]) ? 4'd0 : healthgunman[3:0] - damagegunman};
                            
            healthswordman <= {healthswordman[5:4], 
                              (damageswordman >= healthswordman[3:0]) ? 4'd0 : healthswordman[3:0] - damageswordman};
                              
            healthfistman <= {healthfistman[5:4], 
                             (damagefistman >= healthfistman[3:0]) ? 4'd0 : healthfistman[3:0] - damagefistman};
        end
        
        prev_collisions <= collisions;
        prev_ult_collisions <= ult_collisions;
    end
    
endmodule

