library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tetris_vga2 is
    Port (
        clk   : in STD_LOGIC; -- 100Mhz clock
        GridA : in STD_LOGIC_VECTOR(199 downto 0); -- blue grid
        GridB : in STD_LOGIC_VECTOR(199 downto 0); -- red grid
        HSync : out STD_LOGIC;
        VSync : out STD_LOGIC;
        R     : out STD_LOGIC_VECTOR(2 downto 0);
        G     : out STD_LOGIC_VECTOR(2 downto 0);
        B     : out STD_LOGIC_VECTOR(1 downto 0)
    );
end tetris_vga2;

architecture Behavioral of tetris_vga2 is

    signal RGB : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal HSync_reg : STD_LOGIC := '0';

    -- colors
    constant COLOR_BACKGROUND : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    constant COLOR_BORDER     : STD_LOGIC_VECTOR(7 downto 0) := "11111111";
    constant COLOR_GRIDA      : STD_LOGIC_VECTOR(7 downto 0) := "00011111";
    constant COLOR_GRIDB      : STD_LOGIC_VECTOR(7 downto 0) := "01100111";
    constant COLOR_BOTH       : STD_LOGIC_VECTOR(7 downto 0) := "11100000";

    constant HPULSE_END  : integer := 96;
    constant LMARGIN_END : integer := 336;
    constant LBORDER_END : integer := 352;
    constant RGAME_END   : integer := 512;
    constant RBORDER_END : integer := 528;

    constant VPULSE_END  : integer := 2;
    constant TMARGIN_END : integer := 76;
    constant TBORDER_END : integer := 92;
    constant BGAME_END   : integer := 412;
    constant BBORDER_END : integer := 428;

    signal HorizontalCounter : unsigned(9 downto 0) := (others => '0');
    signal VerticalCounter   : unsigned(9 downto 0) := (others => '0');

    signal ShiftedHorizontalCounter : unsigned(5 downto 0);
    constant SHIFTED_HGAME_START : integer := 22; -- gamestart/16

    signal GridA_Buff : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');
    signal GridB_Buff : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');
    signal a : STD_LOGIC_VECTOR(9 downto 0);
    signal b : STD_LOGIC_VECTOR(9 downto 0);

    -- Function to check if a bit position should NOT be white
    function is_trapezium_space(row : unsigned(7 downto 0); col : integer) return boolean is
    begin
        case to_integer(row) is
            when 19 => return (col >= 4 and col <= 5);  -- Row 0: width 6
            when 18 => return (col >= 4 and col <= 5);  -- Row 1: width 6
            when 17 => return (col >= 3 and col <= 6);  -- Row 2: width 8
            when 16 => return (col >= 3 and col <= 6);  -- Row 3: width 8
            when 15 => return (col >= 2 and col <= 7);  -- Row 4: width 8
            when 14 => return (col >= 2 and col <= 7);  -- Row 5: width 10
            when 13 => return (col >= 1 and col <= 8);  -- Row 6: width 10
            when 12 => return (col >= 1 and col <= 8);  -- Row 7: width 10
            when 11 => return (col >= 0 and col <= 9);  -- Row 0: width 6
            when 10 => return (col >= 0 and col <= 9);  -- Row 1: width 6
            when 9  => return (col >= 0 and col <= 9);  -- Row 2: width 8
            when 8  => return (col >= 0 and col <= 9);  -- Row 3: width 8
            when 7  => return (col >= 0 and col <= 9);  -- Row 4: width 8
            when 6  => return (col >= 0 and col <= 9);  -- Row 5: width 10
            when 5  => return (col >= 0 and col <= 9);  -- Row 6: width 10
            when 4  => return (col >= 0 and col <= 9);  -- Row 7: width 10
            when 3  => return (col >= 0 and col <= 9);  -- Row 4: width 8
            when 2  => return (col >= 0 and col <= 9);  -- Row 5: width 10
            when 1  => return (col >= 0 and col <= 9);  -- Row 6: width 10
            when 0  => return (col >= 0 and col <= 9);  -- Row 7: width 10
            when others => return false;
        end case;
    end function;

    signal clock_divider : unsigned(1 downto 0) := (others => '0');
    signal pxl_clk       : STD_LOGIC;

    -- Calculate row and column position
    signal row : unsigned(7 downto 0);
    signal col : unsigned(3 downto 0);

begin

    R <= RGB(7 downto 5);
    G <= RGB(4 downto 2);
    B <= RGB(1 downto 0);
    HSync <= HSync_reg;

    ShiftedHorizontalCounter <= HorizontalCounter(9 downto 4);
    a <= GridA_Buff(199 downto 190);
    b <= GridB_Buff(199 downto 190);
    pxl_clk <= clock_divider(1);

    row <= resize((VerticalCounter - TBORDER_END) / 16, 8);
    col <= resize(ShiftedHorizontalCounter - SHIFTED_HGAME_START, 4);

    process(clk)
    begin
        if rising_edge(clk) then
            clock_divider <= clock_divider + 1;
        end if;
    end process;

    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if HorizontalCounter < 799 then
                HorizontalCounter <= HorizontalCounter + 1;
            else
                HorizontalCounter <= (others => '0');
            end if;
        end if;
    end process;

    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if HorizontalCounter < 96 then
                HSync_reg <= '0';
            else
                HSync_reg <= '1';
            end if;
        end if;
    end process;

    process(HSync_reg)
    begin
        if falling_edge(HSync_reg) then
            if VerticalCounter < 524 then
                VerticalCounter <= VerticalCounter + 1;
            else
                VerticalCounter <= (others => '0');
            end if;
        end if;
    end process;

    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if VerticalCounter < 2 then
                VSync <= '0';
            else
                VSync <= '1';
            end if;
        end if;
    end process;

    -- Modified drawing logic
    process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if VerticalCounter < TMARGIN_END then
                RGB <= COLOR_BACKGROUND;

            elsif VerticalCounter < TBORDER_END then
                if HorizontalCounter >= LMARGIN_END and HorizontalCounter < RBORDER_END then
                    RGB <= COLOR_BORDER;
                else
                    RGB <= COLOR_BACKGROUND;
                end if;

            elsif VerticalCounter < BGAME_END then
                if HorizontalCounter < LMARGIN_END then
                    RGB <= COLOR_BACKGROUND;
                elsif HorizontalCounter < LBORDER_END then
                    RGB <= COLOR_BORDER;
                elsif HorizontalCounter < RGAME_END then
                    case to_integer(ShiftedHorizontalCounter) is
                        when SHIFTED_HGAME_START =>
                            if is_trapezium_space(row, 0) then
                                if (a(9) and b(9)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(9) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(9) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 1 =>
                            if is_trapezium_space(row, 1) then
                                if (a(8) and b(8)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(8) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(8) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 2 =>
                            if is_trapezium_space(row, 2) then
                                if (a(7) and b(7)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(7) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(7) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 3 =>
                            if is_trapezium_space(row, 3) then
                                if (a(6) and b(6)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(6) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(6) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 4 =>
                            if is_trapezium_space(row, 4) then
                                if (a(5) and b(5)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(5) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(5) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 5 =>
                            if is_trapezium_space(row, 5) then
                                if (a(4) and b(4)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(4) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(4) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 6 =>
                            if is_trapezium_space(row, 6) then
                                if (a(3) and b(3)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(3) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(3) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 7 =>
                            if is_trapezium_space(row, 7) then
                                if (a(2) and b(2)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(2) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(2) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 8 =>
                            if is_trapezium_space(row, 8) then
                                if (a(1) and b(1)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(1) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(1) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when SHIFTED_HGAME_START + 9 =>
                            if is_trapezium_space(row, 9) then
                                if (a(0) and b(0)) = '1' then RGB <= COLOR_BOTH;
                                elsif a(0) = '1' then RGB <= COLOR_GRIDA;
                                elsif b(0) = '1' then RGB <= COLOR_GRIDB;
                                else RGB <= COLOR_BACKGROUND;
                                end if;
                            else
                                RGB <= COLOR_BORDER;
                            end if;
                        when others =>
                            RGB <= COLOR_BACKGROUND;
                    end case;
                elsif HorizontalCounter < RBORDER_END then
                    RGB <= COLOR_BORDER;
                else
                    RGB <= COLOR_BACKGROUND;
                end if;

            elsif VerticalCounter < BBORDER_END then
                if HorizontalCounter >= LMARGIN_END and HorizontalCounter < RBORDER_END then
                    RGB <= COLOR_BORDER;
                else
                    RGB <= COLOR_BACKGROUND;
                end if;

            else
                RGB <= COLOR_BACKGROUND;
            end if;
        end if;
    end process;

    process(HSync_reg)
    begin
        if falling_edge(HSync_reg) then
            if VerticalCounter = 0 then
                GridA_Buff <= GridA;
                GridB_Buff <= GridB;
            elsif VerticalCounter > TBORDER_END
                    and VerticalCounter(3 downto 0) = to_unsigned(TBORDER_END mod 16, 4) then
                GridA_Buff <= GridA_Buff(189 downto 0) & "0000000000";
                GridB_Buff <= GridB_Buff(189 downto 0) & "0000000000";
            end if;
        end if;
    end process;

end Behavioral;
