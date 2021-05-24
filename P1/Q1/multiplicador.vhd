-- Alunos: Alaf e Marcos
-- Disciplina: Sistemas Digitais
-- PRIMEIRA PROVA PARCIAL

--declaracao de bibliotecas e pacotes
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--declaracao da entidade
entity multiplicador is
   port(clk, reset, p_start  : in STD_LOGIC;
		  x_in, y_in			  : in STD_LOGIC_VECTOR(7 downto 0);
		  p_out					  : out STD_LOGIC_VECTOR(15 downto 0);
		  p_idle, p_done		  : out STD_LOGIC);
end multiplicador;

--implementacao da arquitetura do multiplicador
architecture arch of multiplicador is
   type   estado is (aguardando, inicializando, deslocando);
	signal estadoAtual, proximoEstado							: estado;
	signal x_reg, x_next, y_reg, y_next, resultado, acum	: UNSIGNED(7 downto 0);
	signal produto_reg, produto_next								: UNSIGNED(16 downto 0);
	signal contador_reg, contador_next							: UNSIGNED(3 downto 0);
begin
	resultado <= produto_reg(16 downto 9) + x_reg 				when produto_reg(1 downto 0) = "01" else 	--soma
					 produto_reg(16 downto 9) + (not(x_reg) + 1) when produto_reg(1 downto 0) = "10" else	--subtracao
					 produto_reg(16 downto 9);																					--somente desloca (feito em deslocando)
	p_out <= std_logic_vector(produto_reg(16 downto 1));	--saida do multiplicador
	acum  <= (others => '0'); 										--o acumulador sempre comeca nulo
   process(clk, reset)
   begin
		if(reset = '1') then --zera os registradores e aguarda entradas (vai pro estado aguardando)
			estadoAtual <= aguardando; 
			contador_reg<= (others => '0'); produto_reg <= (others => '0');
			y_reg 		<= (others => '0'); x_reg 		  <= (others => '0');
      elsif(clk'event and clk='1') then --quando tem uma subida de clock ele vai para os proximos valores que estavam na entrada de cada flip-flop
			estadoAtual <= proximoEstado;
			contador_reg <= contador_next;
			produto_reg <= produto_next;
			y_reg <= y_next;
			x_reg <= x_next;
		end if;	
   end process;

   process(estadoAtual, x_reg, y_reg, produto_reg, p_start, x_in, y_in, contador_reg,resultado)
   begin
		--deixa o valor atual mantido, mas pode ser mudado no case
		y_next <= y_reg;
		x_next <= x_reg;
		p_done <= '0';
		p_idle <= '0';
		proximoEstado <= estadoAtual;
		produto_next  <= produto_reg;
		contador_next <= contador_reg;
	   case estadoAtual is
			when aguardando =>		--fica disponivel para uma multiplicacao
				p_idle <= '1';
				if p_start = '1' then --se apertou o botao start, joga os valores de cada entrada nos regs
					x_next <= unsigned(x_in);
					y_next <= unsigned(y_in);
					proximoEstado <= inicializando;	--define que vai para a inicializacao dos operadores
				end if;	
			when inicializando =>	--primeira linha do exemplo dado, "iteracao 0"
				produto_next <=  acum & y_reg & acum(0);
				contador_next <= acum(3 downto 0);
				proximoEstado <= deslocando;
			when deslocando =>
					if(contador_reg = 8) then 		  --acabou a multiplicacao
						p_done <= '1';			  		  --mostra que a multiplicacao acabou
						proximoEstado <= aguardando; --aguarda nova multiplicacao
					else
						produto_next(16) 		     <= resultado(7);
						produto_next(15 downto 8) <= resultado(7 downto 0); 
						produto_next(7 downto 0)  <= produto_reg(8 downto 1);
						contador_next <= contador_reg + 1; --contabiliza iteracao
					end if;
				end case;
		end process;
	end arch;
