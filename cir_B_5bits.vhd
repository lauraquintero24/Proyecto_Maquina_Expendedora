library ieee;
use ieee.std_logic_1164.all;

entity cir_B_5bits is
    port (
        Z  : in  std_logic_vector(1 downto 0);
        D1 : out std_logic_vector(3 downto 0)
    );
end cir_B_5bits;

architecture behavioral of cir_B_5bits is
begin
    with Z select
        D1 <= "0000" when "00",  -- 0 decenas (0-9)
              "0001" when "01",  -- 1 decena (10-19)
              "0010" when "10",  -- 2 decenas (20-29)
              "0011" when "11",  -- 3 decenas (30-31) 
              "0000" when others;
end behavioral;