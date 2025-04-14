`timescale 1ns / 1ps

module soundboard(
    input clk,                 // 100 MHz clock
    input btn1,                // Mage Firing
    input btn2,                // Gunman Firing
    input btn3,                // Fistman Punching
    input btn4,                // Sword Slashing
    output pwm_out             // PWM signal to PmodAMP2
);

    localparam DURATION = 25_000_000; // 0.5s at 100MHz
    wire [31:0] clk_freq = 100_000_000;
    wire [31:0] pwm_freq = 62500;
    wire [15:0] pwm_period = clk_freq / pwm_freq;

    reg [31:0] timer = 0;
    reg [2:0] state = 0;
    reg playing = 0;

    reg [31:0] tone_counter = 0;
    reg [31:0] tone_freq = 0;
    reg [7:0] pwm_value = 128;

    reg [15:0] pwm_counter = 0;
    reg pwm_reg = 0;

    // Control logic for state transitions and sound triggering
    always @(posedge clk) begin
        if (!playing) begin
            if (btn1) begin
                state <= 1; timer <= 0; tone_freq <= 10000; playing <= 1;
            end else if (btn2) begin
                state <= 2; timer <= 0; tone_freq <= 7000; playing <= 1;
            end else if (btn3) begin
                state <= 3; timer <= 0; tone_freq <= 300; playing <= 1;
            end else if (btn4) begin
                state <= 4; timer <= 0; tone_freq <= 6000; playing <= 1;
            end
        end else begin
            timer <= timer + 1;
            if (timer >= DURATION) begin
                playing <= 0;
                state <= 0;
                tone_freq <= 0;
            end else begin
                case (state)
                    1: if (tone_freq > 400) tone_freq <= tone_freq - 20; // Mage
                    2: begin // Gunman triple burst
                        if ((timer < DURATION/6) || 
                            (timer > DURATION/3 && timer < DURATION/2) || 
                            (timer > 2*DURATION/3 && timer < 5*DURATION/6))
                            tone_freq <= 7000;
                        else
                            tone_freq <= 0;
                    end
                    3: begin // Fistman fade
                        if (timer < DURATION/6) tone_freq <= 300;
                        else if (timer < DURATION/3) tone_freq <= 200;
                        else tone_freq <= 0;
                    end
                    4: begin // Sword noise
                        tone_freq <= (timer[9:3] * 23) + 5000;
                    end
                    default: tone_freq <= 0;
                endcase
            end
        end
    end

    // PWM generation block
    always @(posedge clk) begin
        pwm_reg <= (pwm_counter < pwm_value);
        pwm_counter <= pwm_counter + 1;
        if (pwm_counter >= pwm_period)
            pwm_counter <= 0;
    end

    // Square wave audio tone generation
    always @(posedge clk) begin
        if (tone_freq > 0) begin
            if (tone_counter >= clk_freq / tone_freq) begin
                tone_counter <= 0;
                pwm_value <= ~pwm_value;  // toggle for square wave
            end else begin
                tone_counter <= tone_counter + 1;
            end
        end else begin
            pwm_value <= 0;
            tone_counter <= 0;
        end
    end

    assign pwm_out = pwm_reg;

endmodule

