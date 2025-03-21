module top_module (
    input basys_clk,  // e.g., 100MHz clock
    input reset,
    output clk_out    // Output clock (for instance, 6.25MHz when DIV_COUNT is 8)
);

  // Instantiate the reusable clock divider with DIV_COUNT set to 8.
  clock_divider #(.DIV_COUNT(8)) clk_divider (
      .clk_in(basys_clk),
      .reset(reset),
      .clk_out(clk_out)
  );

endmodule

module clock_divider_6_25MHz (
    input clk_in,       // e.g., 100MHz input clock
    input reset,
    output reg clk_out  // 6.25MHz output clock
);

    reg [3:0] counter;
    
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter == 7) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule