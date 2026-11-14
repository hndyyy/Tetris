`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: button_input
// Description: Debounces push buttons on the Basys 3 board (Up, Down, Left, Right, Center)
//              and generates single-cycle active-high pulses via rising-edge detection.
//////////////////////////////////////////////////////////////////////////////////

module button_input(
    input wire clk,             // 100 MHz system clock from Basys 3
    input wire btnU,            // Up button (Rotate / Start game)
    input wire btnD,            // Down button (Soft drop)
    input wire btnL,            // Left button (Move left)
    input wire btnR,            // Right button (Move right)
    input wire btnC,            // Center button (Reset)
    output reg pulse_spin = 0,  // Single-cycle pulse for Rotate/Start
    output reg pulse_down = 0,  // Single-cycle pulse for Soft Drop
    output reg pulse_left = 0,  // Single-cycle pulse for Move Left
    output reg pulse_right = 0, // Single-cycle pulse for Move Right
    output reg pulse_reset = 0  // Single-cycle pulse for Reset
);

    // Debounce parameter for ~10.5 ms at 100 MHz clock (1,000,000 cycles)
    localparam COUNT_MAX   = 20'd1_000_000;
    localparam COUNT_WIDTH = 20;

    wire db_u, db_d, db_l, db_r, db_c;

    // Instansiasi modul debouncer untuk masing-masing tombol fisik
    debouncer #(.COUNT_MAX(COUNT_MAX), .COUNT_WIDTH(COUNT_WIDTH)) deb_u (
        .clk(clk), .I(btnU), .O(db_u)
    );
    debouncer #(.COUNT_MAX(COUNT_MAX), .COUNT_WIDTH(COUNT_WIDTH)) deb_d (
        .clk(clk), .I(btnD), .O(db_d)
    );
    debouncer #(.COUNT_MAX(COUNT_MAX), .COUNT_WIDTH(COUNT_WIDTH)) deb_l (
        .clk(clk), .I(btnL), .O(db_l)
    );
    debouncer #(.COUNT_MAX(COUNT_MAX), .COUNT_WIDTH(COUNT_WIDTH)) deb_r (
        .clk(clk), .I(btnR), .O(db_r)
    );
    debouncer #(.COUNT_MAX(COUNT_MAX), .COUNT_WIDTH(COUNT_WIDTH)) deb_c (
        .clk(clk), .I(btnC), .O(db_c)
    );

    // Register untuk pendeteksi transisi tepi naik (Rising Edge Detector)
    reg prev_u = 0, prev_d = 0, prev_l = 0, prev_r = 0, prev_c = 0;

    always @(posedge clk) begin
        // Menghasilkan pulsa tepat 1 siklus clock saat tombol ditekan
        pulse_spin  <= (db_u && !prev_u);
        pulse_down  <= (db_d && !prev_d);
        pulse_left  <= (db_l && !prev_l);
        pulse_right <= (db_r && !prev_r);
        pulse_reset <= (db_c && !prev_c);

        prev_u <= db_u;
        prev_d <= db_d;
        prev_l <= db_l;
        prev_r <= db_r;
        prev_c <= db_c;
    end

endmodule
