library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador3 is
    port (
        Clock   : in  std_logic;  -- reloj rápido (50 MHz)
        Reset   : in  std_logic;  -- reset activo '1'
        Start   : in  std_logic;  -- nivel: pedido_activo desde el latch
		  
        Sal_D1  : out std_logic_vector(6 downto 0); -- unidades (7seg)
        Sal_D2  : out std_logic_vector(6 downto 0); -- decenas (7seg)
        Producto_entregado : out std_logic
    );
end contador3;

architecture arch_contador3 of contador3 is
    signal cuenta   : integer range 0 to 30 := 30;
    signal en_curso : std_logic := '0';
    signal clk_1Hz  : std_logic;

    signal unidades, decenas : std_logic_vector(3 downto 0);

    -- Señal para mantener visible la entrega 1 segundo
    signal PulsoProducto : std_logic := '0';
    signal TiempoPulsoProducto : integer range 0 to 2 := 0;

    -- Componentes
    component Divisordefrecuenciaa
        port (
            clk   : in  std_logic;
            out1  : out std_logic;
            out2  : out std_logic
        );
    end component;

    component bcd7seg
        port (
            A : in std_logic_vector(3 downto 0);
            B : in std_logic_vector(3 downto 0);
            Display_0 : out std_logic_vector(6 downto 0);
            Display_1 : out std_logic_vector(6 downto 0)
        );
    end component;

begin
    -- divisor
    U_div: Divisordefrecuenciaa
        port map (
            clk  => Clock,
            out1 => clk_1Hz,
            out2 => open
        );

    -- proceso controlado por clk_1Hz
    process(clk_1Hz, Reset)
    begin
        if Reset = '1' then
            cuenta <= 30;
            en_curso <= '0';
            PulsoProducto <= '0';
            TiempoPulsoProducto <= 0;
            Producto_entregado <= '0';

        elsif rising_edge(clk_1Hz) then
            -- Si Start aparece y no estamos en curso, arrancamos (solo una vez)
            if (Start = '1') and (en_curso = '0') then
                cuenta <= 30;
                en_curso <= '1';
                PulsoProducto <= '0';
                TiempoPulsoProducto <= 0;
                Producto_entregado <= '0';

            elsif en_curso = '1' then
                -- contamos hacia abajo 30 -> 0
                if cuenta > 0 then
                    cuenta <= cuenta - 1;
                else
                    -- llegó a 0: entregar (pulso visible 1 s)
                    PulsoProducto <= '1';
                    TiempoPulsoProducto <= 1; -- mantener 1 tick de 1Hz
                    Producto_entregado <= '1';
                    en_curso <= '0'; -- finaliza la cuenta
                end if;

            elsif TiempoPulsoProducto > 0 then
                -- gestionar la duración visible del pulso
                TiempoPulsoProducto <= TiempoPulsoProducto - 1;
                if TiempoPulsoProducto = 1 then
                    PulsoProducto <= '0';
                    Producto_entregado <= '0';
                end if;
            end if;
        end if;
    end process;

    -- convertir a BCD y mostrar en 7 segmentos
    decenas  <= std_logic_vector(to_unsigned(cuenta / 10, 4));
    unidades <= std_logic_vector(to_unsigned(cuenta mod 10, 4));

    U_disp: bcd7seg
        port map (
            A => unidades,
            B => decenas,
            Display_0 => Sal_D1,
            Display_1 => Sal_D2
        );

end arch_contador3;