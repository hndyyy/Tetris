`timescale 1ns / 1ps

module Tetris_top(
	clk,
	kclk,
	kdata,
	HSync,
	VSync,
	R,
	G,
	B,
	Seg,
	An,
	t
    );
	reg btnL, btnR, btnD, btnS, BtnRst, Btn_Pause;
	reg prev_key_pressed = 0;  // Track previous key press state
	input clk, kdata,kclk;
	output HSync, VSync;
	output [2:0] R;
	output [2:0] G;
	output [1:0] B;
	output [7:0] Seg;
	output [3:0] An;
	output reg t;
	wire [5:0] keys;
	wire [199:0] gridA;
	wire [199:0] gridB;
	wire [12:0] score;
	wire key_pressed;  // Add key_pressed signal

    // Instantiate key_input module with key_pressed
    key_input k(
        .clk(clk),
        .kclk(kclk),
        .kdata(kdata),
        .keys(keys),
        .key_pressed(key_pressed)  // Connect key_pressed
    );
   always @(posedge clk) begin
        // Detect rising edge of key_pressed
        if (key_pressed && !prev_key_pressed) begin
            case (keys)
                6'b100000: Btn_Pause <= 1;  // P key
                6'b010000: BtnRst <= 1;     // R key
                6'b001000: btnR <= 1;       // Right Arrow
                6'b000100: btnL <= 1;       // Left Arrow
                6'b000010: btnD <= 1;       // Down Arrow
                6'b000001: btnS <= 1;       // Up Arrow
                default: begin
                    btnL <= 0;
                    btnR <= 0;
                    btnD <= 0;
                    btnS <= 0;
                    BtnRst <= 0;
                    Btn_Pause <= 0;
                end
            endcase
        end
        
        // Reset button states in the next clock cycle
        if (key_pressed == 0) begin
            btnL <= 0;
            btnR <= 0;
            btnD <= 0;
            btnS <= 0;
            BtnRst <= 0;
            Btn_Pause <= 0;
        end
        
        // Update previous key press state
        prev_key_pressed <= key_pressed;
    end

	tetris_main M_TET(clk, btnL, btnR, btnD, btnS, BtnRst,Btn_Pause,gridA, gridB, score);
	tetris_vga2 M_VGA(clk, gridA, gridB, HSync, VSync, R, G, B);
	tetris_seg  M_SEG(clk, score, Seg, An);
	
  
endmodule