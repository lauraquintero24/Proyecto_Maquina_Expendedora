library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparador_precios is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        dinero_ingresado : in  integer range 0 to 99;  -- dinero del usuario 
        precio_producto  : in  integer range 0 to 99;  -- precio del producto 
        suficiente    : out std_logic                  -- 1 si dinero >= precio, 0 si no
    );
end entity comparador_precios;

architecture arch_comparador_precios of comparador_precios is
    signal suficiente_interno : std_logic;
begin
    
    -- proceso del comparador
    proceso_comparador : process(clk, reset)
    begin
        if reset = '1' then
            suficiente_interno <= '0';
        elsif rising_edge(clk) then
            -- comparar dinero ingresado con precio del producto
            if dinero_ingresado >= precio_producto then
                suficiente_interno <= '1';  --suficiente
            else
                suficiente_interno <= '0';  --insuficiente
            end if;
        end if;
    end process proceso_comparador;
    
    -- asignar salida
    suficiente <= suficiente_interno;

end architecture arch_comparador_precios;