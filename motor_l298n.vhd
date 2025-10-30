library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity motor_l298n is
    Port (
        clk          : in  STD_LOGIC;
        enable       : in  STD_LOGIC;   -- Control de habilitación (1 = motor activo, 0 = motor parado)
        motor_enable : out STD_LOGIC;
        motor_in1    : out STD_LOGIC;
        motor_in2    : out STD_LOGIC
    );
end motor_l298n;

architecture arch_motor_l298n of motor_l298n is
    
begin

    -- Control directo: motor al 100% cuando está habilitado
    motor_enable <= enable;
    motor_in1    <= enable;  -- Siempre en una dirección cuando está habilitado
    motor_in2    <= '0';     -- Dirección fija

end arch_motor_l298n;