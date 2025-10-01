library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd7seg is

	port
	(
		A	: in  std_logic_vector(3 downto 0);
		B   : in  std_logic_vector(3 downto 0);
	
		Display_0 : out std_logic_vector(6 downto 0);
		Display_1 : out std_logic_vector(6 downto 0)
	);
end bcd7seg;


architecture arch_bcd7seg of bcd7seg is

	--signal AB : std_logic_vector(7 downto 0);
	
begin
	--AB <= A & B;

	
	Display_0 <= "1000000" when (A="0000" ) else 
	             "1111001" when (A="0001" ) else 
					 "0100100" when (A="0010" ) else
					 "0110000" when (A="0011" ) else 
					 "0011001" when (A="0100" ) else 
					 "0010010" when (A="0101" ) else 
					 "0000010" when (A="0110" ) else 
					 "1111000" when (A="0111" ) else 
					 "0000000" when (A="1000" ) else
					 "0011000" when (A="1001" ) else
					 "1111111";
					 
	Display_1 <= "1000000" when (B="0000" ) else 
	             "1111001" when (B="0001" ) else 
					 "0100100" when (B="0010" ) else
					 "0110000" when (B="0011" ) else 
					 "0011001" when (B="0100" ) else 
					 "0010010" when (B="0101" ) else 
					 "0000010" when (B="0110" ) else 
					 "1111000" when (B="0111" ) else 
					 "0000000" when (B="1000" ) else
					 "0011000" when (B="1001" ) else
					 "1111111";

end arch_bcd7seg;