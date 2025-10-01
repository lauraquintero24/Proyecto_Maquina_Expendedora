library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity restador_vueltas is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        enable       : in  std_logic;                    -- Señal 'suficiente' del comparador
        dinero_total : in  integer range 0 to 99;        -- CNT del summonedas
        precio_producto : in  integer range 0 to 99;     -- Precio del producto
        vuelta       : out integer range 0 to 99;        -- Dinero a devolver
        hay_vuelta   : out std_logic;                    -- 1 si vuelta > 0
        vuelta_lista : out std_logic                     -- 1 cuando el cálculo está listo
    );
end entity restador_vueltas;

architecture arch_restador_vueltas of restador_vueltas is
    signal calculo_realizado : std_logic;
begin
    
    -- Proceso del restador
    proceso_restador : process(clk, reset)
        variable vuelta_calc : integer range 0 to 99;
    begin
        if reset = '1' then
            vuelta <= 0;
            hay_vuelta <= '0';
            vuelta_lista <= '0';
            calculo_realizado <= '0';
        elsif rising_edge(clk) then
            -- Resetear flags cuando no hay enable
            if enable = '0' then
                vuelta <= 0;
                hay_vuelta <= '0';
                vuelta_lista <= '0';
                calculo_realizado <= '0';
            else
                -- Solo calcular cuando enable=1 y no se ha calculado aún
                if calculo_realizado = '0' then
                    -- Realizar la resta
                    vuelta_calc := dinero_total - precio_producto;
                    vuelta <= vuelta_calc;
                    
                    -- Determinar si hay vuelta
                    if vuelta_calc > 0 then
                        hay_vuelta <= '1';
                    else
                        hay_vuelta <= '0';
                    end if;
                    
                    -- Marcar cálculo como realizado
                    calculo_realizado <= '1';
                    vuelta_lista <= '1';
                end if;
            end if;
        end if;
    end process proceso_restador;

end architecture arch_restador_vueltas;