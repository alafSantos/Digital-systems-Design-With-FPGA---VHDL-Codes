--Aluno: Alaf do Nascimento Santos
--Matricula: 2017100781
--Disciplina: Sistemas Digitais

-- Listing 13.7
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pong_graph is
 port(clk, reset: std_logic;
      pixel_x,pixel_y: in std_logic_vector(9 downto 0);
      gra_still: in std_logic;
      graph_on, hit, miss: out std_logic;
      rgb: out std_logic_vector(7 downto 0));
end pong_graph;

architecture arch of pong_graph is
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
  
   constant WALL_X_L: integer:=0;
   constant WALL_X_R: integer:=1;

   constant WALL_X_L2: integer:=639;
   constant WALL_X_R2: integer:=640;

   constant BALL_SIZE: integer:=8; -- 8
   signal ball_x_l, ball_x_r: unsigned(9 downto 0);
   signal ball_y_t, ball_y_b: unsigned(9 downto 0);
   signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
   signal ball_y_reg, ball_y_next: unsigned(9 downto 0);
   signal ball_vx_reg, ball_vx_next: unsigned(9 downto 0);
   signal ball_vy_reg, ball_vy_next: unsigned(9 downto 0);
   constant BALL_V_P: unsigned(9 downto 0)
            :=to_unsigned(2,10);
   constant BALL_V_N: unsigned(9 downto 0)
            :=unsigned(to_signed(-2,10));
   type rom_type is array (0 to 7) of
        std_logic_vector (7 downto 0);
   constant BALL_ROM: rom_type :=
   (
      "00111100", --   ****
      "01111110", --  ******
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "01111110", --  ******
      "00111100"  --   ****
   );
   signal rom_addr, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;
   signal wall_on,wall_on2, sq_ball_on, rd_ball_on,teste: std_logic;
   signal wall_rgb,wall_rgb2, bar_rgb, ball_rgb:
          std_logic_vector(7 downto 0);--modificado
   signal refr_tick: std_logic;
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         ball_x_reg <= (OTHERS=>'0');
         ball_y_reg <= (OTHERS=>'0');
         ball_vx_reg <= ("0000000100");
         ball_vy_reg <= ("0000000100");
      elsif (clk'event and clk='1') then
         ball_x_reg <= ball_x_next;
         ball_y_reg <= ball_y_next;
         ball_vx_reg <= ball_vx_next;
         ball_vy_reg <= ball_vy_next;
      end if;
   end process;
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
   -- wall
   wall_on <=
      '1' when (WALL_X_L<=pix_x) and (pix_x<=WALL_X_R) else
      '0';

   wall_on2 <=
      '0' when (WALL_X_L2>=pix_x) and (pix_x>=WALL_X_R2) else
      '1';
	--modificado
   wall_rgb <= "11111100"; -- amarelo, assim temos a visao de nao existencia dos muros
   wall_rgb2 <= "11111100"; -- amarelo
   -- square ball
   ball_x_l <= ball_x_reg;
   ball_y_t <= ball_y_reg;
   ball_x_r <= ball_x_l + BALL_SIZE - 1;
   ball_y_b <= ball_y_t + BALL_SIZE - 1;
   sq_ball_on <=
      '1' when (ball_x_l<=pix_x) and (pix_x<=ball_x_r) and
               (ball_y_t<=pix_y) and (pix_y<=ball_y_b) else
      '0';
   -- round ball
   rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
   rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
   rom_data <= BALL_ROM(to_integer(rom_addr));
   rom_bit <= rom_data(to_integer(not rom_col));
   rd_ball_on <=
      '1' when (sq_ball_on='1') and (rom_bit='1') else
      '0';
   --modificado
	ball_rgb <= "11100000";   -- red
   -- new ball position
   ball_x_next <=
      to_unsigned((MAX_X)/2,10) when gra_still='1' else
      ball_x_reg + ball_vx_reg when refr_tick='1' else
      ball_x_reg ;
   ball_y_next <=
      to_unsigned((MAX_Y)/2,10) when gra_still='1' else
      ball_y_reg + ball_vy_reg when refr_tick='1' else
      ball_y_reg ;
   -- new ball velocity
   -- wuth new hit, miss signals
   process(ball_vx_reg,ball_vy_reg,ball_y_t,ball_x_l,ball_x_r,
           ball_y_t,ball_y_b,gra_still)
   begin
      hit <='0';
      miss <='0';
      ball_vx_next <= ball_vx_reg;
      ball_vy_next <= ball_vy_reg;
      if gra_still='1' then            --initial velocity
         ball_vx_next <= BALL_V_N;
         ball_vy_next <= BALL_V_P;
      elsif ball_y_t < 1 then          -- reach top
         ball_vy_next <= BALL_V_P;
      elsif ball_y_b > (MAX_Y-1) then  -- reach bottom
         ball_vy_next <= BALL_V_N;
      elsif ball_x_l <= WALL_X_R  then -- reach wall
         ball_vx_next <= BALL_V_P;     -- bounce back
     -- elsif ball_x_l >= WALL_X_R then
       --     ball_vx_next <= BALL_V_N;
      elsif (ball_x_r>MAX_X) then     -- reach right border
         miss <= '1';                 -- a miss
      end if;
   end process;
   -- rgb multiplexing circuit
   process(wall_on,rd_ball_on,wall_rgb,ball_rgb)
   begin
      if wall_on='1' then
         rgb <= wall_rgb;
      elsif wall_on2 = '1' then
        rgb <= wall_rgb2;
      elsif rd_ball_on='1' then
         rgb <= ball_rgb;
      else
         rgb <= "11111100"; -- yellow background
      end if;
   end process;
   -- new graphic_on signal
   graph_on <= wall_on or wall_on2 or rd_ball_on;
end arch;
