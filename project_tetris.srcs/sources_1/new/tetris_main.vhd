library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tetris_main is
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
end tetris_main;

architecture Behavioral of tetris_main is

	signal Grid_Settled : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');
	signal Grid_Active  : STD_LOGIC_VECTOR(229 downto 0) := (others => '0');
	signal periodic_counter : unsigned(28 downto 0) := (others => '0');
	signal Score_reg : unsigned(12 downto 0) := (others => '0');
	signal game_tick_counter : unsigned(28 downto 0) := (others => '0');
	constant TICK_THRESHOLD : unsigned(28 downto 0) := "00010111111111111111111111111"; -- Adjust for desired descent speed
	signal auto_descend_tick : STD_LOGIC := '0';

	-----------------
	-- Initial Grids
	-----------------
	constant START_SCREEN_SETTLED    : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');
	constant GAMEOVER_SCREEN_SETTLED : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');

	constant ROW_MASK     : STD_LOGIC_VECTOR(9 downto 0) := "1111111111";
	constant BEGINNING_SA : unsigned(7 downto 0) := to_unsigned(213, 8);

	-----------------
	-- Piece States and Data
	-----------------
	constant PS_None : unsigned(4 downto 0) := to_unsigned(0, 5);
	constant PS_O_1  : unsigned(4 downto 0) := to_unsigned(1, 5);
	constant PS_I_1  : unsigned(4 downto 0) := to_unsigned(2, 5);
	constant PS_I_2  : unsigned(4 downto 0) := to_unsigned(3, 5);
	constant PS_S_1  : unsigned(4 downto 0) := to_unsigned(4, 5);
	constant PS_S_2  : unsigned(4 downto 0) := to_unsigned(5, 5);
	constant PS_Z_1  : unsigned(4 downto 0) := to_unsigned(6, 5);
	constant PS_Z_2  : unsigned(4 downto 0) := to_unsigned(7, 5);
	constant PS_L_1  : unsigned(4 downto 0) := to_unsigned(8, 5);
	constant PS_L_2  : unsigned(4 downto 0) := to_unsigned(9, 5);
	constant PS_L_3  : unsigned(4 downto 0) := to_unsigned(10, 5);
	constant PS_L_4  : unsigned(4 downto 0) := to_unsigned(11, 5);
	constant PS_J_1  : unsigned(4 downto 0) := to_unsigned(12, 5);
	constant PS_J_2  : unsigned(4 downto 0) := to_unsigned(13, 5);
	constant PS_J_3  : unsigned(4 downto 0) := to_unsigned(14, 5);
	constant PS_J_4  : unsigned(4 downto 0) := to_unsigned(15, 5);
	constant PS_T_1  : unsigned(4 downto 0) := to_unsigned(16, 5);
	constant PS_T_2  : unsigned(4 downto 0) := to_unsigned(17, 5);
	constant PS_T_3  : unsigned(4 downto 0) := to_unsigned(18, 5);
	constant PS_T_4  : unsigned(4 downto 0) := to_unsigned(19, 5);

	constant PSd_O_1 : STD_LOGIC_VECTOR(15 downto 0) := "0110011000000000";
	constant PSd_I_1 : STD_LOGIC_VECTOR(15 downto 0) := "0100010001000100";
	constant PSd_I_2 : STD_LOGIC_VECTOR(15 downto 0) := "0000111100000000";
	constant PSd_S_1 : STD_LOGIC_VECTOR(15 downto 0) := "0000011011000000";
	constant PSd_S_2 : STD_LOGIC_VECTOR(15 downto 0) := "0100011000100000";
	constant PSd_Z_1 : STD_LOGIC_VECTOR(15 downto 0) := "0000110001100000";
	constant PSd_Z_2 : STD_LOGIC_VECTOR(15 downto 0) := "0100110010000000";
	constant PSd_L_1 : STD_LOGIC_VECTOR(15 downto 0) := "0100010001100000";
	constant PSd_L_2 : STD_LOGIC_VECTOR(15 downto 0) := "0000111010000000";
	constant PSd_L_3 : STD_LOGIC_VECTOR(15 downto 0) := "0110001000100000";
	constant PSd_L_4 : STD_LOGIC_VECTOR(15 downto 0) := "0010111000000000";
	constant PSd_J_1 : STD_LOGIC_VECTOR(15 downto 0) := "0100010011000000";
	constant PSd_J_2 : STD_LOGIC_VECTOR(15 downto 0) := "1000111000000000";
	constant PSd_J_3 : STD_LOGIC_VECTOR(15 downto 0) := "0110010001000000";
	constant PSd_J_4 : STD_LOGIC_VECTOR(15 downto 0) := "0000111000100000";
	constant PSd_T_1 : STD_LOGIC_VECTOR(15 downto 0) := "0100111000000000";
	constant PSd_T_2 : STD_LOGIC_VECTOR(15 downto 0) := "0100110001000000";
	constant PSd_T_3 : STD_LOGIC_VECTOR(15 downto 0) := "0000111001000000";
	constant PSd_T_4 : STD_LOGIC_VECTOR(15 downto 0) := "0100011001000000";

	-----------------
	-- Game States
	-----------------
	constant S_Start            : unsigned(4 downto 0) := to_unsigned(0, 5);  -- The very first state - wait for user to start a new game
	constant S_Initialize       : unsigned(4 downto 0) := to_unsigned(1, 5);  -- this state initializes a new game
	constant S_GenerateNewPiece : unsigned(4 downto 0) := to_unsigned(2, 5);  -- Generate a new active piece
	constant S_Idle             : unsigned(4 downto 0) := to_unsigned(3, 5);  -- main game state. Accepts tick event or user input
	constant S_MoveLeft         : unsigned(4 downto 0) := to_unsigned(4, 5);  -- increments active piece shift amount 
	constant S_MoveRight        : unsigned(4 downto 0) := to_unsigned(5, 5);  -- decrements active piece shift amount
	constant S_Spin             : unsigned(4 downto 0) := to_unsigned(6, 5);  -- spins piece by changing Active Piece PS
	constant S_SpinCorrection   : unsigned(4 downto 0) := to_unsigned(7, 5);  -- Corrects active piece position after rotating piece
	constant S_Wait             : unsigned(4 downto 0) := to_unsigned(8, 5);  -- just a wait state for debouncing input
	constant S_Tick             : unsigned(4 downto 0) := to_unsigned(9, 5);  -- process a game tick (check for piece settling/dropping piece 1 row)
	constant S_CleanFullRows    : unsigned(4 downto 0) := to_unsigned(10, 5); -- clean all the complete rows
	constant S_CleanEmptyRows   : unsigned(4 downto 0) := to_unsigned(11, 5); -- remove empty rows and shift floating rows down
	constant S_CheckLoss        : unsigned(4 downto 0) := to_unsigned(12, 5); -- Check if the user has lost
	constant S_GameOver         : unsigned(4 downto 0) := to_unsigned(13, 5); -- Game over state - stop and wait for user to start new game
	constant S_Pause            : unsigned(4 downto 0) := to_unsigned(14, 5); -- Pause

	signal Grid_Mask : STD_LOGIC_VECTOR(199 downto 0) := (others => '0');

	-- these wires are used for easily checking the position of the active piece
	signal Column_Left   : STD_LOGIC;
	signal Column_Left2  : STD_LOGIC;
	signal Column_Right  : STD_LOGIC;
	signal Column_Right2 : STD_LOGIC;

	signal AP_State_PS  : unsigned(4 downto 0) := (others => '0'); -- piece state
	signal AP_State_PSd : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); -- piece state data
	signal AP_State_SA  : unsigned(7 downto 0) := (others => '0'); -- shift amount

	signal Game_State         : unsigned(4 downto 0) := S_Start;
	signal Game_State_Counter : unsigned(21 downto 0) := (others => '0');
	signal Row_Elim_Counter   : unsigned(2 downto 0) := (others => '0');

	signal Game_Clock_Counter : unsigned(28 downto 0) := (others => '0');
	signal Game_Clock_Acc     : unsigned(13 downto 0) := (others => '0');
	signal Game_Tick          : STD_LOGIC;
	signal clk2_Counter       : unsigned(1 downto 0) := (others => '0');
	signal clk2               : STD_LOGIC;

	signal Random_Counter : unsigned(2 downto 0) := (others => '0');

begin

	GridS <= Grid_Settled(199 downto 0);
	GridA <= Grid_Active(229 downto 30);
	Score <= std_logic_vector(Score_reg);

	Column_Left <= Grid_Active(229) or Grid_Active(219) or Grid_Active(209) or Grid_Active(199) or Grid_Active(189)
				or Grid_Active(179) or Grid_Active(169) or Grid_Active(159) or Grid_Active(149) or Grid_Active(139)
				or Grid_Active(129) or Grid_Active(119) or Grid_Active(109) or Grid_Active(99)  or Grid_Active(89)
				or Grid_Active(79)  or Grid_Active(69)  or Grid_Active(59)  or Grid_Active(49)  or Grid_Active(39)
				or Grid_Active(29)  or Grid_Active(19)  or Grid_Active(9);

	Column_Left2 <= Grid_Active(228) or Grid_Active(218) or Grid_Active(208) or Grid_Active(198) or Grid_Active(188)
				 or Grid_Active(178) or Grid_Active(168) or Grid_Active(158) or Grid_Active(148) or Grid_Active(138)
				 or Grid_Active(128) or Grid_Active(118) or Grid_Active(108) or Grid_Active(98)  or Grid_Active(88)
				 or Grid_Active(78)  or Grid_Active(68)  or Grid_Active(58)  or Grid_Active(48)  or Grid_Active(38)
				 or Grid_Active(28)  or Grid_Active(18)  or Grid_Active(8);

	Column_Right <= Grid_Active(220) or Grid_Active(210) or Grid_Active(200) or Grid_Active(190) or Grid_Active(180)
				 or Grid_Active(170) or Grid_Active(160) or Grid_Active(150) or Grid_Active(140) or Grid_Active(130)
				 or Grid_Active(120) or Grid_Active(110) or Grid_Active(100) or Grid_Active(90)  or Grid_Active(80)
				 or Grid_Active(70)  or Grid_Active(60)  or Grid_Active(50)  or Grid_Active(40)  or Grid_Active(30)
				 or Grid_Active(20)  or Grid_Active(10)  or Grid_Active(0);

	Column_Right2 <= Grid_Active(221) or Grid_Active(211) or Grid_Active(201) or Grid_Active(191) or Grid_Active(181)
				  or Grid_Active(171) or Grid_Active(161) or Grid_Active(151) or Grid_Active(141) or Grid_Active(131)
				  or Grid_Active(121) or Grid_Active(111) or Grid_Active(101) or Grid_Active(91)  or Grid_Active(81)
				  or Grid_Active(71)  or Grid_Active(61)  or Grid_Active(51)  or Grid_Active(41)  or Grid_Active(31)
				  or Grid_Active(21)  or Grid_Active(11)  or Grid_Active(1);

	Game_Tick <= Game_Clock_Counter(28);
	clk2      <= clk2_Counter(1);

	process(clk)
	begin
		if rising_edge(clk) then
			clk2_Counter <= clk2_Counter + 1;
		end if;
	end process;

	process(clk2)
	begin
		if rising_edge(clk2) then
			if Random_Counter = "110" then
				Random_Counter <= "000";
			else
				Random_Counter <= Random_Counter + 1;
			end if;
		end if;
	end process;

	-----------------
	-- WIll adjust game speed based on score
	-----------------
	process(clk2)
	begin
		if rising_edge(clk2) then
			Game_Clock_Acc <= to_unsigned(5, 14);
		end if;
	end process;

	-----------------
	-- Generate Active Piece Grid based on AP_State
	-----------------
	process(clk2)
	begin
		if rising_edge(clk2) then
			case AP_State_PS is
				when PS_O_1 => AP_State_PSd <= PSd_O_1;
				when PS_I_1 => AP_State_PSd <= PSd_I_1;
				when PS_I_2 => AP_State_PSd <= PSd_I_2;
				when PS_S_1 => AP_State_PSd <= PSd_S_1;
				when PS_S_2 => AP_State_PSd <= PSd_S_2;
				when PS_Z_1 => AP_State_PSd <= PSd_Z_1;
				when PS_Z_2 => AP_State_PSd <= PSd_Z_2;
				when PS_L_1 => AP_State_PSd <= PSd_L_1;
				when PS_L_2 => AP_State_PSd <= PSd_L_2;
				when PS_L_3 => AP_State_PSd <= PSd_L_3;
				when PS_L_4 => AP_State_PSd <= PSd_L_4;
				when PS_J_1 => AP_State_PSd <= PSd_J_1;
				when PS_J_2 => AP_State_PSd <= PSd_J_2;
				when PS_J_3 => AP_State_PSd <= PSd_J_3;
				when PS_J_4 => AP_State_PSd <= PSd_J_4;
				when PS_T_1 => AP_State_PSd <= PSd_T_1;
				when PS_T_2 => AP_State_PSd <= PSd_T_2;
				when PS_T_3 => AP_State_PSd <= PSd_T_3;
				when PS_T_4 => AP_State_PSd <= PSd_T_4;
				when others => AP_State_PSd <= (others => '0');
			end case;
		end if;
	end process;

	process(clk2)
	begin
		if rising_edge(clk2) then
			Grid_Active <= std_logic_vector(
				shift_left(resize(unsigned(AP_State_PSd(15 downto 12)), 230), to_integer(AP_State_SA) + 30) +
				shift_left(resize(unsigned(AP_State_PSd(11 downto 8)), 230), to_integer(AP_State_SA) + 20) +
				shift_left(resize(unsigned(AP_State_PSd(7 downto 4)), 230), to_integer(AP_State_SA) + 10) +
				shift_left(resize(unsigned(AP_State_PSd(3 downto 0)), 230), to_integer(AP_State_SA))
			);
		end if;
	end process;

	-----------------
	-- Game Clock
	-----------------
--	always @(posedge clk2) begin
--		if (Game_State == S_Idle)
--			Game_Clock_Counter <= Game_Clock_Counter[27:0] + Game_Clock_Acc;
--		else if (Game_State == S_Spin)
--			Game_Clock_Counter <= 0;
--	end
	process(clk2)
	begin
		if rising_edge(clk2) then
			game_tick_counter <= game_tick_counter + 1;

			-- Generate automatic descent tick
			if game_tick_counter >= TICK_THRESHOLD then
				auto_descend_tick <= '1';
				game_tick_counter <= (others => '0'); -- Reset counter
			else
				auto_descend_tick <= '0';
			end if;

			if Game_State = S_Idle or Game_State = S_Wait then
				Game_Clock_Counter <= resize(Game_Clock_Counter(27 downto 0), 29) + resize(Game_Clock_Acc, 29);
			elsif Game_State = S_Spin then
				Game_Clock_Counter <= (others => '0');
			elsif Game_State = S_Pause then
				Game_Clock_Counter <= to_unsigned(1, 29);
			end if;
		end if;
	end process;

	-----------------
	-- Main game state machine
	-----------------
	process(clk2)
	begin
		if rising_edge(clk2) then
			case Game_State is
				when S_Start =>
					Grid_Settled <= START_SCREEN_SETTLED;
					if Btn_Rst = '1' or Btn_Spin = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Initialize;
					end if;
				when S_Initialize =>
					Score_reg <= (others => '0');
					Grid_Settled <= (others => '0');
					Grid_Settled(0) <= '1';
					Grid_Settled(1) <= '1';
					Grid_Settled(2) <= '1';
					Grid_Settled(3) <= '1';
					Grid_Settled(6) <= '1';
					Grid_Settled(7) <= '1';
					Grid_Settled(8) <= '1';
					Grid_Settled(9) <= '1';
					Grid_Settled(10) <= '1';
					Grid_Settled(11) <= '1';
					Grid_Settled(12) <= '1';
					Grid_Settled(13) <= '1';
					Grid_Settled(16) <= '1';
					Grid_Settled(17) <= '1';
					Grid_Settled(18) <= '1';
					Grid_Settled(19) <= '1';
					Grid_Settled(20) <= '1';
					Grid_Settled(21) <= '1';
					Grid_Settled(22) <= '1';
					Grid_Settled(27) <= '1';
					Grid_Settled(28) <= '1';
					Grid_Settled(29) <= '1';
					Grid_Settled(30) <= '1';
					Grid_Settled(31) <= '1';
					Grid_Settled(32) <= '1';
					Grid_Settled(37) <= '1';
					Grid_Settled(38) <= '1';
					Grid_Settled(39) <= '1';
					Grid_Settled(40) <= '1';
					Grid_Settled(41) <= '1';
					Grid_Settled(48) <= '1';
					Grid_Settled(49) <= '1';
					Grid_Settled(50) <= '1';
					Grid_Settled(51) <= '1';
					Grid_Settled(58) <= '1';
					Grid_Settled(59) <= '1';
					Grid_Settled(60) <= '1';
					Grid_Settled(69) <= '1';
					Grid_Settled(70) <= '1';
					Grid_Settled(79) <= '1';

					Game_State_Counter <= (others => '0');
					Game_State <= S_GenerateNewPiece;
				when S_GenerateNewPiece =>
					if Game_State_Counter = 0 then
						case Random_Counter is
							when "000" => AP_State_PS <= PS_O_1;
							when "001" => AP_State_PS <= PS_I_1;
							when "010" => AP_State_PS <= PS_S_1;
							when "011" => AP_State_PS <= PS_Z_1;
							when "100" => AP_State_PS <= PS_L_1;
							when "101" => AP_State_PS <= PS_J_1;
							when others => AP_State_PS <= PS_T_1;
						end case;
						AP_State_SA <= BEGINNING_SA;
					end if;
					if Game_State_Counter < 2 then -- wait a few clock cycles for changes to AP_State_* to propogate
						Game_State_Counter <= Game_State_Counter + 1;
					else
						Game_State_Counter <= (others => '0');
						Game_State <= S_Idle;
					end if;
				when S_Idle =>
					if Btn_Spin = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Spin;
					elsif Btn_Left = '1' then
						if (Column_Left = '0') and (unsigned(('0' & Grid_Settled(199 downto 1)) and Grid_Active(229 downto 30)) = 0) then
							Game_State <= S_MoveLeft;
						end if;
					elsif Btn_Right = '1' then
						if (Column_Right = '0') and (unsigned((Grid_Settled(198 downto 0) & '0') and Grid_Active(229 downto 30)) = 0) then
							Game_State <= S_MoveRight;
						end if;
					elsif Game_Tick = '1' or Btn_Down = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Tick;
					elsif Btn_Rst = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Initialize;
					elsif Btn_Pause = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Pause;
					end if;
					if auto_descend_tick = '1' then
						Game_State_Counter <= (others => '0');
						Game_State <= S_Tick;
					end if;
				when S_MoveLeft =>
					AP_State_SA <= AP_State_SA + 1;
					Game_State_Counter <= to_unsigned(1, 22);
					Game_State <= S_Wait;
				when S_MoveRight =>
					AP_State_SA <= AP_State_SA - 1;
					Game_State_Counter <= to_unsigned(1, 22);
					Game_State <= S_Wait;
				when S_Spin =>
					if Game_State_Counter = 0 then
						case AP_State_PS is
							when PS_O_1 => AP_State_PS <= PS_O_1;
							when PS_I_1 => AP_State_PS <= PS_I_2;
							when PS_I_2 => AP_State_PS <= PS_I_1;
							when PS_S_1 => AP_State_PS <= PS_S_2;
							when PS_S_2 => AP_State_PS <= PS_S_1;
							when PS_Z_1 => AP_State_PS <= PS_Z_2;
							when PS_Z_2 => AP_State_PS <= PS_Z_1;
							when PS_L_1 => AP_State_PS <= PS_L_2;
							when PS_L_2 => AP_State_PS <= PS_L_3;
							when PS_L_3 => AP_State_PS <= PS_L_4;
							when PS_L_4 => AP_State_PS <= PS_L_1;
							when PS_J_1 => AP_State_PS <= PS_J_2;
							when PS_J_2 => AP_State_PS <= PS_J_3;
							when PS_J_3 => AP_State_PS <= PS_J_4;
							when PS_J_4 => AP_State_PS <= PS_J_1;
							when PS_T_1 => AP_State_PS <= PS_T_2;
							when PS_T_2 => AP_State_PS <= PS_T_3;
							when PS_T_3 => AP_State_PS <= PS_T_4;
							when PS_T_4 => AP_State_PS <= PS_T_1;
							when others => AP_State_PS <= PS_None;
						end case;
					end if;

					if Game_State_Counter < 3 then
						Game_State_Counter <= Game_State_Counter + 1;
					else
						Game_State_Counter <= (others => '0');
						Game_State <= S_SpinCorrection;
					end if;
				when S_SpinCorrection =>
					Game_State_Counter <= Game_State_Counter + 1;
					-- only execute the shift every other clock cycles. changes to AP_State_SA take a
					-- cycle to propagate into Grid_Active (ie Column_Left, Column_Right, etc)
					if Game_State_Counter(0) = '0' then
						-- check for shift amount dividing active piece into 2 (piece in both left most column and right most column)
						if Column_Left = '1' and Column_Right = '1' then
							if Column_Left2 = '1' and Column_Right2 = '1' then -- this only happens when rotating a vertical I shape when tight against right wall
								AP_State_SA <= AP_State_SA + 2;
							elsif Column_Left2 = '0' then
								AP_State_SA <= AP_State_SA + 1;
							elsif Column_Right2 = '0' then
								AP_State_SA <= AP_State_SA - 1;
							end if;
						-- check if the shifting left/right caused any overlap, if it does, move piece up one line
						elsif unsigned(Grid_Active(229 downto 30) and Grid_Settled) /= 0 then
							AP_State_SA <= AP_State_SA + 10;
						else
							-- after looping through a number of clock cycles and fixing all errors, move to next state
							Game_State_Counter <= to_unsigned(1, 22);
							Game_State <= S_Wait;
						end if;
					end if;
				when S_Wait =>
					if Game_State_Counter /= 0 then
						Game_State_Counter <= Game_State_Counter + 1;
					else
						Game_State <= S_Idle;
					end if;
				when S_Tick =>
					if unsigned(Grid_Active(39 downto 30)) > 0 or unsigned(Grid_Settled(189 downto 0) and Grid_Active(229 downto 40)) > 0 then
						Grid_Settled <= Grid_Settled or Grid_Active(229 downto 30);
						Game_State <= S_CleanFullRows;
						Game_State_Counter <= (others => '0');
					else
						AP_State_SA <= AP_State_SA - 10;
						Game_State_Counter <= to_unsigned(1, 22);
						Game_State <= S_Wait;
					end if;
				when S_Pause =>
					-- Stop game tick

					-- Resume game when any key is pressed
					if Btn_Down = '1' then
						Game_State <= S_Idle;
					end if;
				when S_CleanFullRows =>
					if Game_State_Counter = 0 then
						Grid_Mask <= ROW_MASK & (189 downto 0 => '0');
						Row_Elim_Counter <= "000";
					else
						if unsigned(Grid_Mask) /= 0 and (Grid_Mask and Grid_Settled) = Grid_Mask then
							Grid_Settled <= Grid_Settled xor Grid_Mask;
							Row_Elim_Counter <= Row_Elim_Counter + 1;
						end if;
						Grid_Mask <= std_logic_vector(shift_right(unsigned(Grid_Mask), 10));
					end if;

					if Game_State_Counter > 21 then
						case Row_Elim_Counter is
							when "000" => Score_reg <= Score_reg;
							when "001" => Score_reg <= Score_reg + 5;
							when "010" => Score_reg <= Score_reg + 15;
							when "011" => Score_reg <= Score_reg + 25;
							when "100" => Score_reg <= Score_reg + 40;
							when others => Score_reg <= Score_reg;
						end case;
						Game_State_Counter <= (others => '0');
						Game_State <= S_CleanEmptyRows;
					else
						Game_State_Counter <= Game_State_Counter + 1;
					end if;
				when S_CleanEmptyRows =>
					Game_State_Counter <= Game_State_Counter + 1;
					case to_integer(Game_State_Counter) is
						when  0 => if unsigned(Grid_Settled(189 downto 180)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 190) & Grid_Settled(179 downto 0); end if;
						when  1 => if unsigned(Grid_Settled(179 downto 170)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 180) & Grid_Settled(169 downto 0); end if;
						when  2 => if unsigned(Grid_Settled(169 downto 160)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 170) & Grid_Settled(159 downto 0); end if;
						when  3 => if unsigned(Grid_Settled(159 downto 150)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 160) & Grid_Settled(149 downto 0); end if;
						when  4 => if unsigned(Grid_Settled(149 downto 140)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 150) & Grid_Settled(139 downto 0); end if;
						when  5 => if unsigned(Grid_Settled(139 downto 130)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 140) & Grid_Settled(129 downto 0); end if;
						when  6 => if unsigned(Grid_Settled(129 downto 120)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 130) & Grid_Settled(119 downto 0); end if;
						when  7 => if unsigned(Grid_Settled(119 downto 110)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 120) & Grid_Settled(109 downto 0); end if;
						when  8 => if unsigned(Grid_Settled(109 downto 100)) = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 110) & Grid_Settled(99 downto 0); end if;
						when  9 => if unsigned(Grid_Settled(99 downto 90))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 100) & Grid_Settled(89 downto 0); end if;
						when 10 => if unsigned(Grid_Settled(89 downto 80))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 90)  & Grid_Settled(79 downto 0); end if;
						when 11 => if unsigned(Grid_Settled(79 downto 70))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 80)  & Grid_Settled(69 downto 0); end if;
						when 12 => if unsigned(Grid_Settled(69 downto 60))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 70)  & Grid_Settled(59 downto 0); end if;
						when 13 => if unsigned(Grid_Settled(59 downto 50))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 60)  & Grid_Settled(49 downto 0); end if;
						when 14 => if unsigned(Grid_Settled(49 downto 40))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 50)  & Grid_Settled(39 downto 0); end if;
						when 15 => if unsigned(Grid_Settled(39 downto 30))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 40)  & Grid_Settled(29 downto 0); end if;
						when 16 => if unsigned(Grid_Settled(29 downto 20))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 30)  & Grid_Settled(19 downto 0); end if;
						when 17 => if unsigned(Grid_Settled(19 downto 10))   = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 20)  & Grid_Settled(9 downto 0); end if;
						when 18 => if unsigned(Grid_Settled(9 downto 0))     = 0 then Grid_Settled <= "0000000000" & Grid_Settled(199 downto 10); end if;
						when others => null;
					end case;
					if Game_State_Counter < 18 then
						Game_State_Counter <= Game_State_Counter + 1;
					else
						Game_State_Counter <= (others => '0');
						Game_State <= S_CheckLoss;
					end if;
					Grid_Settled(0) <= '1';
					Grid_Settled(1) <= '1';
					Grid_Settled(2) <= '1';
					Grid_Settled(3) <= '1';
					Grid_Settled(6) <= '1';
					Grid_Settled(7) <= '1';
					Grid_Settled(8) <= '1';
					Grid_Settled(9) <= '1';
					Grid_Settled(10) <= '1';
					Grid_Settled(11) <= '1';
					Grid_Settled(12) <= '1';
					Grid_Settled(13) <= '1';
					Grid_Settled(16) <= '1';
					Grid_Settled(17) <= '1';
					Grid_Settled(18) <= '1';
					Grid_Settled(19) <= '1';
					Grid_Settled(20) <= '1';
					Grid_Settled(21) <= '1';
					Grid_Settled(22) <= '1';
					Grid_Settled(27) <= '1';
					Grid_Settled(28) <= '1';
					Grid_Settled(29) <= '1';
					Grid_Settled(30) <= '1';
					Grid_Settled(31) <= '1';
					Grid_Settled(32) <= '1';
					Grid_Settled(37) <= '1';
					Grid_Settled(38) <= '1';
					Grid_Settled(39) <= '1';
					Grid_Settled(40) <= '1';
					Grid_Settled(41) <= '1';
					Grid_Settled(48) <= '1';
					Grid_Settled(49) <= '1';
					Grid_Settled(50) <= '1';
					Grid_Settled(51) <= '1';
					Grid_Settled(58) <= '1';
					Grid_Settled(59) <= '1';
					Grid_Settled(60) <= '1';
					Grid_Settled(69) <= '1';
					Grid_Settled(70) <= '1';
					Grid_Settled(79) <= '1';
				when S_CheckLoss =>
					if unsigned(Grid_Settled(199 downto 190)) > 0 then
						Game_State <= S_GameOver;
					else
						-- generate a new piece and continue game
						Game_State <= S_GenerateNewPiece;
						Game_State_Counter <= (others => '0');
					end if;
				when S_GameOver =>
					if Game_State_Counter /= 0 then
						Game_State_Counter <= Game_State_Counter + 1;
					elsif Btn_Rst = '1' or Btn_Spin = '1' then
						Game_State <= S_Initialize;
					end if;
				when others =>
					Game_State <= S_Start;
			end case;
		end if;
	end process;

end Behavioral;
