library ieee;
use ieee.std_logic_1164.all;

entity dec_bcd is
	
	port
	(
		-- Input ports
		A	: in  std_logic_vector(3 downto 0);
		B	: in  std_logic_vector(3 downto 0);

		-- Output ports
		D0	: out std_logic_vector(6 downto 0);
		D1	: out std_logic_vector(6 downto 0)
		
	);
end dec_bcd;



-- Library Clause(s) (optional)
-- Use Clause(s) (optional)

architecture arch_dec_bcd of dec_bcd is

	-- Declarations (optional)

begin

 with A select
    D0 <= "1000000" when "0000",  -- 0
           "1111001" when "0001",  -- 1
           "0100100" when "0010",  -- 2
           "0110000" when "0011",  -- 3
           "0011001" when "0100",  -- 4
           "0010010" when "0101",  -- 5
           "0000010" when "0110",  -- 6
           "1111000" when "0111",  -- 7
           "0000000" when "1000",  -- 8
           "0010000" when "1001",  -- 9
           "1111111" when others;  -- apagado
 with B select
    D1 <= "1000000" when "0000",  -- 0
           "1111001" when "0001",  -- 1
           "0100100" when "0010",  -- 2
           "0110000" when "0011",  -- 3
           "0011001" when "0100",  -- 4
           "0010010" when "0101",  -- 5
           "0000010" when "0110",  -- 6
           "1111000" when "0111",  -- 7
           "0000000" when "1000",  -- 8
           "0010000" when "1001",  -- 9
           "1111111" when others;  -- apagado



end arch_dec_bcd;

