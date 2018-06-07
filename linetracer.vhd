library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity A19_AKS_PCY_YKH is
	Port (Reset : in STD_LOGIC;
			CLK : in STD_LOGIC;
			Light : out STD_LOGIC_VECTOR (6 downto 0);	-- emit infrared ray
			Sen_in : in STD_LOGIC_VECTOR (6 downto 0);  -- receive infrared ray
			LED : inout STD_LOGIC_VECTOR (6 downto 0);
			R_A : out STD_LOGIC;						-- Motor Stators (4 for right wheel)
			R_B : out STD_LOGIC;
			R_NA : out STD_LOGIC;
			R_NB : out STD_LOGIC;
			L_A : out STD_LOGIC;						-- Motor Stators (4 for left wheel)
			L_B : out STD_LOGIC;
			L_NA : out STD_LOGIC;
			L_NB : out STD_LOGIC);
end A19_AKS_PCY_YKH;

architecture Behavioral of A19_AKS_PCY_YKH is

	signal clk_sen : STD_LOGIC;							-- infrared ray clk
	signal clk_r : STD_LOGIC;							-- right wheel clk
	signal clk_l : STD_LOGIC;							-- left wheel clk
	signal cnt_r : integer range 0 to 10000;			-- clk div : clk_r, control speed & direction
	signal cnt_l : integer range 0 to 10000;			-- clk div : clk_l, control speed & direction
	signal R_state : STD_LOGIC_VECTOR (2 downto 0);		-- control right wheel
	signal L_state : STD_LOGIC_VECTOR (2 downto 0); 	-- control left wheel
	
begin
	-- Infrared Ray Sensor
	process (reset, CLK)
		variable cnt : integer range 0 to 5000;
	begin
		if reset = '0' then cnt := 0; 
		elsif rising_edge(clk) then 
			if cnt = 4999 then cnt := 0; clk_sen <= not clk_sen;
			else cnt := cnt +1;
			end if;
		end if;
	end process;
	
	process (clk_sen)
	begin
	for i in 0 to 6 loop
		Light(i) <= clk_sen;
	end loop;
	end process;

	-- Infrared Ray Sensor (input) -> LED (output)
	process (clk_sen, reset)
	begin 
		if reset = '0' then LED <= "0000000";
		elsif falling_edge (clk_sen) then LED <= sen_in;	-- LED output falling edge
		end if;
	end process;
		
	-- Clk division for Right Wheel 
	process (reset, clk, cnt_r)
		variable cnt : integer range 0 to 10000;
	begin
		if reset = '0' then cnt := 0; clk_r <= '0';
		elsif rising_edge (clk) then
			if cnt = cnt_r then cnt := 0; clk_r <= not clk_r;
			else cnt := cnt + 1;
			end if;
		end if;
	end process;
	
	-- Clk division for Left Wheel 
	process (reset, clk, cnt_l)
		variable cnt : integer range 0 to 10000;
	begin
		if reset = '0' then cnt := 0; clk_l <= '0';
		elsif rising_edge (clk) then
			if cnt = cnt_l then cnt := 0; clk_l <= not clk_l;
			else cnt := cnt + 1;
			end if;
		end if;
		end process;


		-- !! clk changes -> state changes !!
		-- state changes when clk rises
		-- a turn : state (000) -> state (000)
		-- cnt decrease -> clk period decreas -> wheel speed increase
		-- Turn : low speed direction

	-- Right Wheel Operation
	process (reset, clk_r)
	begin
		end if;
		if reset = '0' then R_state <= "000";
		elsif rising_edge (clk_r) then R_state <= R_state + 1;
	end process;

	-- Left Wheel Operation
	process (reset, clk_l)
	begin
		if reset = '0' then L_state <= "000";
		elsif rising_edge (clk_l) then L_state <= L_state + 1;
		end if;
		end process;

	-- Right Wheel State Control 
	process (R_state)
	begin
		case R_state is			-- 1-2 phase exitation
			when "000" => R_A <= '1'; R_B <= '0'; R_NA <= '0'; R_NB <= '0';		// 1 phase exitation
			when "001" => R_A <= '1'; R_B <= '1'; R_NA <= '0'; R_NB <= '0'; 	// 2 phase exitation
			when "010" => R_A <= '0'; R_B <= '1'; R_NA <= '0'; R_NB <= '0';		// 1 phase exitation
			when "011" => R_A <= '0'; R_B <= '1'; R_NA <= '1'; R_NB <= '0';		// 2 phase exitation
			when "100" => R_A <= '0'; R_B <= '0'; R_NA <= '1'; R_NB <= '0';		// 1 phase exitation
			when "101" => R_A <= '0'; R_B <= '0'; R_NA <= '1'; R_NB <= '1'; 	// 2 phase exitation
			when "110" => R_A <= '0'; R_B <= '0'; R_NA <= '0'; R_NB <= '1'; 	// 1 phase exitation
			when "111" => R_A <= '1'; R_B <= '0'; R_NA <= '0'; R_NB <= '1'; 	// 2 phase exitation
			when others => R_A <= '0'; R_B <= '0'; R_NA <= '0'; R_NB <= '0'; 	// 1 phase exitation
		end case;
	end process;
	
	-- Left Wheel State Control 	
	process (L_state)
	begin
		case L_state is
			when "000" => L_A <= '0'; L_B <= '0'; L_NA <= '0'; L_NB <= '1';		// 1 phase exitation
			when "001" => L_A <= '0'; L_B <= '0'; L_NA <= '1'; L_NB <= '1'; 	// 2 phase exitation
			when "010" => L_A <= '0'; L_B <= '0'; L_NA <= '1'; L_NB <= '0'; 	// 1 phase exitation
			when "011" => L_A <= '0'; L_B <= '1'; L_NA <= '1'; L_NB <= '0'; 	// 2 phase exitation
			when "100" => L_A <= '0'; L_B <= '1'; L_NA <= '0'; L_NB <= '0'; 	// 1 phase exitation
			when "101" => L_A <= '1'; L_B <= '1'; L_NA <= '0'; L_NB <= '0'; 	// 2 phase exitation
			when "110" => L_A <= '1'; L_B <= '0'; L_NA <= '0'; L_NB <= '0';		// 1 phase exitation
			when "111" => L_A <= '1'; L_B <= '0'; L_NA <= '0'; L_NB <= '1'; 	// 2 phase exitation
			when others => L_A <= '0'; L_B <= '0'; L_NA <= '0'; L_NB <= '0'; 	// 1 phase exitation
		end case;
	end process;
	
	-- Control Line Tracer
	process (LED)
	begin
		case LED is
			-- LED - [LANE] - LED : Go straight : 
			when "0111110" => cnt_l <= 1000; cnt_r <= 1000;
			when "0011100" => cnt_l <= 1000; cnt_r <= 1000;
			when "0001000" => cnt_l <= 1000; cnt_r <= 1000;

			-- LED - LED - [LANE] : Move Right : cnt_l < cnt_r
			when "0111100" => cnt_l <= 1000; cnt_r <= 1500;
			when "0011000" => cnt_l <= 1000; cnt_r <= 1500;
			when "0010000" => cnt_l <= 1000; cnt_r <= 1500;
			
			-- [LANE] - LED - LED : Move Left : cnt_l > cnt_r
			when "0011110" => cnt_l <= 1500; cnt_r <= 1000;
			when "0001100" => cnt_l <= 1500; cnt_r <= 1000; 
			when "0000100" => cnt_l <= 1500; cnt_r <= 1000;
			
			-- LED - LED - --- [LANE] : Move Right : cnt_l << cnt_r
			when "0111000" => cnt_l <= 1000; cnt_r <= 1800;
			when "0110000" => cnt_l <= 1000; cnt_r <= 2300;
			when "0100000" => cnt_l <= 1000; cnt_r <= 2800;
			
			-- [LANE] --- LED - LED : Move Left : cnt_l >> cnt_r				
			when "0001110" => cnt_l <= 1800; cnt_r <= 1000;
			when "0000110" => cnt_l <= 2300; cnt_r <= 1000;
			when "0000010" => cnt_l <= 2800; cnt_r <= 1000;

			-- LED - [LANE] - LED : Go straight : 
			when others => cnt_r <= 1000; cnt_l <= 1000;
		end case;
	end process;
	
end Behavioral;
