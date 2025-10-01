library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Tecladomatricial is
    port(
       clk       : in  std_logic;
       reset     : in  std_logic;
       Fila      : in  std_logic_vector(3 downto 0);
       Columna   : out std_logic_vector(3 downto 0);
       Tecla     : out std_logic_vector(3 downto 0);
       Display_0 : out std_logic_vector(6 downto 0)
    );
end Tecladomatricial;

architecture arch_Tecladomatricial of Tecladomatricial is

    component DecoHexadecimal
       port(
          A : in  std_logic_vector(3 downto 0);
          Display_0 : out std_logic_vector(6 downto 0)
        );
    end component;

    signal col_sel  : integer range 0 to 3 := 0;
    signal tecla_sig: std_logic_vector(3 downto 0) := (others => '0');

begin

    process(clk, reset)
		begin
          if reset = '1' then
				col_sel  <= 0;
				Columna  <= "1110";
            tecla_sig <= "0000";
				
          elsif rising_edge(clk) then
		  -- Escaneo de columnas
             case col_sel is
                when 0 => Columna <= "1110";
                when 1 => Columna <= "1101";
                when 2 => Columna <= "1011";
                when 3 => Columna <= "0111";
             end case;

            
             if Fila /= "1111" then
                   case col_sel is
                      when 0 =>
                         case Fila is
                            when "1110" => tecla_sig <= "0001"; -- 1
                            when "1101" => tecla_sig <= "0100"; -- 4
                            when "1011" => tecla_sig <= "0111"; -- 7
                            when "0111" => tecla_sig <= "1110"; -- E
                            when others => null;
                         end case;
							 when 1 =>
                         case Fila is
                            when "1110" => tecla_sig <= "0010"; -- 2
                            when "1101" => tecla_sig <= "0101"; -- 5
                            when "1011" => tecla_sig <= "1000"; -- 8
                            when "0111" => tecla_sig <= "0000"; -- 0
                            when others => null;
                         end case;
                      when 2 =>
                         case Fila is
                            when "1110" => tecla_sig <= "0011"; -- 3
                            when "1101" => tecla_sig <= "0110"; -- 6
                            when "1011" => tecla_sig <= "1001"; -- 9
                            when "0111" => tecla_sig <= "1111"; -- F
                            when others => null;
                         end case;
                      when 3 =>
                         case Fila is
                            when "1110" => tecla_sig <= "1010"; -- A
                            when "1101" => tecla_sig <= "1011"; -- B
                            when "1011" => tecla_sig <= "1100"; -- C
                            when "0111" => tecla_sig <= "1101"; -- D
                            when others => null;
                         end case;
                   end case;
             end if;

           
             if col_sel = 3 then
                col_sel <= 0;
						 else
							col_sel <= col_sel + 1;
             end if;
          end if;
    end process;


    Tecla <= tecla_sig;

    U1: DecoHexadecimal 
		 port map (
			A => tecla_sig,
			Display_0 => Display_0
    );

end arch_Tecladomatricial;
