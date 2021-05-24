-- Aluno: Alaf do Nascimento Santos;
-- Disciplina: Sistemas Digitais
-- EXERCCIO: OCUPACAO DE ESTACIONAMENTO

--Bibliotecas e Pacotes
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Declaracao da entidade do contador
entity contador is
    Port ( clk, reset, inc, dec : in  STD_LOGIC; d2, d1, d0: out std_logic_vector(3 downto 0));
end contador;

--Implementacao da Arquitetura
architecture arch of contador is
	signal d0_reg, d0_next, d1_reg, d1_next, d2_reg, d2_next: unsigned (3 downto 0);
	
begin
   process(clk, reset)
   begin
        if (reset = '1') then
            d2_reg <= "0000"; d1_reg <= "0000"; d0_reg <= "0000";
        elsif (clk'event and clk='1') then
            d2_reg <= d2_next; d1_reg <= d1_next; d0_reg <= d0_next;
        end if;
   end process;

   process(d0_reg,d1_reg,d2_reg,inc,dec)
   begin
      -- default
      d0_next <= d0_reg;
      d1_next <= d1_reg;
      d2_next <= d2_reg;

	if (d2_reg /= 2) and  (inc = '1') then
         if (d0_reg/=9) then
            d0_next <= d0_reg + 1;
         else       -- reach XX9
            d0_next <= "0000";
            if (d1_reg/=9) then
               d1_next <= d1_reg + 1;
            else    -- reach X99
               d1_next <= "0000";
               if (d2_reg/=2) then --vai de 0 a 200 
                  d2_next <= d2_reg + 1;
               end if;
            end if;
         end if;
		elsif (dec = '1') then
				if (d0_reg/=0) then
					d0_next <= d0_reg - 1;
				else       -- reach XX9
					if(d1_reg /= "0000") then
						d1_next <= d1_reg - 1;
						d0_next <= "1001";
					elsif(d2_reg /= "0000") then
						d2_next <= d2_reg - 1;
						d0_next <= "1001";
						d1_next <= "1001";
					end if;
				end if;
		end if;
   end process;
   -- output logic
   d0 <= std_logic_vector(d0_reg);
   d1 <= std_logic_vector(d1_reg);
   d2 <= std_logic_vector(d2_reg);
end arch;
--codigo baseado no cronometro do projeto 09
