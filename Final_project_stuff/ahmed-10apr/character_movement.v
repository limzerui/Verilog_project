`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2025 13:42:05
// Design Name: 
// Module Name: Character Movement
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


`timescale 1ns / 1ps

`timescale 1ns / 1ps

module charactermovement #(
    parameter startx = 10,
    parameter starty = 10
)(
    input debouncingclock,
    input btnU, btnD, btnL, btnR,
    
    // Collision detection inputs
    input [6:0] wxcharacter,  // Current x position (input)
    input [5:0] wycharacter,  // Current y position (input)
    input move_allowed,       // Signal from collision detector
    
    // Outputs
    output reg [1:0] chardirection,
    output [6:0] xcharacter,  // New x position (output)
    output [5:0] ycharacter,  // New y position (output)
    
    // Test position outputs for collision detection
    output reg [6:0] test_x,
    output reg [5:0] test_y,
    output reg test_active    // Signal when testing a new position
);

    reg [6:0] x_pos;
    reg [5:0] y_pos;
    reg [7:0] debounce_counter;   
    reg debounce_active;

    localparam xlimit = 95;
    localparam ylimit = 63;
    localparam CHARACTER_WIDTH = 20;
    localparam CHARACTER_HEIGHT = 20;
    
    initial begin
        x_pos = startx;
        y_pos = starty;
        chardirection = 2'b00;
        debounce_counter = 8'd10;
        debounce_active = 0;
        test_active = 0;
    end
    
    always @(posedge debouncingclock) begin
        if (debounce_active) begin
            if (debounce_counter > 0)
                debounce_counter <= debounce_counter - 1;
            else
                debounce_active <= 0;
        end
        else begin
            test_active = 0; // Reset test flag
            
            if (btnL) begin
                if (x_pos > 0) begin
                    // Calculate potential new position
                    test_x = x_pos - 1;
                    test_y = y_pos;
                    test_active = 1;
                    
                    // Wait one cycle for collision detector to update
                    if (move_allowed) begin
                        x_pos <= x_pos - 1;
                    end
                end
                chardirection <= 2'b10; // Left
            end
            else if (btnR) begin
                if (x_pos < xlimit - CHARACTER_WIDTH) begin
                    // Calculate potential new position
                    test_x = x_pos + 1;
                    test_y = y_pos;
                    test_active = 1;
                    
                    // Wait one cycle for collision detector to update
                    if (move_allowed) begin
                        x_pos <= x_pos + 1;
                    end
                end
                chardirection <= 2'b11; // Right
            end
            else if (btnU) begin
                if (y_pos > 0) begin
                    // Calculate potential new position
                    test_x = x_pos;
                    test_y = y_pos - 1;
                    test_active = 1;
                    
                    // Wait one cycle for collision detector to update
                    if (move_allowed) begin
                        y_pos <= y_pos - 1;
                    end
                end
                chardirection <= 2'b00; // Up
            end
            else if (btnD) begin
                if (y_pos < ylimit - CHARACTER_HEIGHT) begin
                    // Calculate potential new position
                    test_x = x_pos;
                    test_y = y_pos + 1;
                    test_active = 1;
                    
                    // Wait one cycle for collision detector to update
                    if (move_allowed) begin
                        y_pos <= y_pos + 1;
                    end
                end
                chardirection <= 2'b01; // Down
            end
            
            debounce_active <= 1;
            debounce_counter <= 8'd10;
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
    input [6:0] xcharacter,
    input [5:0] ycharacter,
    output reg [1:0] projectiledirection,
    output reg [6:0] xprojectile,
    output reg [5:0] yprojectile,
    output reg projectileactive
    );

 reg [7:0] debounce_counter;   
 reg debounce_active; 
 
 initial begin
    projectileactive = 1'b0;
 end

always @ (posedge debouncingclock) begin
    if (debounce_active) begin
        if (debounce_counter > 0)
            debounce_counter <= debounce_counter-1;
        else
        debounce_active <= 0;
    end
    
    else begin
        if (btnC) begin
            if (chardirection == 2'b00) begin
                projectiledirection <= 2'b00; //projectile above
                xprojectile <= xcharacter;
                yprojectile <= ycharacter - 20;
                end
            else if (chardirection == 2'b01) begin
                projectiledirection <= 2'b01; //projectile below
                xprojectile <= xcharacter;
                yprojectile <= ycharacter + 20;
                end
            else if (chardirection == 2'b10) begin
                projectiledirection <= 2'b10;  //projectile to the left
                xprojectile <= xcharacter - 20;
                yprojectile <= ycharacter;
                end
            else if (chardirection == 2'b11) begin
                projectiledirection <= 2'b11; //projectile to the right
                xprojectile <= xcharacter + 20;
                yprojectile <= ycharacter;
                end                  
            projectileactive <= 1'b1;
            end
        debounce_active <= 1;
    end
end
endmodule
