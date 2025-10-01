library ieee;
use ieee.std_logic_1164.all;

entity LatchSolicitud is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        prod_ok : in  std_logic;   -- confirma inventario (producto disponible)
        prod_listo : in  std_logic;   -- contador indica fin (producto entregado)

        pedido_activo : out std_logic  -- cuando es 1 = pedido en curso
    );
end LatchSolicitud;

architecture arch_LatchSolicitud of LatchSolicitud is
    signal estado : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            estado <= '0';
        elsif rising_edge(clk) then
            if (estado = '0') and (prod_ok = '1') then
                -- se confirma pedido: latch activo hasta que prod_listo = '1'
                estado <= '1';
            elsif (estado = '1') and (prod_listo = '1') then
                -- contador terminó: liberar latch
                estado <= '0';
            end if;
        end if;
    end process;

    pedido_activo <= estado;
end arch_LatchSolicitud;