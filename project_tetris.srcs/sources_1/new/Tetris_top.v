`timescale 1ns / 1ps

module Tetris_top(
    input wire clk,
    // Push buttons on Basys 3 board
    input wire btnU,
    input wire btnD,
    input wire btnL,
    input wire btnR,
    input wire btnC,
    // VGA Outputs
    output wire HSync,
    output wire VSync,
    output wire [2:0] R,
    output wire [2:0] G,
    output wire [1:0] B,
    // Seven-segment display outputs
    output wire [7:0] Seg,
    output wire [3:0] An,
    // LED output
    output wire t
);

    assign t = 1'b0;

    wire [199:0] gridA;
    wire [199:0] gridB;
    wire [12:0] score;

    wire pulse_spin;
    wire pulse_down;
    wire pulse_left;
    wire pulse_right;
    wire pulse_reset;

    // Button input controller with debounce and edge detection
    button_input btn_ctrl(
        .clk(clk),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .pulse_spin(pulse_spin),
        .pulse_down(pulse_down),
        .pulse_left(pulse_left),
        .pulse_right(pulse_right),
        .pulse_reset(pulse_reset)
    );

    // Core Tetris game logic
    tetris_main M_TET(
        .clk(clk),
        .Btn_Left(pulse_left),
        .Btn_Right(pulse_right),
        .Btn_Down(pulse_down),
        .Btn_Spin(pulse_spin),
        .Btn_Rst(pulse_reset),
        .Btn_Pause(1'b0),
        .GridS(gridA),
        .GridA(gridB),
        .Score(score)
    );

    // VGA display controller
    tetris_vga2 M_VGA(
        .clk(clk),
        .GridA(gridA),
        .GridB(gridB),
        .HSync(HSync),
        .VSync(VSync),
        .R(R),
        .G(G),
        .B(B)
    );

    // Seven-segment display controller for score
    tetris_seg M_SEG(
        .clk(clk),
        .num(score),
        .seg(Seg),
        .an(An)
    );

endmodule
