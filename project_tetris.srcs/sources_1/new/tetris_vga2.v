`timescale 1ns / 1ps

module tetris_vga2(
    clk,
    GridA, GridB,
    HSync, VSync,
    R, G, B
    );
    
    input clk; // 100Mhz clock
    input [199:0] GridA; // blue grid
    input [199:0] GridB; // red grid
    output reg HSync;
    output reg VSync;
    output wire [2:0] R;
    output wire [2:0] G;
    output wire [1:0] B;
    
    reg [7:0] RGB;
    assign R = RGB[7:5];
    assign G = RGB[4:2];
    assign B = RGB[1:0];
    
    // colors
    parameter COLOR_BACKGROUND = 8'b000_000_00,
              COLOR_BORDER     = 8'b111_111_11,
              COLOR_GRIDA      = 8'b000_111_11,
              COLOR_GRIDB      = 8'b011_001_11,
              COLOR_BOTH       = 8'b111_000_00;
    
    parameter HPULSE_END  = 96 ,
              LMARGIN_END = 336,
              LBORDER_END = 352,
              RGAME_END   = 512,
              RBORDER_END = 528;

    parameter VPULSE_END  = 2,
              TMARGIN_END = 76,
              TBORDER_END = 92,
              BGAME_END   = 412,
              BBORDER_END = 428;
    
    reg [9:0] HorizontalCounter;
    reg [9:0] VerticalCounter;

    wire [5:0] ShiftedHorizontalCounter = HorizontalCounter[9:4];
    parameter SHIFTED_HGAME_START = 22; // gamestart/16

    reg [199:0] GridA_Buff;
    reg [199:0] GridB_Buff;
    wire [9:0] a = GridA_Buff[199:190];
    wire [9:0] b = GridB_Buff[199:190];

    // Function to check if a bit position should NOT be white
    function is_trapezium_space;
        input [19:0] row;
        input [3:0] col;
        begin
            case(row)
                19: is_trapezium_space = (col >= 4 && col <= 5);  // Row 0: width 6
                18: is_trapezium_space = (col >= 4 && col <= 5);  // Row 1: width 6
                17: is_trapezium_space = (col >= 3 && col <= 6);  // Row 2: width 8
                16: is_trapezium_space = (col >= 3 && col <= 6);  // Row 3: width 8
                15: is_trapezium_space = (col >= 2 && col <= 7);  // Row 4: width 8
                14: is_trapezium_space = (col >= 2 && col <= 7);  // Row 5: width 10
                13: is_trapezium_space = (col >= 1 && col <= 8);  // Row 6: width 10
                12: is_trapezium_space = (col >= 1 && col <= 8);  // Row 7: width 10
                11: is_trapezium_space = (col >= 0 && col <= 9);  // Row 0: width 6
                10: is_trapezium_space = (col >= 0 && col <= 9);  // Row 1: width 6
                9: is_trapezium_space = (col >= 0 && col <= 9);  // Row 2: width 8
                8: is_trapezium_space = (col >= 0 && col <= 9);  // Row 3: width 8
                7: is_trapezium_space = (col >= 0 && col <= 9);  // Row 4: width 8
                6: is_trapezium_space = (col >= 0 && col <= 9);  // Row 5: width 10
                5: is_trapezium_space = (col >= 0 && col <= 9);  // Row 6: width 10
                4: is_trapezium_space = (col >= 0 && col <= 9);  // Row 7: width 10
                3: is_trapezium_space = (col >= 0 && col <= 9);  // Row 4: width 8
                2: is_trapezium_space = (col >= 0 && col <= 9);  // Row 5: width 10
                1: is_trapezium_space = (col >= 0 && col <= 9);  // Row 6: width 10
                0: is_trapezium_space = (col >= 0 && col <= 9);  // Row 7: width 10
                
                default: is_trapezium_space = 0;
            endcase
        end
    endfunction

    reg [1:0] clock_divider;
    wire pxl_clk = clock_divider[1];
    
    always @(posedge clk) begin
        clock_divider <= clock_divider + 1'b1;
    end
    
    always @(posedge pxl_clk) begin
        if (HorizontalCounter < 799)
            HorizontalCounter <= HorizontalCounter + 1'b1;
        else
            HorizontalCounter <= 0;
    end

    always @(posedge pxl_clk) begin
        if (HorizontalCounter < 96)
            HSync <= 1'b0;
        else
            HSync <= 1'b1;
    end

    always @(negedge HSync) begin
        if (VerticalCounter < 524)
            VerticalCounter <= VerticalCounter + 1'b1;
        else
            VerticalCounter <= 0;
    end

    always @(posedge pxl_clk) begin
        if (VerticalCounter < 2)
            VSync <= 1'b0;
        else
            VSync <= 1'b1;
    end

    // Calculate row and column position
    wire [7:0] row = (VerticalCounter - TBORDER_END) / 16;
    wire [3:0] col = (ShiftedHorizontalCounter - SHIFTED_HGAME_START);

    // Modified drawing logic
    always @(posedge pxl_clk) begin
        if (VerticalCounter < TMARGIN_END)
            RGB <= COLOR_BACKGROUND;
        
        else if (VerticalCounter < TBORDER_END) begin
            if (HorizontalCounter >= LMARGIN_END && HorizontalCounter < RBORDER_END)
                RGB <= COLOR_BORDER;
            else
                RGB <= COLOR_BACKGROUND;
        end
        
        else if (VerticalCounter < BGAME_END) begin
            if (HorizontalCounter < LMARGIN_END)
                RGB <= COLOR_BACKGROUND;
            else if (HorizontalCounter < LBORDER_END)
                RGB <= COLOR_BORDER;
            else if (HorizontalCounter < RGAME_END) begin
                case (ShiftedHorizontalCounter)
                    SHIFTED_HGAME_START:     RGB <= is_trapezium_space(row, 0) ? ((a[9] & b[9]) ? COLOR_BOTH : (a[9]) ? COLOR_GRIDA : (b[9]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 1: RGB <= is_trapezium_space(row, 1) ? ((a[8] & b[8]) ? COLOR_BOTH : (a[8]) ? COLOR_GRIDA : (b[8]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 2: RGB <= is_trapezium_space(row, 2) ? ((a[7] & b[7]) ? COLOR_BOTH : (a[7]) ? COLOR_GRIDA : (b[7]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 3: RGB <= is_trapezium_space(row, 3) ? ((a[6] & b[6]) ? COLOR_BOTH : (a[6]) ? COLOR_GRIDA : (b[6]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 4: RGB <= is_trapezium_space(row, 4) ? ((a[5] & b[5]) ? COLOR_BOTH : (a[5]) ? COLOR_GRIDA : (b[5]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 5: RGB <= is_trapezium_space(row, 5) ? ((a[4] & b[4]) ? COLOR_BOTH : (a[4]) ? COLOR_GRIDA : (b[4]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 6: RGB <= is_trapezium_space(row, 6) ? ((a[3] & b[3]) ? COLOR_BOTH : (a[3]) ? COLOR_GRIDA : (b[3]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 7: RGB <= is_trapezium_space(row, 7) ? ((a[2] & b[2]) ? COLOR_BOTH : (a[2]) ? COLOR_GRIDA : (b[2]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 8: RGB <= is_trapezium_space(row, 8) ? ((a[1] & b[1]) ? COLOR_BOTH : (a[1]) ? COLOR_GRIDA : (b[1]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    SHIFTED_HGAME_START + 9: RGB <= is_trapezium_space(row, 9) ? ((a[0] & b[0]) ? COLOR_BOTH : (a[0]) ? COLOR_GRIDA : (b[0]) ? COLOR_GRIDB : COLOR_BACKGROUND) : COLOR_BORDER;
                    default:                 RGB <= COLOR_BACKGROUND;
                endcase
            end
            else if (HorizontalCounter < RBORDER_END)
                RGB <= COLOR_BORDER;
            else
                RGB <= COLOR_BACKGROUND;
        end
        
        else if (VerticalCounter < BBORDER_END) begin
            if (HorizontalCounter >= LMARGIN_END && HorizontalCounter < RBORDER_END)
                RGB <= COLOR_BORDER;
            else
                RGB <= COLOR_BACKGROUND;
        end
        
        else
            RGB <= COLOR_BACKGROUND;
    end

    always @(negedge HSync) begin
        if (VerticalCounter == 0) begin
            GridA_Buff <= GridA;
            GridB_Buff <= GridB;
        end
        else if (VerticalCounter > TBORDER_END 
                && VerticalCounter[3:0] == TBORDER_END % 16) begin
            GridA_Buff <= GridA_Buff << 10;
            GridB_Buff <= GridB_Buff << 10;
        end
    end

endmodule