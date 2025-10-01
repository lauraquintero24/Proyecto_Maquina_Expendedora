library ieee;
use ieee.std_logic_1164.all;

entity DecoHexadecimal is
    port(
       A : in  std_logic_vector(3 downto 0);
       Display_0 : out std_logic_vector(6 downto 0)
    );
end DecoHexadecimal;

architecture arch_DecoHexadecimal of DecoHexadecimal is
begin
   
    Display_0 <= "0111111" when (A="0000") else  -- 0
                 "0000110" when (A="0001") else  -- 1
                 "1011011" when (A="0010") else  -- 2
                 "1001111" when (A="0011") else  -- 3
                 "1100110" when (A="0100") else  -- 4
                 "1101101" when (A="0101") else  -- 5
                 "1111101" when (A="0110") else  -- 6
                 "0000111" when (A="0111") else  -- 7
                 "1111111" when (A="1000") else  -- 8
                 "1101111" when (A="1001") else  -- 9
                 "1110111" when (A="1010") else  -- A
                 "1111100" when (A="1011") else  -- b
                 "0111001" when (A="1100") else  -- C
                 "1011110" when (A="1101") else  -- d
                 "1111001" when (A="1110") else  -- E
                 "1110001" when (A="1111") else  -- F
                 "0000000";                      -- apagado

end arch_DecoHexadecimal;
