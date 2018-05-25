library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity stop_watch is
	port ( Reset : in STD_LOGIC;					-- initial state (00:00:00)
		   CLK : in STD_LOGIC;					-- system clock
		   SW : in STD_LOGIC;					-- stop watch on/off
		   DIGIT_CON : out STD_LOGIC_VECTOR (5 downto 0);	-- choose one digit among six digits
		   sseg : out STD_LOGIC_VECTOR (7 downto 0) );		-- 7 Segment Output (DIGIT_CON)
end stop_watch;

architecture Behavioral of stop_watch is

	signal clk_dc : STD_LOGIC := '0';				-- DIGIT_CON clock
	signal clk_csec : STD_LOGIC := '1';				-- 1 per 0.01 sec, rising edge
	signal clk_sec : STD_LOGIC := '1';				-- 1 per sec, rising edge
	signal clk_min : STD_LOGIC := '1';				-- 1 per 60 sec, rising edge
	signal s_sw : STD_LOGIC := '1';					-- RUN State, active low
	signal s_clk : STD_LOGIC := '0';				-- STOP State
	signal clk_chat : STD_LOGIC := '0';				-- Debouncing SW signal
	signal Clean_out : STD_LOGIC := '1';				-- Debounced signal, active low

	signal csec2 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal csec1 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal sec2 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal sec1 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal min2 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal min1 : STD_LOGIC_VECTOR (3 downto 0) := "0000";		-- initial state (00:00:00)
	signal D : STD_LOGIC_VECTOR (7 downto 0) := "11111111";		-- Flip Flop Array for clk_chat, active low

	signal cnt_dc : integer range 0 to 5 := 0;			-- choose digit (by clk_dc)

	type State_push is (p0, p1);					-- p0 : SW OFF, p1 : SW ON
	type State_stop is (Cont, Stop);				-- STOP/RUN state
	signal Push_state : State_push := p0;
	signal Time_state : State_stop := Stop;

	function seg (data : in STD_LOGIC_VECTOR (3 downto 0))		-- LED dot : OFF
		return STD_LOGIC_VECTOR is
		variable seg7 : STD_LOGIC_VECTOR (7 downto 0);		-- BCD to 7 Segment
		begin
			case data is
				when "0000" => seg7 := "11111100";
				when "0001" => seg7 := "01100000";
				when "0010" => seg7 := "11011010";
				when "0011" => seg7 := "11110010";
				when "0100" => seg7 := "01100110";
				when "0101" => seg7 := "10110110";
				when "0110" => seg7 := "10111110";
				when "0111" => seg7 := "11100000";
				when "1000" => seg7 := "11111110";
				when "1001" => seg7 := "11110110";
				when others => seg7 := "00000000";
			end case;
		return seg7;						-- Return : 7 Segment value
	end seg;

	function dot_seg (data : in STD_LOGIC_VECTOR (3 downto 0))
		return STD_LOGIC_VECTOR is				-- LED dot : ON ( : : )
		variable seg7 : STD_LOGIC_VECTOR (7 downto 0);		-- BCD to 7 Segment
		begin
			case data is
				when "0000" => seg7 := "11111101";
				when "0001" => seg7 := "01100000";
				when "0010" => seg7 := "11011011";
				when "0011" => seg7 := "11110011";
				when "0100" => seg7 := "01100111";
				when "0101" => seg7 := "10110111";
				when "0110" => seg7 := "10111111";
				when "0111" => seg7 := "11100001";
				when "1000" => seg7 := "11111111";
				when "1001" => seg7 := "11110111";
				when others => seg7 := "00000001";
			end case;
		return seg7;
	end dot_seg;							-- Return : 7 Segment value

-- CLK DIVISION
begin
	process(reset, CLK)
	variable count_dc : integer range 0 to 1000;			-- Count : 1000 (High Frequency)
	begin
		if (reset = '0') then count_dc := 0; clk_dc <= '0';
		elsif (CLK' event and clk = '1') then
			if (count_dc = 1000) then count_dc := 0; clk_dc <= not clk_dc;
			else count_dc := count_dc + 1;
			end if;
		end if;
	end process;

	process(reset, CLK)
	variable count_chat : integer range 0 to 5000;			-- Count : 5000
	begin
		if (reset = '0') then count_chat := 0; clk_chat <= '0';
		elsif (CLK' event and clk = '1') then
			if (count_chat = 50000) then count_chat := 0; clk_chat <= not clk_chat;
			else count_chat := count_chat + 1;
			end if;
		end if;
	end process;

	process(reset, s_clk)
	variable count_csec : integer range 0 to 19999;			-- 100Hz : CNT = CLK/(2*100Hz)-1 = 19999
	begin
		if(reset = '0') then count_csec := 0; clk_csec <= '1';
		elsif (s_clk' event and s_clk = '1') then
			if (count_sec = 19999) then count_csec := 0; clk_csec <= not clk_csec;
			else count_csec := count_csec + 1;
			end if;
		end if;
	end process;

	process(reset, s_clk)
	variable count_sec : integer range 0 to 1999999;		-- 1Hz : CNT = CLK/(2*1Hz)-1 = 1999999
	begin
		if(reset = '0') then count_sec := 0; clk_sec <= '1';
		elsif (s_clk' event and s_clk = '1') then
			if (count_sec = 1999999) then count_csec := 0; clk_sec <= not clk_sec;
			else count_sec := count_sec + 1;
			end if;
		end if;
	end process;

	process(reset, s_clk)
	variable count_min : integer range 0 to 119999999;		-- 1/60Hz : CNT = CLK/(2*1/60Hz)-1 = 11999999
	begin
		if(reset = '0') then count_min := 0; clk_min <= '1';
		elsif (s_clk' event and s_clk = '1') then
			if (count_min = 11999999) then count_min := 0; clk_min <= not clk_min;
			else count_min := count_min + 1;
			end if;
		end if;
	end process;

	-- CSEC, SEC, MIN CALCULATION
	process(reset, clk_csec)
	begin
		if(reset = '0') then csec1 <= "00000"; csec2 <= "00000";	-- Async
		elsif(clk_csec' event and clk_csec = '1') then			-- rising edge
			if csec1 = "1001" then
				csec2 = "00000";
				if csec 2 = "1001" then csec2 <= "00000";	-- 00 ~ 99 - 0(0000) ~ 9(1001)
				else csec2 <= csec2 + 1;			-- carry
				end if;
			else csec1 <= csec1 + 1;
			end if;
		end if;
	end process;

	process(reset, clk_sec)
	begin
		if(reset = '0') then sec1 <= "00000"; sec2 <= "00000";		-- Async
		elsif(clk_sec' event and clk_sec = '1') then			-- rising edge
			if sec1 = "1001" then
				sec2 = "00000";
				if sec 2 = "0101" then sec2 <= "00000";		-- 00 ~ 59 - 0(0000) ~ 5(0101)
				else sec2 <= sec2 + 1;				-- carry
				end if;
			else sec1 <= sec1 + 1;
			end if;
		end if;
	end process;

	process(reset, clk_min)
	begin
		if(reset = '0') then min1 <= "00000"; min2 <= "00000";		-- Async
		elsif(clk_min' event and clk_min = '1') then			-- rising edge
			if min1 = "1001" then
				min2 = "00000";
				if min2 = "0101" then min2 <= "00000";		-- 00 ~ 59 - 0(0000) ~ 5(0101)
				else min2 <= min2 + 1;				-- carry
				end if;
			else min1 <= min1 + 1;
			end if;
		end if;
	end process;

	-- DIGIT Assignment, 7 Segment Assignment
	process(clk_dc)
	begin
		if (clk_dc' event and clk_dc = '1') then			-- digit 0 ~ digit 5
			if (cnt_dc = 5) then cnt_dc <= 0;
			else cnt_dc <= cnt_dc + 1;
			end if;
		end if;
	end process;

	process(cnt_dc, csec2, csec1, sec2, sec1, min2, min1)
	begin
		case cnt_dc is
			when 0 => DIGIT_CON <= "100000"; sseg <= seg(min2);
			when 1 => DIGIT_CON <= "010000"; sseg <= dot_seg(min1);
			when 2 => DIGIT_CON <= "001000"; sseg <= seg(sec2);
			when 3 => DIGIT_CON <= "000100"; sseg <= dot_seg(sec1);
			when 4 => DIGIT_CON <= "000010"; sseg <= seg(csec2);
			when 5 => DIGIT_CON <= "000001"; sseg <= dot_seg(csec1);
			when others => DIGIT_CON <= "000000"; sseg <= "000000000";
		end case;
	end process;

	-- Debouncing
	process(clk_chat, D, reset)
	begin
		if (reset = '0') then D <= "11111111";				-- Active Low
		elsif (clk_chat' event and clk_chat = '1') then
			D(0) <= sw;						-- Flip Flop : 0
			D(1) <= D(0);						-- Flip Flop : 0
			D(2) <= D(1);						-- Flip Flop : 0
			D(3) <= D(2);						-- Flip Flop : 0
			D(4) <= D(3);						-- Flip Flop : 0
			D(5) <= D(4);						-- Flip Flop : 0
			D(6) <= D(5);						-- Flip Flop : 0
			D(7) <= D(6);						-- Flip Flop : 0
			clean_out <= D(0) or D(1) or D(2) or D(3) or D(4) or D(5) or D(6) or D(7);
		end if;
	end process;

	-- Switching State
	-- (1) Stop Watch : RUN
	process(clean_out, clk_chat)
	begin
		if (clk_chat' event and clk_chat = '1') then
			case Push_state is
				when p0 =>						-- Switch OFF
					if (Clean_out = '0') then			-- state : p0 -> p1
						Push_state <= p1; s_sw <= '0';
					elsif(Clean_out = '1') then			-- state : p0 -> p0 (SW X)
						Push_state <= p0; s_sw <= '1';
					end if;
				when p1 =>						-- Switch ON
					if (Clean_out = '0') then			-- state : p1 -> p1 (SW X)
						Push_state <= p1; s_sw <= '1';
					elsif(Clean_out = '1') then 			-- state : p1 -> p0
						Push_state <= p0; s_sw <= '1';
					end if;
				when others => null;
			end case;
		end if;
	end process;

	-- (2) Stop Watch : STOP
	process(s_sw, clk_chat)
	begin
		if (clk_chat' event and clk_chat = '1') then
			case Time_state is
				when Cont =>						-- Stop Watch : RUN
					if (s_sw = '0') then				-- RUN -> STOP
						Time_state <= Stop;
					elsif (s_sw = '1') then				-- RUN -> RUN
						Time_state <= Cont;
					end if;
				when Stop =>						-- Stop Watch : STOP
					if (s_sw = '0') then				-- STOP -> RUN
						Time_state <= Cont;
					elsif (s_sw = '1') then				-- STOP -> STOP
						Time_state <= Stop;
					end if;
				when others => null;
			end case;
		end if;
	end process;	

	-- System - s_clk Alignment
	process(time_state, CLK)
	begin
		case time_state is
			when Cont => s_clk <= CLK;					-- RUN STATE
			when Stop => s_clk <= '0';					-- process using s_clk : STOP
			when others => null;
	end process;
end Behavioral;
