library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cir_A_5bits is
	port
	(
		-- Input ports
		V	: in  std_logic_vector(4 downto 0);
		-- Output ports
		D0 	: out std_logic_vector(3 downto 0) 
	);
end cir_A_5bits;

architecture arch_cir_A of cir_A_5bits is
	signal num : integer range 0 to 31;
begin
	num <= to_integer(unsigned(V));
	
	process(num)
	begin
		if num < 10 then
			D0 <= std_logic_vector(to_unsigned(num, 4));
		elsif num < 20 then
			D0 <= std_logic_vector(to_unsigned(num - 10, 4));
		elsif num < 30 then
            D0 <= std_logic_vector(to_unsigned(num - 20, 4));
		else
			 D0 <= std_logic_vector(to_unsigned(num - 30, 4));
		end if;
	end process;
end arch_cir_A;