library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador_monedas_optico is
    Port ( 
        Clk      : in  std_logic;
        Reset    : in  std_logic;
        Sensor   : in  std_logic_vector(1 downto 0);
        CNT      : out integer range 0 to 99
    );
end contador_monedas_optico;

architecture arch of contador_monedas_optico is
    signal valor_actual    : integer range 0 to 99 := 0;
    signal estado_anterior : std_logic_vector(1 downto 0) := "00";
    
begin

    process(Clk, Reset)
        variable contador : integer range 0 to 500000 := 0;
    begin
        if Reset = '1' then
            valor_actual    <= 0; -- saldo
            estado_anterior <= "00";
            contador := 0;
            
        elsif rising_edge(Clk) then
		  
            if contador < 500000 then
                contador := contador + 1;
            else
                contador := 0;
					 
					 
                --detecta el flanco de subida
                if estado_anterior = "00" and Sensor /= "00" then
                    case Sensor is
                        when "01" =>
                            if valor_actual <= 94 then
                                valor_actual <= valor_actual + 5;
                            else
                                valor_actual <= 99;
                            end if;
                            
                        when "10" =>
                            if valor_actual <= 89 then
                                valor_actual <= valor_actual + 10;
                            else
                                valor_actual <= 99;
                            end if;
                            
                        when others => 
                            null;
                    end case;
                end if;
                
                estado_anterior <= Sensor;
            end if;
        end if;
    end process;
    
    CNT <= valor_actual;
    
end arch;