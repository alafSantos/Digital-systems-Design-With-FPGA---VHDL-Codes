-- Listing 8.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity kb_code is
   generic(W_SIZE: integer:=2);  -- 2^W_SIZE words in FIFO
   port (
      clk, reset: in  std_logic;
      ps2d, ps2c: in  std_logic;
      key: out std_logic_vector(7 downto 0);
		k_done_tick, k_press, k_normal: out std_logic
   );
end kb_code;

architecture arch of kb_code is
   constant BRK									: std_logic_vector(7 downto 0):="11110000";-- F0 (break code)
   constant EST									: std_logic_vector(7 downto 0):="11100000";-- E0 (Cdico estendido)
   type statetype is (wait_code,wait_brk, get_code);
   signal state_reg, state_next				: statetype;
   signal dout       						   : std_logic_vector(7 downto 0);
   signal rx_done_tick						   : std_logic;
	signal k_done_tick_reg,k_done_tick_next: std_logic;
	signal k_press_reg, k_press_next			: std_logic;
	signal k_normal_reg, k_normal_next		: std_logic;
	signal key_reg,key_next					   : std_logic_vector(7 downto 0);

begin
   --=======================================================
   -- instanciação
   --=======================================================
   ps2_rx_unit: entity work.ps2_rx(arch)
      port map(clk=>clk, reset=>reset, rx_en=>'1',
               ps2d=>ps2d, ps2c=>ps2c,
               rx_done_tick=>rx_done_tick,
               dout=>dout);

   --=======================================================
   -- FSM para tratar o dado 
   --=======================================================
   process (clk, reset)
   begin
      if reset='1' then
         state_reg <= wait_code;
			k_press_reg <= '0';
			k_done_tick_reg <= '0';
			k_normal_reg <= '0';
			key_reg <= (others=> '0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
			k_press_reg <= k_press_next;
			k_done_tick_reg <= k_done_tick_next;
			k_normal_reg <= k_normal_next;
			key_reg <= key_next;
      end if;
   end process;

   process(state_reg, rx_done_tick, dout, k_press_reg,k_done_tick_reg, k_normal_reg, key_reg)
   begin
      state_next <= state_reg;
		k_press_next <= k_press_reg;
		k_done_tick_next <= k_done_tick_reg;
		k_normal_next <= k_normal_reg;
		key_next <= key_reg;
	   k_normal<=k_normal_reg;
      k_press <= k_press_reg;
      k_done_tick<= k_done_tick_reg;
		key <= key_reg;
   
      case state_reg is
         when wait_code => -- Espera e salva 1 em press- tecla apertada
            k_done_tick_next <= '0';
				if rx_done_tick='1' and dout=EST then -- Salva 0 em normal- tecla estendida
               k_press_next <= '1';
					k_normal_next <= '0';
               state_next <= wait_brk;
            else -- Salva 1 em normal- tecla normal
					k_press_next <= '1';
					k_normal_next <= '1';
               state_next <= wait_brk;
				end if;

         when wait_brk => -- Espera e salva 0 em press- tecla solta
            if rx_done_tick='1' and dout=BRK then
					k_press_next <= '0';
               state_next <= get_code;
            end if;

         when get_code => -- Espera e salva o makecode 
            if rx_done_tick='1' then
					key_next <= dout;
					k_done_tick_next <= '1';
               state_next <= wait_code;
            end if;
      end case;
   end process;
end arch;
