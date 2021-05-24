library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
entity pixel_generation_circuit is
   port (
      clk, reset: in std_logic;
      x_bcd0, x_bcd1: in std_logic_vector(3 downto 0);
		x2_bcd0, x2_bcd1, x2_bcd2: in std_logic_vector(3 downto 0);
		text_on: out std_logic;
      text_rgb: out  std_logic_vector(7 downto 0)
   );
end pixel_generation_circuit;

architecture arch of pixel_generation_circuit is
   signal video_on, start: std_logic;
   signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	signal rom_addr: std_logic_vector(10 downto 0);
   signal char_addr: std_logic_vector(6 downto 0);
   signal row_addr: std_logic_vector(3 downto 0);
   signal bit_addr: std_logic_vector(2 downto 0);
   signal font_word: std_logic_vector(7 downto 0);
   signal font_bit: std_logic;
	signal display_on: std_logic;
	signal pix_x, pix_y: unsigned(9 downto 0);
	signal hsync, vsync, pixel_tick:  std_logic;
begin
   -- Instanciando vga_sync
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>pixel_tick, pixel_x=>pixel_x, pixel_y=>pixel_y);

   -- Instanciando font rom
   font_unit: entity work.font_rom
      port map(clk=>clk, addr=>rom_addr, data=>font_word);

   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
	---------------------------------------------
   -- Regiao de texto:
   --   - display "X=XX e X^2=ZZZ" on top center
   --   - Na cor branca e fundo preto
   --   - Na escala de fonte de 32x64
   --   - Existem valores que iram mudar de acordo com as entradas
   --   - Logica de que os numeros vao de 30 a 39 no precisando mudar
   --   - o 'prefixo' "011"
   ---------------------------------------------
   row_addr <= std_logic_vector(pix_y(4 downto 1));
   bit_addr <= std_logic_vector(pix_x(3 downto 1));
   ---------------------------------------------
   -- Interface de font rom
   ---------------------------------------------
   rom_addr <= char_addr & row_addr;
   font_bit <= font_word(to_integer(unsigned(not bit_addr)));
   ---------------------------------------------
   display_on <=
      font_bit when pix_y(9 downto 5)=7 and
         (12<= pix_x(8 downto 4) and pix_x(8 downto 4)<=25) else
      '0';
  
   with pix_x(8 downto 4) select
     char_addr <=
        "1011000" when "01100", -- X x58
        "0111101" when "01101", -- = x3d
        "011" & x_bcd1 when "01110", -- X x58
        "011" & x_bcd0 when "01111",	 -- X x58
		  "0000000" when "10000", --   
		  "1100101" when "10001", -- e x65
		  "0000000" when "10010", --   
		  "1011000" when "10011", -- X x58
		  "1011110" when "10100", -- ^ x5e
		  "0110010" when "10101", -- 2 x32
		  "0111101" when "10110", -- = x3d
		  "011" & x2_bcd2 when "10111", -- Z x5a
		  "011" & x2_bcd1 when "11000", -- Z x5a
		  "011" & x2_bcd0 when others; -- Z x5a

	---------------------------------------------
   -- mux for font ROM addresses and rgb
   --   - Se for a regio do texto pinta de branco
   --   - o resto preto.
   ---------------------------------------------
 process(display_on,font_bit)
   begin
      if display_on='1' and font_bit='1' then
            text_rgb <= "11111111"; -- Cor de texto
      else
        text_rgb <= "00000000";  -- background, black
         end if;
   end process;		
text_on<=display_on;
end arch;