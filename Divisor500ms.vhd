library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divisor500ms is
    port(
        clk    : in  std_logic; 
        reset  : in  std_logic;
        out500 : out std_logic -- señal que alterna cada 500 ms
    );
end Divisor500ms;

architecture arch_Divisor500ms of Divisor500ms is
    constant maxima_count : integer := 25000000 - 1;
    signal count : integer := 0;
    signal temp  : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count <= 0;
            temp  <= '0';
        elsif rising_edge(clk) then
            if count = maxima_count then
                count <= 0;
                temp  <= not temp;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    out500 <= temp;
end arch_Divisor500ms;