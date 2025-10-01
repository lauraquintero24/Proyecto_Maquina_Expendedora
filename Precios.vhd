library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Precios is
    port(
        sel        : in  unsigned(3 downto 0); -- Producto seleccionado
        precio_out : out unsigned(4 downto 0) 
    );
end Precios;

architecture arch_Precios of Precios is
begin
    process(sel)
    begin
        case sel is
            when "0001" => precio_out <= to_unsigned(5, 5); 
            when "0010" => precio_out <= to_unsigned(5, 5); 
            when "0011" => precio_out <= to_unsigned(5, 5); 
            when "0100" => precio_out <= to_unsigned(10, 5); 
            when "0101" => precio_out <= to_unsigned(10, 5);
            when "0110" => precio_out <= to_unsigned(10, 5); 
            when "0111" => precio_out <= to_unsigned(15, 5);
            when "1000" => precio_out <= to_unsigned(15, 5); 
            when "1001" => precio_out <= to_unsigned(15, 5); 
            when "1010" => precio_out <= to_unsigned(20, 5); 
            when "1011" => precio_out <= to_unsigned(20, 5); 
            when "1100" => precio_out <= to_unsigned(20, 5); 
            when "1101" => precio_out <= to_unsigned(25, 5); 
            when "1110" => precio_out <= to_unsigned(25, 5); 
            when "1111" => precio_out <= to_unsigned(30, 5);
            when others => precio_out <= to_unsigned(31, 5); 
        end case;
    end process;
end arch_Precios;