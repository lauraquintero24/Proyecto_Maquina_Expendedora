--para la puerta de la maquina 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_servo is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        led_entrega : in  STD_LOGIC;
        servo_pwm   : out STD_LOGIC  -- se conecta al servo de la puerta
    );
end pwm_servo;

architecture arch_pwm_servo of pwm_servo is
    
    constant CLK_FREQ    : integer := 50000000;  
    constant PERIOD_20MS : integer := 1000000;   
    constant PULSE_0DEG  : integer := 50000;     
    constant PULSE_180DEG : integer := 100000;   
    
    signal counter : integer range 0 to PERIOD_20MS := 0;
    signal pulse_width : integer range PULSE_0DEG to PULSE_180DEG := PULSE_0DEG;
    
begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            servo_pwm <= '0';
        elsif rising_edge(clk) then
            if counter < PERIOD_20MS - 1 then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;
            
            if counter < pulse_width then
                servo_pwm <= '1';
            else
                servo_pwm <= '0';
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            pulse_width <= PULSE_0DEG;
        elsif rising_edge(clk) then
            if led_entrega = '1' then
                pulse_width <= PULSE_180DEG; 
            else
                pulse_width <= PULSE_0DEG; 
            end if;
        end if;
    end process;

end arch_pwm_servo;