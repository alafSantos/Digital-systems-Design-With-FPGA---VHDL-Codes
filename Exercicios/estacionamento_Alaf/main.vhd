-- Aluno: Alaf do Nascimento Santos;
-- Disciplina: Sistemas Digitais
-- EXERCCIO: OCUPACAO DE ESTACIONAMENTO

--Bibliotecas e Pacotes
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Declaracao da entidade principal
entity main is
    Port ( clk, reset : in  STD_LOGIC;
           btn : in  STD_LOGIC_VECTOR (1 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           sseg : out  STD_LOGIC_VECTOR (7 downto 0));
end main;

--Implementacao da Arquitetura
architecture arch of main is
	signal inc, dec, a, b: std_logic;
	signal d2, d1, d0: std_logic_vector(3 downto 0);
begin
   debounce_a: entity work.debounce (fsmd_arch)
   port map(clk => clk, reset => reset, sw => btn(1), db_level => a, db_tick =>open);

   debounce_b: entity work.debounce (fsmd_arch)
   port map(clk => clk, reset => reset, sw => btn(0), db_level => b, db_tick =>open);

   sensoriamento: entity work.FSM (arch)
   port map(clk => clk, reset => reset, a => a, b => b, entrou => inc, saiu => dec);

   contar: entity work.contador (arch)
   port map(clk => clk, reset => reset, inc => inc, dec => dec, d2 => d2, d1 => d1, d0 => d0);
			  	 
   disp_mux0: entity work.disp_hex_mux (arch)
   port map(clk => clk, reset => reset, hex3 =>"0000", hex2 => d2, hex1 => d1, hex0 => d0, dp_in =>"1111", an => an, sseg => sseg);
end arch;