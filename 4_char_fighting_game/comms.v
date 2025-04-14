`timescale 1ns / 1ps

module get_required_data (
    input clk,
    input PS2Data,
    input PS2Clk,
    input master,
    input p1_clear_ult,
    input p2_clear_ult,
    input [11:0] health_data_in,
    input [15:0] sw,
    input [9:0] rx_line,
    output[9:0] tx_line,
    output [19:0] all_keyboard_data, //kb data for all 4 players, including a block ult when meter not charged,
    output [9:0] raw_keyboard_data,  //kb data for local 2 players (no block ult when meter not charged)
    output [11:0] other_health_data  //health data received from master, only accurate for slave
);
    
    // keyboard
    wire [9:0] keyboard_data;
    keyboard kb1(
        .clk(clk),
        .PS2Data(PS2Data),
        .PS2Clk(PS2Clk),
        .game_controls(raw_keyboard_data)
    );
    
    assign keyboard_data = raw_keyboard_data & 
            (p1_clear_ult ? 10'b11111_11111 : 10'b11111_10111) &
            (p2_clear_ult ? 10'b11111_11111 : 10'b10111_11111);
    
    wire [9:0] data_to_transmit;
    assign data_to_transmit = master ? {health_data_in[9:6], health_data_in[3:0]} : keyboard_data;
    // health = 8 bit, keyboard = 10 bit
    
    assign tx_line = data_to_transmit;
    wire [11:0] data_received, other_keyboard_data;
    
    assign other_keyboard_data = master ? rx_line : 12'b0000_0000_0000;
    assign other_health_data = ~master ? {2'b11, rx_line[7:4], 2'b10, rx_line[3:0]} : 12'b0000_0000;
    assign all_keyboard_data = {other_keyboard_data, keyboard_data};

endmodule