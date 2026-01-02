`timescale 1ns / 1ps

//module key_input(
//    input wire clk,       // System clock
//    input wire kclk,      // PS/2 clock
//    input wire kdata,     // PS/2 data
//    output reg [5:0] keys = 6'b000000,
//    output reg key_pressed = 0
//);
//    // Ultra-fast state tracking
//    reg [7:0] current_scancode = 8'h00;
//    reg is_break_code = 0;

//    // Shift register for PS/2 frame capture
//    reg [10:0] ps2_frame = 11'b0;
//    reg [3:0] bit_count = 4'b0;

//    // Synchronous PS/2 frame decoding
//    // Optional: Add debounce for more robust input
//    wire kclk_debounced, kdata_debounced;
    
//    debouncer #(
//        .COUNT_MAX(20),
//        .COUNT_WIDTH(5)
//    ) db_clk (
//        .clk(clk),
//        .I(kclk),
//        .O(kclk_debounced)
//    );
    
//    debouncer #(
//        .COUNT_MAX(20),
//        .COUNT_WIDTH(5)
//    ) db_data (
//        .clk(clk),
//        .I(kdata),
//        .O(kdata_debounced)
//    );

//    always @(negedge kclk) begin
//        // Shift in PS/2 data
//        ps2_frame <= {kdata, ps2_frame[10:1]};
//        bit_count <= bit_count + 1;

//        // Frame complete (11 bits)
//        if (bit_count == 4'd10) begin
//            // Validate frame (start bit low, stop bit high)
//            if (ps2_frame[0] == 1'b0 && ps2_frame[10] == 1'b1) begin
//                current_scancode <= ps2_frame[8:1];
//                bit_count <= 4'b0;
//            end
//        end
//    end

//    // Instant key state processing
//    always @(posedge clk) begin
//        // Reset key states
//        keys <= 6'b000000;
//        key_pressed <= 1'b0;

//        // Process scancode
//        case (current_scancode)
//            8'hF0: is_break_code <= 1'b1;  // Break code indicator
            
//            // Directional Keys
//            8'h75: if (!is_break_code) begin // Up Arrow
//                keys[0] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
            
//            8'h72: if (!is_break_code) begin // Down Arrow
//                keys[1] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
            
//            8'h6B: if (!is_break_code) begin // Left Arrow
//                keys[2] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
            
//            8'h74: if (!is_break_code) begin // Right Arrow
//                keys[3] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
            
//            8'h2D: if (!is_break_code) begin // R Key (Reset)
//                keys[4] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
            
//            8'h4D: if (!is_break_code) begin // P Key (Pause)
//                keys[5] <= 1'b1;
//                key_pressed <= 1'b1;
//            end
//        endcase

//        // Reset break code flag after processing
//        if (current_scancode != 8'hF0) begin
//            is_break_code <= 1'b0;
//        end
//    end
//endmodule



module key_input(
    input wire clk,       // System clock
    input wire kclk,      // PS/2 clock
    input wire kdata,     // PS/2 data
    output reg [5:0] keys = 6'b000000,
    output reg key_pressed = 0
);
    // Ultra-fast state tracking
    reg [7:0] current_scancode = 8'h00;
    reg [7:0] previous_scancode = 8'h00;
    reg is_break_code = 0;
    reg key_state_changed = 0;  // New flag to track key state changes

    // Shift register for PS/2 frame capture
    reg [10:0] ps2_frame = 11'b0;
    reg [3:0] bit_count = 4'b0;

    // Rest of the existing setup remains the same...
    
        debouncer #(
        .COUNT_MAX(20),
        .COUNT_WIDTH(5)
    ) db_clk (
        .clk(clk),
        .I(kclk),
        .O(kclk_debounced)
    );
    
    debouncer #(
        .COUNT_MAX(20),
        .COUNT_WIDTH(5)
    ) db_data (
        .clk(clk),
        .I(kdata),
        .O(kdata_debounced)
    );

    always @(negedge kclk) begin
        // Shift in PS/2 data
        ps2_frame <= {kdata, ps2_frame[10:1]};
        bit_count <= bit_count + 1;

        // Frame complete (11 bits)
        if (bit_count == 4'd10) begin
            // Validate frame (start bit low, stop bit high)
            if (ps2_frame[0] == 1'b0 && ps2_frame[10] == 1'b1) begin
                current_scancode <= ps2_frame[8:1];
                bit_count <= 4'b0;
            end
        end
    end

    // Instant key state processing
    always @(posedge clk) begin
        // Reset key states and key_pressed
        keys <= 6'b000000;
        key_pressed <= 1'b0;
        key_state_changed = 1'b0;  // Reset change flag

        // Process scancode
        case (current_scancode)
            8'hF0: is_break_code <= 1'b1;  // Break code indicator
            
            // Directional Keys
            8'h75: if (!is_break_code) begin // Up Arrow
                keys[0] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
            
            8'h72: if (!is_break_code) begin // Down Arrow
                keys[1] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
            
            8'h6B: if (!is_break_code) begin // Left Arrow
                keys[2] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
            
            8'h74: if (!is_break_code) begin // Right Arrow
                keys[3] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
            
            8'h2D: if (!is_break_code) begin // R Key (Reset)
                keys[4] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
            
            8'h4D: if (!is_break_code) begin // P Key (Pause)
                keys[5] <= 1'b1;
                key_pressed <= 1'b1;
                key_state_changed <= 1'b1;
            end
        endcase

        // Update previous scancode only when key state changes
        if (key_state_changed) begin
            previous_scancode <= current_scancode;
        end

        // Reset break code flag after processing
        if (current_scancode != 8'hF0) begin
            is_break_code <= 1'b0;
        end
    end
endmodule