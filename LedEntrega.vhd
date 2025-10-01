library ieee;
use ieee.std_logic_1164.all;

entity LedEntrega is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        producto_listo : in  std_logic; -- pulso de contador al terminar
        solicitar : in  std_logic; -- para apagar cuando haya nueva solicitud
        clk_500ms : in  std_logic; -- señal de parpadeo
        led_out : out std_logic -- LED de entrega (parpadea)
    );
end LedEntrega;

architecture arch_LedEntrega of LedEntrega is
    signal activo : std_logic := '0';
    signal prev_s : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            activo <= '0';
            prev_s <= '0';
        elsif rising_edge(clk) then
            prev_s <= solicitar;

            if producto_listo = '1' then
                activo <= '1'; -- empieza a parpadear
            elsif (prev_s = '0' and solicitar = '1') then
                activo <= '0'; -- se apaga en nuevo pedido
            end if;
        end if;
    end process;

    led_out <= clk_500ms when activo = '1' else '0';
end arch_LedEntrega;