`timescale 1ns / 1ps


module CollisionDetector(
    // Character positions
    input [9:0] xmage, 
    input [9:0] ymage,
    input [9:0] xgunman,
    input [9:0] ygunman,
    input [9:0] xswordman,
    input [9:0] yswordman,
    input [9:0] xfistman,
    input [9:0] yfistman,
    
    // Size parameters
    input [6:0] CHARACTER_WIDTH,
    input [5:0] CHARACTER_HEIGHT,
    
    // Test position inputs
    input [9:0] test_x,
    input [9:0] test_y,
    input [1:0] character_to_move,  // 00=mage, 01=gunman, 10=swordman, 11=fistman
    
    // Collision outputs
    output move_allowed
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
    
    // Collision check for potential movement
    reg move_result;
    
    always @(*) begin
        case (character_to_move)
            2'b00: begin // Mage movement check
                move_result <= !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b01: begin // Gunman movement check
                move_result <= !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b10: begin // Swordman movement check
                move_result <= !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xfistman, yfistman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            
            2'b11: begin // Fistman movement check
                move_result <= !(collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                        xmage, ymage, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xgunman, ygunman, CHARACTER_WIDTH, CHARACTER_HEIGHT) || 
                              collision(test_x, test_y, CHARACTER_WIDTH, CHARACTER_HEIGHT, 
                                      xswordman, yswordman, CHARACTER_WIDTH, CHARACTER_HEIGHT));
            end
            default: move_result <= 1;
        endcase
    end
    
    assign move_allowed = move_result;
    
endmodule