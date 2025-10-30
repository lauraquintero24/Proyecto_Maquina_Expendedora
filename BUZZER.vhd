library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity BUZZER is
    port(
        CLK   : in  STD_LOGIC;   -- Reloj
        RESET : in  STD_LOGIC;   -- Señal de reinicio
        BEEP  : buffer STD_LOGIC -- Salida al buzzer
    );
end BUZZER;

architecture SenalBuzzer of BUZZER is
    --------------------------------------------------------------------
    -- Para generar una nota musical, el tono depende del tiempo
    -- que tarda la señal en cambiar de estado (toggle).
    -- 
    -- Nota: La4 = 440 Hz
    -- CLK = 50 MHz → semiperiodo = 50e6 / (2 * 440) ≈ 56,818
    --------------------------------------------------------------------
    signal CONTADOR_NOTA : INTEGER range 0 to 37_940 := 0;
begin

    CrearSonido: process (CLK, RESET)
    begin
        if RESET = '1' then
            CONTADOR_NOTA <= 0;
            BEEP <= '0';

        elsif rising_edge(CLK) then
            if CONTADOR_NOTA = 37_940 then  -- Semiperiodo de la nota LA4
                CONTADOR_NOTA <= 0;
                BEEP <= not BEEP;           -- Invierte la señal → onda cuadrada
            else
                CONTADOR_NOTA <= CONTADOR_NOTA + 1;
            end if;
        end if;
    end process;

end SenalBuzzer;
