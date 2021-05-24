-- Listing 16.2
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Prova is
   port(
      clk, reset: in std_logic;
      sw: in std_logic_vector(7 downto 0);
      btn: in std_logic_vector(1 downto 0);
		rgb: out std_logic_vector(7 downto 0);
		hsync, vsync: out std_logic
   );
end Prova;

architecture arch of Prova is
   -- KCPSM3/ROM signals
   signal address: std_logic_vector(9 downto 0);
   signal instruction: std_logic_vector(17 downto 0);
   signal port_id: std_logic_vector(7 downto 0);
   signal in_port: std_logic_vector(7 downto 0);
	signal out_port: std_logic_vector(7 downto 0);
   signal write_strobe, read_strobe: std_logic;
   signal interrupt, interrupt_ack: std_logic;
   signal kcpsm_reset: std_logic;
   -- I/O port signals
   -- output enable - As saidas so 5
   signal en_d: std_logic_vector(4 downto 0);
   -- 5 registradores para armazenar os valores de x e x^2 em BCD
   signal ds4_reg,ds3_reg, ds2_reg: std_logic_vector(3 downto 0);
   signal ds1_reg, ds0_reg: std_logic_vector(3 downto 0);
   -- DOIS BOTES
   signal btnc_flag_reg, btnc_flag_next: std_logic;
   signal btns_flag_reg, btns_flag_next: std_logic;
   signal set_btnc_flag, set_btns_flag: std_logic;
   signal clr_btn_flag: std_logic;
begin
   -- =====================================================
   --  I/O modules - Debounce
   -- =====================================================
   btnc_db_unit: entity work.debounce
      port map(
         clk=>clk, reset=>reset, sw=>btn(0),
         db_level=>open, db_tick=>set_btnc_flag);
   btns_db_unit: entity work.debounce
      port map(
         clk=>clk, reset=>reset, sw=>btn(1),
         db_level=>open, db_tick=>set_btns_flag);
   -- =====================================================
   --  KCPSM and ROM instantiation
   -- =====================================================
   proc_unit: entity work.kcpsm3
      port map(
         clk=>clk, reset =>kcpsm_reset,
         address=>address, instruction=>instruction,
         port_id=>port_id, write_strobe=>write_strobe,
         out_port=>out_port, read_strobe=>read_strobe,
         in_port=>in_port, interrupt=>interrupt,
         interrupt_ack=>interrupt_ack);
-- Colocar embaixo o nome do arquivo vhd gerado
  questao2 : entity work.questao2
      port map(
          clk => clk, address=>address,
          instruction=>instruction);
   -- Unused inputs on processor
   kcpsm_reset <= '0';
   interrupt <= '0';
	
	-- =====================================================
   --  Controlador instantiation
   -- =====================================================
	Controlador_video: entity work.Controlador_video
      port map(
         clk=>clk, reset=>reset, x_bcd0=>ds0_reg,x_bcd1=>ds1_reg,
			x2_bcd0=>ds2_reg,x2_bcd1=>ds3_reg,x2_bcd2=>ds4_reg,
			rgb=>rgb,hsync=>hsync,vsync=>vsync);
   -- =====================================================
   --  output interface - modificar para a saida utilizada
   -- =====================================================
   --    outport port id:
   --      0x00: ds0 (X0)
   --      0x40: ds1 (X1)
   --      0x:80 ds2 (X^2 0)
   --      0x:c0 ds3 (X^2 1)
   --      0x:20 ds4 (X^2 2)
   -- =====================================================
	process (clk)
   begin
      if (clk'event and clk='1') then
         if en_d(0)='1' then ds0_reg <= out_port(3 downto 0); end if;
         if en_d(1)='1' then ds1_reg <= out_port(3 downto 0); end if;
         if en_d(2)='1' then ds2_reg <= out_port(3 downto 0); end if;
         if en_d(3)='1' then ds3_reg <= out_port(3 downto 0); end if;
			if en_d(4)='1' then ds4_reg <= out_port(3 downto 0); end if;
      end if;
   end process;
  -- decoding circuit for enable signals
   process(port_id,write_strobe)
   begin
      en_d <= (others=>'0');
      if write_strobe='1' then
         case port_id(7 downto 0) is
            when "00000000" => en_d <="00001";
            when "01000000" => en_d <="00010";
            when "10000000" => en_d <="00100";
            when "11000000" => en_d <="01000";
				when others => en_d <="10000"; 
         end case;
      end if;
   end process;	
  -- =====================================================
   --  input interface
   -- =====================================================
   --    input port id
   --      0x00: flag
   --      0x01: switch
   -- =====================================================
   -- input register (for flags)
   process(clk)
   begin
      if (clk'event and clk='1') then
         btnc_flag_reg <= btnc_flag_next;
         btns_flag_reg <= btns_flag_next;
      end if;
   end process;

   btnc_flag_next <= '1' when set_btnc_flag='1' else
                     '0' when clr_btn_flag='1' else
                      btnc_flag_reg;
   btns_flag_next <= '1' when set_btns_flag='1' else
                     '0' when clr_btn_flag='1' else
                      btns_flag_reg;
   -- decoding circuit for clear signals
   clr_btn_flag <='1' when read_strobe='1' and
                           port_id(0)='0' else
                  '0';
  -- input multiplexing
   process(port_id,btns_flag_reg,btnc_flag_reg,sw)
   begin
      case port_id(0) is
         when '0' =>
            in_port <= "000000" &
                       btns_flag_reg & btnc_flag_reg;
         when others =>
            in_port <= sw;
      end case;
   end process;
end arch;						