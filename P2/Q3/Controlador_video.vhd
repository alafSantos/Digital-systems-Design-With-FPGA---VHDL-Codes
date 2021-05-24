
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
entity Controlador_video is
 port (
      clk, reset: in std_logic;
		x_bcd0, x_bcd1: in std_logic_vector(3 downto 0);
		x2_bcd0, x2_bcd1, x2_bcd2: in std_logic_vector(3 downto 0);
		rgb: out std_logic_vector(7 downto 0);
		hsync, vsync: out std_logic
   );
end Controlador_video;

architecture Behavioral of Controlador_video is
    signal text_on,video_on, pixel_tick:  std_logic;
    signal text_rgb:   std_logic_vector(7 downto 0);
	 signal rgb_reg, rgb_next: std_logic_vector(7 downto 0); --modificado
	 signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
begin

   -- Instanciando vga_sync
vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>pixel_tick, pixel_x=>pixel_x, pixel_y=>pixel_y);

   -- Instanciando pixel_generation_circuit
 pixel_generation_circuit: entity work.pixel_generation_circuit
      port map(clk=>clk, reset=>reset, x_bcd0=>x_bcd0,
               x_bcd1=>x_bcd1,x2_bcd0=>x2_bcd0, x2_bcd1=>x2_bcd1,
               x2_bcd2=>x2_bcd2,text_on=>text_on,text_rgb=>text_rgb);

-- Definindo o processo 'geral' do registrador rgb, digo geral pois
-- dentro do pixel_generation que  definido a cor dos itens('Especfico').
process (clk,reset)
   begin
      if reset='1' then
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         if (pixel_tick='1') then
           rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
 -- rgb multiplexing circuit
   process(video_on,text_on,text_rgb)
   begin
      if video_on='0' then
		--modificado
         rgb_next <= "00000000"; -- blank the edge/retrace
         elsif text_on='1'  then -- display logo
           rgb_next <= text_rgb;
         else
			--modificado
           rgb_next <= "00000000"; -- 
         end if;
   end process;
   rgb <= rgb_reg;	
 
end Behavioral;
