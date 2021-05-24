-- Aluno: Alaf do Nascimento Santos;
-- Disciplina: Sistemas Digitais
-- EXERCCIO: OCUPACAO DE ESTACIONAMENTO

--Bibliotecas e Pacotes
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Declaracao da entidade da nossa maquina de estados
entity FSM is
    port ( clk, reset, a, b : in  STD_LOGIC; entrou, saiu : out  STD_LOGIC);
end FSM;

--Implementacao da Arquitetura
architecture arch of FSM is
	type estado is (estado_00, estado_10_Entrando, estado_11_Entrando, estado_01_Entrando, estado_10_Saindo, estado_11_Saindo, estado_01_Saindo);
	signal estadoAtual, proximoEstado: estado;
   signal sensores : STD_LOGIC_VECTOR(1 downto 0);
 --   variable cont: integer:=0;
begin
	sensores <= a & b; -- sensores recebe os valores de a e b concatenados para usarmos no case

    --process que verifica a ocorrencia de um clk ou se o reset foi precionado
	process(clk, reset)
	begin
		if reset = '1' then
			estadoAtual <= estado_00;
           -- cont := 0;

		elsif (clk'event and clk='1') then
			estadoAtual <= proximoEstado;
		end if;
	end process;

    --process que faz a verificao de se um carro entrou ou saiu a partir da mudana de estado dos sensores
	process(estadoAtual, sensores)
	begin
		proximoEstado <= estadoAtual; entrou <= '0'; saiu <= '0'; --cuida para nao criarmos latches

		case estadoAtual is
			when estado_00 => 
                    if sensores = "10" then proximoEstado <= estado_10_Entrando; 
                    elsif sensores = "01" then proximoEstado <= estado_01_Saindo;
                    end if; 
			
			when estado_10_Entrando => 	
                    if sensores = "00" then proximoEstado <= estado_00;
					elsif sensores = "11" then proximoEstado <= estado_11_Entrando;
					end if; 
								
			when estado_11_Entrando => 	
                    if sensores = "01" then proximoEstado <= estado_01_Entrando; 
					elsif sensores = "10" then proximoEstado <= estado_10_Entrando;
					end if; 
							
			when estado_01_Entrando => 	
                    if sensores = "00" then proximoEstado <= estado_00; 
                        entrou <= '1';-- cont := cont + 1;  
                    elsif sensores = "11" then proximoEstado <= estado_11_Entrando; 
					end if; 							
			
            when estado_01_Saindo => 
                    if sensores = "00" then proximoEstado <= estado_00;
					elsif sensores = "11" then proximoEstado <= estado_11_Saindo;
					end if; 
					
			when estado_11_Saindo => 
                    if sensores = "01" then proximoEstado <= estado_01_Saindo;
					elsif sensores = "10" then 	proximoEstado <= estado_10_Saindo; 
                    end if; 
						
			when estado_10_Saindo => 	
                    if sensores = "00" then proximoEstado <= estado_00; 
                        saiu <= '1'; --
								--cont := cont - 1; 
					elsif sensores = "11" then proximoEstado <= estado_11_Saindo;
					end if; 
        end case;							
	end process;
end arch;
