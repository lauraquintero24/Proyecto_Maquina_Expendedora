library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controlador_15_motores is
    Port (
        clk         : in  STD_LOGIC;
        tecla_sig   : in  STD_LOGIC_VECTOR(3 downto 0); 
        led_entrega : in  STD_LOGIC;                     
        motor3_enable : out STD_LOGIC;  motor3_in1 : out STD_LOGIC;  motor3_in2 : out STD_LOGIC;
        motor11_enable : out STD_LOGIC; motor11_in1 : out STD_LOGIC; motor11_in2 : out STD_LOGIC
    );
end controlador_15_motores;

architecture arch_controlador_15_motores of controlador_15_motores is
    

    component motor_l298n is
        Port (
            clk          : in  STD_LOGIC;
            enable       : in  STD_LOGIC;
            motor_enable : out STD_LOGIC;
            motor_in1    : out STD_LOGIC;
            motor_in2    : out STD_LOGIC
        );
    end component;
    
    -- Señales de habilitación para los 2 motores
    signal motor3_enable_sig : STD_LOGIC;
    signal motor11_enable_sig : STD_LOGIC;
    
    -- Constantes para el tiempo de activación (6 segundos)
    constant CLK_FREQ : integer := 50000000; -- 100 MHz (ajusta según tu FPGA)
    constant TIME_6S : integer := 6 * CLK_FREQ; -- 6 segundos
    
    -- Contadores para los temporizadores
    signal counter_motor3 : unsigned(31 downto 0) := (others => '0');
    signal counter_motor11 : unsigned(31 downto 0) := (others => '0');
    
    -- Estados de los motores
    signal motor3_active : STD_LOGIC := '0';
    signal motor11_active : STD_LOGIC := '0';
    
    -- Registros para detectar flanco de led_entrega
    signal led_entrega_prev : STD_LOGIC := '0';
    
    -- Señales de activación por flanco
    signal motor3_trigger : STD_LOGIC := '0';
    signal motor11_trigger : STD_LOGIC := '0';
    
begin

    -- Proceso para detectar flancos de activación
    process(clk)
    begin
        if rising_edge(clk) then
            -- Detectar flanco de subida de led_entrega
            if led_entrega_prev = '0' and led_entrega = '1' then
                -- Flanco de subida detectado, verificar qué motor activar según tecla_sig
                if tecla_sig = "0011" then
                    motor3_trigger <= '1';
                else
                    motor3_trigger <= '0';
                end if;
                
                if tecla_sig = "1011" then
                    motor11_trigger <= '1';
                else
                    motor11_trigger <= '0';
                end if;
            else
                motor3_trigger <= '0';
                motor11_trigger <= '0';
            end if;
            
            -- Guardar valor anterior para el próximo ciclo
            led_entrega_prev <= led_entrega;
        end if;
    end process;

    -- Proceso principal para controlar los motores
    process(clk)
    begin
        if rising_edge(clk) then
            
            -- Control del Motor 3
            if motor3_active = '0' then
                -- Motor apagado, verificar si debe activarse por flanco
                if motor3_trigger = '1' then
                    motor3_active <= '1';
                    counter_motor3 <= (others => '0');
                    motor3_enable_sig <= '1';
                else
                    motor3_enable_sig <= '0';
                end if;
            else
                -- Motor activado, contar tiempo
                if counter_motor3 < TIME_6S then
                    counter_motor3 <= counter_motor3 + 1;
                    motor3_enable_sig <= '1';
                else
                    -- Tiempo cumplido, apagar motor
                    motor3_active <= '0';
                    motor3_enable_sig <= '0';
                    counter_motor3 <= (others => '0');
                end if;
            end if;
            
            -- Control del Motor 11
            if motor11_active = '0' then
                -- Motor apagado, verificar si debe activarse por flanco
                if motor11_trigger = '1' then
                    motor11_active <= '1';
                    counter_motor11 <= (others => '0');
                    motor11_enable_sig <= '1';
                else
                    motor11_enable_sig <= '0';
                end if;
            else
                -- Motor activado, contar tiempo
                if counter_motor11 < TIME_6S then
                    counter_motor11 <= counter_motor11 + 1;
                    motor11_enable_sig <= '1';
                else
                    -- Tiempo cumplido, apagar motor
                    motor11_active <= '0';
                    motor11_enable_sig <= '0';
                    counter_motor11 <= (others => '0');
                end if;
            end if;
            
        end if;
    end process;

    -- Instanciación de los motores
    MOTOR_3 : motor_l298n
        port map (
            clk          => clk,
            enable       => motor3_enable_sig,
            motor_enable => motor3_enable,
            motor_in1    => motor3_in1,
            motor_in2    => motor3_in2
        );
    
    MOTOR_11 : motor_l298n
        port map (
            clk          => clk,
            enable       => motor11_enable_sig,
            motor_enable => motor11_enable,
            motor_in1    => motor11_in1,
            motor_in2    => motor11_in2
        );

end arch_controlador_15_motores;