`timescale 1ns / 1ps

module kb_receive(
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
            0: begin
                if (prev_clk_pin == 1'b0 && rx_pins[0] == 1'b1) begin
                    state <= 1;
                    counter <= 0;
                end
            end
            1: begin
                counter <= counter + 1;
                if (counter >= 999) begin
                    state <= 2;
                end
            end
            2: begin
                data <= rx_pins[7:1];
                state <= 3;
            end
            3: begin
                if (data[6]) begin
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
                data <= {1'b1, keyboard_data[5:0]};
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