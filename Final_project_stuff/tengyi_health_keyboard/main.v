`timescale 1ns / 1ps

module main(
    input clk,
    input PS2Data,
    input PS2Clk,
    input [15:0] sw,
    input [7:0] JXADC,
    output [7:0] JA,
    output [7:0] JB,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
        
    wire [23:0] all_keyboard_data;
    wire [23:0] all_health_data;
    wire [11:0] other_health_data;
    wire master = sw[15];
    
    assign all_health_data = {  sw[7:6],
                                4'b0000,
                                sw[5:4],
                                4'b0000,
                                sw[3:2],
                                4'b0000,
                                sw[1:0],
                                4'b0000};
    
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
        .all_keyboard_data(all_keyboard_data)
    );
    
    game_character_health gch1(
        .clk(clk),
        .data(master ? all_health_data[11:0] : other_health_data),
        .seg(seg),
        .an(an),
        .led(led),
        .JB(JB)
    );
    
endmodule

module get_required_data (
    input clk,
    input PS2Data,
    input PS2Clk,
    input master,
    input [11:0] health_data_in,
    input [15:0] sw,
    input [1:0] playerAchar,
    input [1:0] playerBchar,
    input [7:0] JXADC,
    output[7:0] JA,
    output [23:0] all_keyboard_data, other_health_data
);
    
    // clocks
    wire clk_50kHz;
    flexible_clock_divider fcd_tx (clk, 32'd999, clk_50kHz);
    
    // keyboard
    wire [9:0] keyboard_data;
    keyboard kb1(
        .clk(clk),
        .PS2Data(PS2Data),
        .PS2Clk(PS2Clk),
        .game_controls(keyboard_data)
    );
        
    wire [11:0] data_to_transmit = ~master ? {1'b0, keyboard_data[9:5], 1'b0, keyboard_data[4:0]} : health_data_in;

    kb_transmit kb_tx1(
        .tx_clk(clk_50kHz),
        .keyboard_data(data_to_transmit),
        .tx_pins(JA)
    );

    wire [11:0] data_received, other_keyboard_data;
    
    assign other_keyboard_data = master ? data_received : 12'b0000_0000_0000;
    assign other_health_data = ~master ? data_received : 12'b0000_0000_0000;
    
    kb_receive kb_rx1(
        .rx_clk(clk),
        .rx_pins(JXADC),
        .keyboard_data(data_received)
    );
    
    assign all_keyboard_data = {keyboard_data, other_keyboard_data};

endmodule