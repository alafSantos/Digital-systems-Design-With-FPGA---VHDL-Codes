--Aluno: Alaf do Nascimento Santos
--Matricula: 2017100781
--Disciplina: Sistemas Digitais

-- Listing 13.6
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
entity pong_text is
   port(clk, reset: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        ball: in std_logic_vector(1 downto 0);
        text_on: out std_logic;
        text_rgb: out std_logic_vector(7 downto 0));
end pong_text;

architecture arch of pong_text is
   signal pix_x, pix_y: unsigned(9 downto 0);
   signal rom_addr: std_logic_vector(10 downto 0);
   signal char_addr, char_addr_s, char_addr_l, char_addr_r,
          char_addr_o: std_logic_vector(6 downto 0);
   signal row_addr, row_addr_s, row_addr_l,row_addr_r,
          row_addr_o: std_logic_vector(3 downto 0);
   signal bit_addr, bit_addr_s, bit_addr_l,bit_addr_r,
          bit_addr_o: std_logic_vector(2 downto 0);
   signal font_word: std_logic_vector(7 downto 0);
   signal font_bit: std_logic;
   signal score_on, logo_on, rule_on, over_on: std_logic;
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   font_unit: entity work.font_rom
      port map(clk=>clk, addr=>rom_addr, data=>font_word);
   logo_on <=
      '1' when pix_y(9 downto 7)=2 and
         (3<= pix_x(9 downto 6) and pix_x(9 downto 6)<=6) else
      '0';
   row_addr_l <= std_logic_vector(pix_y(6 downto 3));
   bit_addr_l <= std_logic_vector(pix_x(5 downto 3));
   with pix_x(8 downto 6) select
     char_addr_l <=
        "1010101" when "011", -- U 
        "1000110" when "100", -- F 
        "1000101" when "101", -- E 
        "1010011" when others; --S 
   process(logo_on,pix_x,pix_y,font_bit, char_addr_s,char_addr_l,char_addr_r,char_addr_o, row_addr_s,row_addr_l,row_addr_r,row_addr_o, bit_addr_s,bit_addr_l,bit_addr_r,bit_addr_o)
   begin
      text_rgb <= "11111100";  -- background, yellow
      if logo_on='1' then
         char_addr <= char_addr_l;
         row_addr <= row_addr_l;
         bit_addr <= bit_addr_l;
         if font_bit='1' then
            text_rgb <= "00011111";
         end if;
      end if;
   end process;
   text_on <= logo_on;
   rom_addr <= char_addr & row_addr;
   font_bit <= font_word(to_integer(unsigned(not bit_addr)));
end arch;