library ieee;
use ieee.std_logic_1164.all;

entity Divisordefrecuenciaa is
    port (
        clk   : in  std_logic;
        out1  : out std_logic;
        out2  : out std_logic-- Otra salida
    );
end Divisordefrecuenciaa;

architecture arch_Divisordefrecuenciaa of Divisordefrecuenciaa is
    signal count1 : integer range 0 to 24999999 := 0;
    signal count2 : integer range 0 to 49999999 := 0;
    signal r_out1, r_out2 : std_logic := '0';
begin
    process (clk)
    begin
        if rising_edge(clk) then
            -- Divisor para 1 Hz
            if count1 = 24999999 then
                r_out1 <= not r_out1;
                count1 <= 0;
            else
                count1 <= count1 + 1;
            end if;

            -- Divisor para 0.5 Hz
            if count2 = 49999999 then
                r_out2 <= not r_out2;
                count2 <= 0;
            else
                count2 <= count2 + 1;
            end if;
        end if;
    end process;

    out1 <= r_out1;
    out2 <= r_out2;
end arch_Divisordefrecuenciaa;