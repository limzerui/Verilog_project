`timescale 1ns / 1ps

module flexible_clock_divider(input basys_clock, [31:0] m, output reg slow_clock = 0);
    reg [31:0] count = 0;
    always @ (posedge basys_clock) begin
        count = (count >= m) ? 0 : count + 1;
        slow_clock = (count >= m) ? ~slow_clock : slow_clock;
    end
endmodule
