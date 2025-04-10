`timescale 1ns / 1ps

module CollisionDetector(
    // Character positions
    input [6:0] xmage, 
    input [5:0] ymage,
    input [6:0] xgunman, 
    input [5:0] ygunman,
    input [6:0] xswordman, 
    input [5:0] yswordman,
    input [6:0] xfistman, 
    input [5:0] yfistman,
    
    // Projectile positions
    input [6:0] xmageprojectile,
    input [5:0] ymageprojectile,
    input [6:0] xgunmanprojectile,
    input [5:0] ygunmanprojectile,
    input [6:0] xswordmanprojectile,
    input [5:0] yswordmanprojectile,
    input [6:0] xfistmanprojectile,
    input [5:0] yfistmanprojectile,
    
    // Active projectiles
    input mageprojectileactive,
    input gunmanprojectileactive,
    input swordmanprojectileactive,
    input fistmanprojectileactive,
    
    // Size parameters
    input [6:0] CHARACTER_WIDTH,
    input [5:0] CHARACTER_HEIGHT,
    input [6:0] PROJECTILE_WIDTH,
    input [5:0] PROJECTILE_HEIGHT,
    
    // Test position inputs
    input [6:0] test_x,
    input [5:0] test_y,
    input [1:0] character_to_move,  // 00=mage, 01=gunman, 10=swordman, 11=fistman
    
    // Collision outputs
    output move_allowed,
    
    // Projectile collision outputs
    output mage_hit,
    output gunman_hit,
    output swordman_hit,
    output fistman_hit
);

    // Function to detect collision between two objects
    function collision;
        input [6:0] x1;
        input [5:0] y1;
        input [6:0] width1;
        input [5:0] height1;
        input [6:0] x2;
        input [5:0] y2;
        input [6:0] width2;
        input [5:0] height2;
        begin
            collision = (x1 < x2 + width2) && 
                       (x1 + width1 > x2) && 
                       (y1 < y2 + height2) && 
                       (y1 + height1 > y2);
        end
    endfunction

    // Character-Character collision checks
    wire mage_gunman_collision = collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                         xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    wire mage_swordman_collision = collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                          xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    wire mage_fistman_collision = collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                         xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    wire gunman_swordman_collision = collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                            xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    wire gunman_fistman_collision = collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                           xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    wire swordman_fistman_collision = collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                             xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT);
    
    // Character-Projectile collision checks (only if projectile is active)
    wire mage_gunmanproj_collision = gunmanprojectileactive && 
                                  collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                          xgunmanprojectile, ygunmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire mage_swordmanproj_collision = swordmanprojectileactive && 
                                    collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                            xswordmanprojectile, yswordmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire mage_fistmanproj_collision = fistmanprojectileactive && 
                                   collision(xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                           xfistmanprojectile, yfistmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    
    wire gunman_mageproj_collision = mageprojectileactive && 
                                  collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                          xmageprojectile, ymageprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire gunman_swordmanproj_collision = swordmanprojectileactive && 
                                      collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                              xswordmanprojectile, yswordmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire gunman_fistmanproj_collision = fistmanprojectileactive && 
                                     collision(xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                             xfistmanprojectile, yfistmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    
    wire swordman_mageproj_collision = mageprojectileactive && 
                                    collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                            xmageprojectile, ymageprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire swordman_gunmanproj_collision = gunmanprojectileactive && 
                                      collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                              xgunmanprojectile, ygunmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire swordman_fistmanproj_collision = fistmanprojectileactive && 
                                       collision(xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                               xfistmanprojectile, yfistmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    
    wire fistman_mageproj_collision = mageprojectileactive && 
                                   collision(xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                           xmageprojectile, ymageprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire fistman_gunmanproj_collision = gunmanprojectileactive && 
                                     collision(xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                             xgunmanprojectile, ygunmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    wire fistman_swordmanproj_collision = swordmanprojectileactive && 
                                       collision(xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                               xswordmanprojectile, yswordmanprojectile, PROJECTILE_WIDTH, PROJECTILE_HEIGHT);
    
    // Collision check for potential movement
    reg move_result;
    
    always @(*) begin
        case (character_to_move)
            2'b00: begin // Mage movement check
                move_result = !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b01: begin // Gunman movement check
                move_result = !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b10: begin // Swordman movement check
                move_result = !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b11: begin // Fistman movement check
                move_result = !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            default: move_result = 1;
        endcase
    end
    
    assign move_allowed = move_result;
    
    // Assign projectile hit signals
    assign mage_hit = mage_gunmanproj_collision || mage_swordmanproj_collision || mage_fistmanproj_collision;
    assign gunman_hit = gunman_mageproj_collision || gunman_swordmanproj_collision || gunman_fistmanproj_collision;
    assign swordman_hit = swordman_mageproj_collision || swordman_gunmanproj_collision || swordman_fistmanproj_collision;
    assign fistman_hit = fistman_mageproj_collision || fistman_gunmanproj_collision || fistman_swordmanproj_collision;
    
endmodule