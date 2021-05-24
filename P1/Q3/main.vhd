-- Alunos: Alaf e Marcos
-- Disciplina: Sistemas Digitais
-- PRIMEIRA PROVA PARCIAL

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity main is
port (clk, reset,ps2d, ps2c 				: in  std_logic;
		sw						  					: in  std_logic_vector(0 downto 0);
      an											: out std_logic_vector(3 downto 0);
      sseg										: out std_logic_vector(7 downto 0));
end main;

architecture Behavioral of main is
    constant tecla_x 			: std_logic_vector(7 downto 0) :="00100010";-- 22 (Codigo para x)
    constant tecla_y 			: std_logic_vector(7 downto 0) :="00110101";-- 35 (Codigo para y)
    constant tecla_Zero 		: std_logic_vector(7 downto 0) :="01000101";-- 45 (Codigo para 0)
    constant tecla_Um	  		: std_logic_vector(7 downto 0) :="00010110";-- 16 (Codigo para 1)
	 constant tecla_Igual	 	: std_logic_vector(7 downto 0) :="01010101";-- 55 (Codigo para =)

	 type statetype is (wait_botao,contar_x,contar_y,pronto,enviar);
--led k_press, k_normal
	 signal state_reg, state_next				: statetype;
    signal p_done,k_done_tick,p_idle										:std_logic;
	 signal x_reg, y_reg, x_next, y_next, key, x_in, y_in 			:std_logic_vector(7 downto  0);
	 signal z_reg, z_next,p_out									 			:std_logic_vector(15 downto 0);
	 signal p_start,sw_novo,sw_next							     					   :std_logic := '0';
    signal contador_reg,contador_next,dp_in,hex3,hex2,hex1,hex0	:unsigned(3 downto 0);
	 signal dp_in_next,hex3_next, hex2_next, hex1_next,hex0_next	:unsigned(3 downto 0);
	 signal x_un,y_un																:unsigned(7 downto 0);
	 signal z_un																	:unsigned(15 downto 0);
begin
   --=======================================================
   -- instanciacao
   --=======================================================
   kb_code_unit: entity work.kb_code(arch) --teclado da 2
   port map(clk  => clk,  reset=>reset, ps2d => ps2d, ps2c=>ps2c, 
				key => key, k_done_tick => k_done_tick);

	multiplicador_unit: entity work.multiplicador(arch)
   port map(clk => clk, reset => reset, p_start => p_start, x_in => x_in,
				y_in => y_in, p_out => p_out, p_idle => p_idle, p_done => p_done);
	
	disp_hex_mux_unit:entity work.disp_hex_mux(arch)
	port map(clk => clk, reset => reset, hex3 => hex3, hex2 => hex2, hex1 => hex1, hex0 => hex0, dp_in => dp_in, an => an, sseg => sseg);

--=======================================================
   -- FSM para tratar os dados
--=======================================================

process (clk, reset)
   begin
      if reset='1' then
         state_reg <= wait_botao;
			x_reg <= (others=> '0');
         y_reg <= (others=> '0');
         z_reg <= (others=> '0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
			x_reg <= x_next;
         y_reg <= y_next;
         z_reg <= z_next;
			hex3 <= hex3_next;
			hex2 <= hex2_next;
			hex1 <= hex1_next;
			hex0 <= hex0_next;
			dp_in <= dp_in_next;
			sw_novo <= sw_next;
			contador_reg <= contador_next;
      end if;
   end process;

process(sw_novo,state_reg,key,x_reg,y_reg,z_reg,contador_reg,k_done_tick,p_idle,p_done,p_out,hex3,hex2,hex1,hex0,dp_in,sw) -- Maquina de estado para receber dado
begin
			state_next <= state_reg;
			x_next <= x_reg;
			y_next <= y_reg;
			z_next <= z_reg;
			contador_next <= contador_reg;
			p_start<='0';
			x_in<=x_reg;
			y_in<=y_reg;
			x_un <= unsigned(x_in);
			y_un <= unsigned(y_in);
			z_un<= unsigned(z_reg);
			hex3_next <= hex3;
			hex2_next <= hex2;
			hex1_next <= hex1;
			hex0_next <= hex0;
			dp_in_next <= dp_in;
			sw_next <= sw_novo;
	case state_reg is
			when wait_botao =>  --pegar a tecla pressionada e guardar nesse sinal aqui
			  if(sw_next = sw(0)) then
					   contador_next <= (others=> '0'); --zera contador
						if key=tecla_x and k_done_tick='1' then -- Se for x, pega tecla ao soltar
							 state_next <= contar_x;
						elsif key=tecla_y and k_done_tick='1' then -- Se for y, pega tecla ao soltar
							 state_next <= contar_y;
						elsif key=tecla_Igual and k_done_tick='1' then -- Se for '=', pega tecla ao soltar
							 if p_idle='1' then -- Se esta ocioso.
								  x_next<=x_reg;
								  y_next<=y_reg;
								  p_start<='1';
								  state_next <= pronto;
							 else
								  state_next <= wait_botao;
							 end if;
						end if;
				else
					state_next <= enviar;
				end if;


			when contar_x => -- Estado que inclui bits em x
            if(contador_reg = 8) then 		  --passou todos os bits
						state_next <= enviar;--pronto; 
				elsif key=tecla_Zero and k_done_tick='1' then  -- se apertar 0, ao soltar
                        x_next<= x_reg(6 downto 0) & '0';
                        contador_next <= contador_reg + 1;
                        state_next <= contar_x;
            elsif key=tecla_Um and k_done_tick='1' then		 -- se apertar 1, ao soltar
                        x_next<= x_reg(6 downto 0) & '1';
                        contador_next <= contador_reg + 1;
                        state_next <= contar_x;
            else
                state_next <= contar_x;
            end if;

			when contar_y => -- Estado que inclui bits em y
            if(contador_reg = 8) then 		  --passou todos os bits
						state_next <= enviar;--pronto;
				elsif key=tecla_Zero and k_done_tick='1' then -- se apertar 0, ao soltar
                        y_next<= y_reg(6 downto 0) & '0';
                        contador_next <= contador_reg + 1;
                        state_next <= contar_y;
            elsif key=tecla_Um and k_done_tick='1' then -- se apertar 1, ao soltar
                        y_next<= y_reg(6 downto 0) & '1';
                        contador_next <= contador_reg + 1;
                        state_next <= contar_y;
            else
                state_next <= contar_y;
            end if;
				
			when pronto => -- Estado que escreve bits em z
				if(p_done = '1') then
					z_next <= p_out;
					state_next <= enviar;
				else
					state_next <= pronto;
				end if;
				
			when enviar => -- Estado que envia x,y,z para o display
					if(sw(0) = '1') then
								if(z_next(15)='0') then -- Senão e (se for positivo)-- em tese não precisava mas quis me resguardar
									dp_in_next <="1111"; -- desaciona os pontos a direita
								else
									dp_in_next <="0111"; -- aciona o ponto mais a esquerda
									z_un <= unsigned(not(z_next))+1; -- complemento de 2
								end if;
								hex3_next <= z_un(15 downto 12); -- recebe o valor de z nos displays
								hex2_next <= z_un(11 downto 8); -- recebe o valor de z nos displays
								hex1_next <= z_un(7 downto 4); -- recebe o valor de z nos displays
								hex0_next <= z_un(3 downto 0); -- recebe o valor de z nos displays
					elsif(sw(0) = '0')then
							if(x_in(7)='1') then 
								x_un <= unsigned(not(x_in))+1; -- complemento de 2
							end if;
							if(y_in(7)='1') then
								y_un <= unsigned(not(y_in))+1; -- complemento de 2
							end if;
							--definindo o sinal no display
							if((x_in(7) = '1')and(y_in(7)='1')) then dp_in_next <="0101"; 
							elsif((x_in(7) = '1')and(y_in(7)='0'))then dp_in_next <= "0111";
							elsif((x_in(7) = '0')and(y_in(7)='1'))then dp_in_next <= "1101";
							elsif((x_in(7) = '0')and(y_in(7)='0'))then dp_in_next <= "1111";
							end if;
							hex1_next <= y_un(7 downto 4); -- recebe o valor de y nos dois primeiros displays
							hex0_next <= y_un(3 downto 0); -- recebe o valor de y nos dois primeiros displays
							hex3_next <= x_un(7 downto 4); -- recebe o valor de x nos dois ultimos displays
							hex2_next <= x_un(3 downto 0); -- recebe o valor de x nos dois ultimos displays
					end if;
				sw_next    <= sw(0);
				state_next <= wait_botao;
	end case;	
end process;
end Behavioral;
