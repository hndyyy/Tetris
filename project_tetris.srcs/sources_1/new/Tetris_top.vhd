library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Tetris_top is
    Port (
        clk   : in STD_LOGIC;
        btnL  : in STD_LOGIC;
        btnR  : in STD_LOGIC;
        btnU  : in STD_LOGIC;
        btnD  : in STD_LOGIC;
        btnC  : in STD_LOGIC;
        HSync : out STD_LOGIC;
        VSync : out STD_LOGIC;
        R     : out STD_LOGIC_VECTOR(2 downto 0);
        G     : out STD_LOGIC_VECTOR(2 downto 0);
        B     : out STD_LOGIC_VECTOR(1 downto 0);
        Seg   : out STD_LOGIC_VECTOR(7 downto 0);
        An    : out STD_LOGIC_VECTOR(3 downto 0);
        t     : out STD_LOGIC
    );
end Tetris_top;

architecture Behavioral of Tetris_top is

    signal btnL_reg, btnR_reg, btnD_reg, btnS, BtnRst, Btn_Pause : STD_LOGIC := '0';
    signal prev_key_pressed : STD_LOGIC := '0';  -- Track previous key press state
    signal keys : STD_LOGIC_VECTOR(5 downto 0);
    signal gridA : STD_LOGIC_VECTOR(199 downto 0);
    signal gridB : STD_LOGIC_VECTOR(199 downto 0);
    signal score : STD_LOGIC_VECTOR(12 downto 0);
    signal key_pressed : STD_LOGIC;  -- Add key_pressed signal

    component button_input is
        Port (
            clk         : in STD_LOGIC;
            btnL        : in STD_LOGIC;
            btnR        : in STD_LOGIC;
            btnU        : in STD_LOGIC;
            btnD        : in STD_LOGIC;
            btnC        : in STD_LOGIC;
            keys        : out STD_LOGIC_VECTOR(5 downto 0);
            key_pressed : out STD_LOGIC
        );
    end component;

    component tetris_main is
        Port (
            clk       : in STD_LOGIC;
            Btn_Left  : in STD_LOGIC;
            Btn_Right : in STD_LOGIC;
            Btn_Down  : in STD_LOGIC;
            Btn_Spin  : in STD_LOGIC;
            Btn_Rst   : in STD_LOGIC;
            Btn_Pause : in STD_LOGIC;
            GridS     : out STD_LOGIC_VECTOR(199 downto 0);
            GridA     : out STD_LOGIC_VECTOR(199 downto 0);
            Score     : out STD_LOGIC_VECTOR(12 downto 0)
        );
    end component;

    component tetris_vga2 is
        Port (
            clk   : in STD_LOGIC;
            GridA : in STD_LOGIC_VECTOR(199 downto 0);
            GridB : in STD_LOGIC_VECTOR(199 downto 0);
            HSync : out STD_LOGIC;
            VSync : out STD_LOGIC;
            R     : out STD_LOGIC_VECTOR(2 downto 0);
            G     : out STD_LOGIC_VECTOR(2 downto 0);
            B     : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component tetris_seg is
        Port (
            clk : in STD_LOGIC;
            num : in STD_LOGIC_VECTOR(12 downto 0);
            seg : out STD_LOGIC_VECTOR(7 downto 0);
            an  : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin

    -- Instantiate button_input module with key_pressed
    k : button_input
        port map (
            clk         => clk,
            btnL        => btnL,
            btnR        => btnR,
            btnU        => btnU,
            btnD        => btnD,
            btnC        => btnC,
            keys        => keys,
            key_pressed => key_pressed  -- Connect key_pressed
        );

    process(clk)
    begin
        if rising_edge(clk) then
            -- Detect rising edge of key_pressed
            if key_pressed = '1' and prev_key_pressed = '0' then
                case keys is
                    when "100000" => Btn_Pause <= '1';  -- P key
                    when "010000" => BtnRst    <= '1';  -- R key
                    when "001000" => btnR_reg  <= '1';  -- Right Arrow
                    when "000100" => btnL_reg  <= '1';  -- Left Arrow
                    when "000010" => btnD_reg  <= '1';  -- Down Arrow
                    when "000001" => btnS      <= '1';  -- Up Arrow
                    when others =>
                        btnL_reg  <= '0';
                        btnR_reg  <= '0';
                        btnD_reg  <= '0';
                        btnS      <= '0';
                        BtnRst    <= '0';
                        Btn_Pause <= '0';
                end case;
            end if;

            -- Reset button states in the next clock cycle
            if key_pressed = '0' then
                btnL_reg  <= '0';
                btnR_reg  <= '0';
                btnD_reg  <= '0';
                btnS      <= '0';
                BtnRst    <= '0';
                Btn_Pause <= '0';
            end if;

            -- Update previous key press state
            prev_key_pressed <= key_pressed;
        end if;
    end process;

    M_TET : tetris_main
        port map (
            clk       => clk,
            Btn_Left  => btnL_reg,
            Btn_Right => btnR_reg,
            Btn_Down  => btnD_reg,
            Btn_Spin  => btnS,
            Btn_Rst   => BtnRst,
            Btn_Pause => Btn_Pause,
            GridS     => gridA,
            GridA     => gridB,
            Score     => score
        );

    M_VGA : tetris_vga2
        port map (
            clk   => clk,
            GridA => gridA,
            GridB => gridB,
            HSync => HSync,
            VSync => VSync,
            R     => R,
            G     => G,
            B     => B
        );

    M_SEG : tetris_seg
        port map (
            clk => clk,
            num => score,
            seg => Seg,
            an  => An
        );

end Behavioral;
