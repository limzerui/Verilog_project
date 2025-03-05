
module Top_Student(
  input clk, btnU, btnD, btnL, btnR, btnC,
  output [7:0] JB
);
    wire [7:0] oledJ;
    assign oledJ = JB;

    wire clk_mhz_6_25;
    clk_divider cdl(clk, 32'd7, clk_mhz_6_25);

    wire frame_begin, sending_pixels,sample_pixel;
    wire [12:0] pixel_index;
    wire [15:0] oled_data;

    Oled_Display oled_inst ( 
        .clk(clk_mhz_6_25),
        .reset(0),
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(oled_data),
        .cs(oledJ[0]),
        .sdin(oledJ[1]),
        .sclk(oledJ[3]),
        .d_cn(oledJ[4]),
        .resn(oledJ[5]),
        .vccen(oledJ[6]),
        .pmoden(oledJ[7])
    );

    localparam pixel_index_width = $clog2(96*64);
    localparam x_width = $clog2(96);
    localparam y_width = $clog2(64);
    localparam x_center = 96/2;
    localparam y_center = 64/2;

    localparam COLOR_BLACK = 16'h0000;
    localparam COLOR_RED   = 16'hF800;
    localparam COLOR_GREEN = 16'h07E0;

    // Border Parameters
    localparam BORDER_DISTANCE = 4;
    localparam BORDER_THICKNESS = 3;

    // Ring Parametes
    reg ring_active = 0;
    reg [7:0] outer_dia = 30;  // Initial outer diameter
    wire [7:0] inner_dia = outer_dia - 5;

    wire[x_width-1:0] x;
    wire[y_width-1:0] y;
    assign x = pixel_index % 96;
    assign y = pixel_index / 96;

    wire in_border;
    assign in_border = (
        (x >= BORDER_DISTANCE && x< BORDER_DISTANCE + BORDER_THICKNESS) ||
        (x >= 96 - BORDER_DISTANCE - BORDER_THICKNESS && x < 96 - BORDER_DISTANCE) ||
        (y >= BORDER_DISTANCE && y < BORDER_DISTANCE + BORDER_THICKNESS) ||
        (y >= 64 - BORDER_DISTANCE - BORDER_THICKNESS && y < 64 - BORDER_DISTANCE)
    );

    wire [15:0] dx = (x > x_center) ? (x - x_center) : (x_center - x);
    wire [15:0] dy = (y > y_center) ? (y - y_center) : (y_center - y);
    wire [31:0] dx_sq = dx * dx;
    wire [31:0] dy_sq = dy * dy;
    wire [31:0] dist_sq = dx_sq + dy_sq;
    wire [31:0] outer_sq = outer_dia * outer_dia;
    wire [31:0] inner_sq = (outer_dia - 5) * (outer_dia - 5);
    wire in_ring = (dist_sq <= outer_sq) && (dist_sq >= inner_sq);

    always @(posedge clk_mhz_6_25) begin
        if(in_border) begin
            oled_data <= COLOR_RED;
        end else if(ring_active && in_ring) begin
            oled_data <= COLOR_GREEN;
        end else begin
            oled_data <= COLOR_BLACK;
        end
    end

    wire center_pressed, up_pressed, down_pressed;

    debounce deb_center(
        .clk(clk_mhz_6_25),
        .btn_in(btnC),
        .pressed(center_pressed)
    );
    debounce deb_up(
        .clk(clk_mhz_6_25),
        .btn_in(btnU),
        .pressed(up_pressed)
    );
    debounce deb_down(
        .clk(clk_mhz_6_25),
        .btn_in(btnD),
        .pressed(down_pressed)
    );

    always @(posedge clk_mhz_6_25) begin
            if(center_pressed && !ring_active) begin
                ring_active <= 1;
            end else if(up_pressed && ring_active) begin
                if (outer_dia <= 45) outer_dia <= outer_dia +5;
            end
            else if(down_pressed && ring_active) begin
                if (outer_dia >= 15) outer_dia <= outer_dia -5;
            end
    end
endmodule

// Debounce Module
module debounce(
    input clk,
    input btn_in,
    output reg pressed
);

localparam DEBOUNCE_MS = 2;
localparam CLK_FREQ = 6250000;  // 6.25 MHz
localparam MAX_COUNT = (CLK_FREQ * DEBOUNCE_MS) / 1000;

reg [15:0] counter;
reg [1:0] state;

always @(posedge clk) begin
     begin
        pressed <= 0;
        case (state)
            0: begin  // Idle
                if (btn_in) begin
                    state <= 1;
                    counter <= 0;
                end
            end
            1: begin  // Debounce wait
                if (counter < MAX_COUNT) begin
                    counter <= counter + 1;
                end else begin
                    if (btn_in) begin
                        pressed <= 1;
                        state <= 2;
                    end else begin
                        state <= 0;
                    end
                end
            end
            2: begin  // Pressed
                if (!btn_in) state <= 0;
            end
        endcase
    end
end
endmodule

module clk_divider(
  input clk,
  input [31:0] m,
  output reg slow_clk
);
    reg [31:0] count;
    
    initial begin
        slow_clk = 0;
        count = 0;
    end

  always @(posedge clk) begin
    if (count == m) begin
      count <= 0;
      slow_clk <= ~slow_clk;
    end else count <= count + 1;
  end
endmodule