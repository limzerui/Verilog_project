`timescale 1ns / 1ps

//MAGE IMAGE
//////////////////////////////////////////////////////////////////////////////////
module mage_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] magedirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("MageImage.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + magedirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//GUNMAN IMAGE
//////////////////////////////////////////////////////////////////////////////////

module gunman_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] gunmandirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("GunmanImage.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + gunmandirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//FISTMAN IMAGE
//////////////////////////////////////////////////////////////////////////////////

module fistman_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] fistmandirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("FistmanImage.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + fistmandirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//SWORDMAN IMAGE
//////////////////////////////////////////////////////////////////////////////////

module swordman_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] swordmandirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("SwordmanImage.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + swordmandirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//MAGE PROJECTILE IMAGE
//////////////////////////////////////////////////////////////////////////////////

module mageprojectile_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] mageprojectiledirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("MageProjectile.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + mageprojectiledirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

// GUNMAN PROJECTILE IMAGE
//////////////////////////////////////////////////////////////////////////////////

module gunmanprojectile_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] gunmanprojectiledirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("GunmanProjectile.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + gunmanprojectiledirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//FISTMAN PROJECTILE IMAGE
//////////////////////////////////////////////////////////////////////////////////

module fistmanprojectile_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] fistmanprojectiledirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("FistmanProjectile.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + fistmanprojectiledirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//SWORDMAN PROJECTILE IMAGE
//////////////////////////////////////////////////////////////////////////////////

module swordmanprojectile_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    input [1:0] swordmanprojectiledirection,
    output reg [17:0] pixel_data
);

    // Declare a memory array for 400 pixels (20x20 = 400 entries, each 16-bits)
    reg [17:0] memory [0:1599]; 

    // Initialize memory with pixel data from a file 
    initial begin
        $readmemb("SwordmanProjectile.mem", memory);  // Load memory from file
    end

    wire [10:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = (y * 20) + x + swordmanprojectiledirection*400;

    always @ (posedge clk) begin
        if (x < 20 && y < 20)
            pixel_data <= memory[addr];  // Fetch pixel data from memory
        else
            pixel_data <= 18'b000000000000000001; // Outside bounds (black)
    end
endmodule

//BATTLE ARENA IMAGE
//////////////////////////////////////////////////////////////////////////////////

module battlearena_bram (
    input clk,
    input [9:0] x,  // X-coordinate
    input [9:0] y,  // Y-coordinate
    output reg [17:0] pixel_data
);

    reg [17:0] memory [0:19199]; 

    // Initialize memory with pixel data from a file 
    initial begin 
        $readmemb("BattleArenaOled.mem", memory);  // Load memory from file
    end

    wire [14:0] addr; // 11-bit address for 400 entries (20x20 sprite)
    assign addr = ((y >> 1) * 160) + (x >> 1);

    always @ (posedge clk) begin
            pixel_data <= memory[addr];  // Fetch pixel data from memory
    end
endmodule
