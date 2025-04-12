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
    input [7:0] JXADC,
    output[7:0] JA,
    output [19:0] all_keyboard_data,
    output [9:0] raw_keyboard_data,
    output [11:0] other_health_data
);
    
    // clocks
    wire clk_1kHz;
    flexible_clock_divider fcd_tx (clk, 32'd49999, clk_1kHz);
    
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
    
    wire [11:0] data_to_transmit = ~master ? {1'b1, keyboard_data[9:5], 1'b0, keyboard_data[4:0]} : health_data_in;

    kb_transmit kb_tx1(
        .tx_clk(clk_1kHz),
        .keyboard_data(data_to_transmit),
        .tx_pins(JA)
    );

    wire [11:0] data_received, other_keyboard_data;
    
    assign other_keyboard_data = master ? data_received : 12'b0000_0000_0000;
    assign other_health_data = ~master ? data_received : 12'b0000_0000_0000;
    
    kb_receive kb_rx1(
        .receiving_health(~master),
        .rx_clk(clk),
        .rx_pins(JXADC),
        .keyboard_data(data_received)
    );
    
    assign all_keyboard_data = {other_keyboard_data[10:6], other_keyboard_data[4:0], keyboard_data};

endmodule

module kb_receive(
    input receiving_health,
    input rx_clk,
    input [7:0] rx_pins,
    output reg [11:0] keyboard_data
);

    reg [6:0] data = 0;
    reg prev_clk_pin = 0;
    reg [1:0] state = 0;
    reg [31:0] counter = 0;
    
    always @(posedge rx_clk) begin
        case (state)
            0: begin // clock edge rise
                if (prev_clk_pin == 1'b0 && rx_pins[0] == 1'b1) begin
                    state <= 1;
                    counter <= 0;
                end
            end
            
            1: begin
                counter <= counter + 1;
                if (counter >= 49999) begin
                    state <= 2;
                end
            end
            2: begin
                data <= rx_pins[7:1];
                state <= 3;
            end
            
            3: begin
                if ((~receiving_health & data[5]) || (receiving_health & data[4])) begin
                    keyboard_data <= {keyboard_data[11:6], data[5:0]};
                end else begin
                    keyboard_data <= {data[5:0], keyboard_data[5:0]};
                end
                state <= 0;
            end
        endcase
        
        prev_clk_pin <= rx_pins[0];
    end
endmodule

module kb_transmit(
    input tx_clk,
    input [11:0] keyboard_data,
    output [7:0] tx_pins
);
    reg [6:0] data;
    reg state = 0;
    
    transmit(
        .tx_clk(tx_clk),
        .start(state),
        .data(data),
        .tx_pins(tx_pins)
    );

    always @(posedge tx_clk) begin
        case (state)
            0: begin
                data <= {1'b0, keyboard_data[11:6]};
                state <= 1;
            end
            1: begin
                data <= {1'b0, keyboard_data[5:0]};
                state <= 0;
            end
        endcase
    end
    
endmodule

module transmit(
    input tx_clk,
    input start,
    input [6:0] data,
    output [7:0] tx_pins
);

    assign tx_pins = {data, tx_clk};
    
endmodule