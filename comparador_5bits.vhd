library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparador_5bits is
	port
	(
		-- Input ports
		V	: in  std_logic_vector(4 downto 0);
		-- Output ports
		Z 	: out std_logic_vector(1 downto 0)  
	);
end comparador_5bits;

architecture arch_comparador of comparador_5bits is
	signal num : integer range 0 to 31;
begin
	num <= to_integer(unsigned(V));
	
	process(num)
	begin
		if num < 10 then
			Z <= "00";    -- 0-9
		elsif num < 20 then
			Z <= "01";    -- 10-19
		elsif num < 30 then
			Z <= "10";    -- 20-29
		else
		   Z <= "11";    -- 30-31
		end if;
	end process;
end arch_comparador;