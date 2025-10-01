library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SistemaMaquinaExpenderora is
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;

        solicitar_btn : in std_logic; -- botón "solicitar" (usuario)
        sensor        : in std_logic_vector(1 downto 0); -- sensores monedero
        fila          : in std_logic_vector(3 downto 0); -- teclado (filas)

        columna       : out std_logic_vector(3 downto 0);

        producto    : out std_logic;
        devolver    : out std_logic;
        alarma      : out std_logic;
        led_entrega : out std_logic;

        D0 : out std_logic_vector(6 downto 0); -- display monedas unidades
        D1 : out std_logic_vector(6 downto 0); -- display monedas decenas

        Display_Tecla : out std_logic_vector(6 downto 0);

        dispU : out std_logic_vector(6 downto 0);
        dispD : out std_logic_vector(6 downto 0);

        VD0 : out std_logic_vector(6 downto 0); -- devuelta unidades
        VD1 : out std_logic_vector(6 downto 0)  -- devuelta decenas
		  
		  
    );
end SistemaMaquinaExpenderora;

architecture arch_SistemaMaquinaExpenderora of SistemaMaquinaExpenderora is

    -- señales internas
    signal sel_teclado   : std_logic_vector(3 downto 0);
    signal dinero_int    : integer range 0 to 99 := 0;
    signal precio_bits   : unsigned(4 downto 0) := (others => '0');
    signal precio_int    : integer range 0 to 99 := 0;

    signal purchase_req  : std_logic := '0';-- requerimiento de compra
    signal suficiente    : std_logic := '0';

    -- restador / devuelta
    signal vuelta_s       : integer range 0 to 99 := 0;
    signal hay_vuelta_s   : std_logic := '0';
    signal vuelta_lista_s : std_logic := '0';

    -- señales provenientes de prueba4
    signal producto_s : std_logic := '0';
    signal devolver_s : std_logic := '0';
    signal alarma_s   : std_logic := '0';
    signal led_entrega_s : std_logic := '0';

    -- divisores)
    signal clk_2s   : std_logic;
    signal clk_500ms: std_logic;

    -- devuelta a mostrar (valores BCD)
    signal decenas_v  : std_logic_vector(3 downto 0);
    signal unidades_v : std_logic_vector(3 downto 0);

    -- reset parcial para reiniciar monedas/teclado/devuelta cuando se entregue producto
    signal reset_parcial : std_logic := '0';

    -- señal que guarda la devuelta final que se mostrará (se limpia con reset_parcial)
    signal devuelta_final : integer range 0 to 99 := 0;

    -- para detectar flanco de solicitar_btn y manejar la petición (UN solo proceso lo maneja)
    signal solicitar_prev  : std_logic := '0';
    signal request_pending : std_logic := '0';

    -- señal combinacional para habilitar restador
    signal calc_enable     : std_logic := '0';
	 
	 signal reset_sin_producto : std_logic := '0';

    -- componentes
    component Tecladomatricial
        port(
            clk       : in  std_logic;
            reset     : in  std_logic;
            Fila      : in  std_logic_vector(3 downto 0);
            Columna   : out std_logic_vector(3 downto 0);
            Tecla     : out std_logic_vector(3 downto 0);
            Display_0 : out std_logic_vector(6 downto 0)
        );
    end component;

    component summonedas
        port (
            Clk      : in  std_logic;
            Reset    : in  std_logic;
            Sensor   : in  std_logic_vector(1 downto 0);
            CNT      : out integer range 0 to 99;
            D0       : out std_logic_vector(6 downto 0);
            D1       : out std_logic_vector(6 downto 0)
        );
    end component;

    component Precios
        port(
            sel        : in  unsigned(3 downto 0);
            precio_out : out unsigned(4 downto 0)
        );
    end component;

    component comparador_precios
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            dinero_ingresado : in  integer range 0 to 99;
            precio_producto  : in  integer range 0 to 99;
            suficiente    : out std_logic
        );
    end component;

    component restador_vueltas is
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            enable       : in  std_logic;
            dinero_total : in  integer range 0 to 99;
            precio_producto : in  integer range 0 to 99;
            vuelta       : out integer range 0 to 99;
            hay_vuelta   : out std_logic;
            vuelta_lista : out std_logic
        );
    end component;

    component prueba4 is
        port (
            clk : in  std_logic;
            reset : in  std_logic;
            solicitar : in  std_logic;
            sel : in  unsigned(3 downto 0);

            producto : out std_logic;
            devolver : out std_logic;
            alarma : out std_logic;

            led_entrega : out std_logic;

            dispU : out std_logic_vector(6 downto 0);
            dispD : out std_logic_vector(6 downto 0)
        );
    end component;

    component bcd7seg is
        port(
            A : in  std_logic_vector(3 downto 0);
            B : in  std_logic_vector(3 downto 0);
            Display_0 : out std_logic_vector(6 downto 0);
            Display_1 : out std_logic_vector(6 downto 0)
        );
    end component;

    component Divisordefrecuenciaa
        port (
            clk   : in  std_logic;
            out1  : out std_logic;
            out2  : out std_logic
        );
    end component;

    component Divisor500ms is
        port(
            clk    : in  std_logic;
            reset  : in  std_logic;
            out500 : out std_logic
        );
    end component;

begin

  
    -- reset_parcial: cuando producto_s='1' (entrega), asserta por 1 ciclo
    process(clk, reset)
    begin
        if reset = '1' then
            reset_parcial <= '1';
        elsif rising_edge(clk) then
            if producto_s = '1' then
                reset_parcial <= '1';
            else
                reset_parcial <= '0';
            end if;
        end if;
    end process;


 
    -- PROCESO que:
    -- - detecta flanco de solicitar_btn (solicitud nueva)
    -- - mantiene request_pending
    -- - decide devuelta_final cuando se procesa la solicitud
    process(clk, reset)
    begin
        if reset = '1' then
            solicitar_prev  <= '0';
            request_pending <= '0';
            devuelta_final  <= 0;
        elsif rising_edge(clk) then
            -- actualizar historial del botón (para detectar flanco)
            solicitar_prev <= solicitar_btn;

            -- si hay reset_parcial -> limpiar todo lo relacionado con la solicitud/devuelta
            if reset_parcial = '1' then
                request_pending <= '0';
                devuelta_final  <= 0;

            else
                -- detectar flanco de subida del botón (nuevo pedido)
                if (solicitar_prev = '0') and (solicitar_btn = '1') then
                    request_pending <= '1';
                end if;

                -- si hay una solicitud pendiente decide la devuelta según condiciones:
                if request_pending = '1' then
                    -- caso inventario dijo "devolver" (no hay producto) -> devolver TODO
                    if (devolver_s = '1') and (producto_s = '0') then
                        devuelta_final <= dinero_int;
                        request_pending <= '0';
								reset_sin_producto <= '1'; --reinicia seleccion y monedas

                    -- caso insuficiente dinero -> devolver TODO
                    elsif (suficiente = '0') then
                        devuelta_final <= dinero_int;
                        request_pending <= '0';

                    -- caso normal: esperar a que el restador calcule (vuelta_lista_s='1')
                    elsif (vuelta_lista_s = '1') then
                        devuelta_final <= vuelta_s;
                        request_pending <= '0';
                    end if;
						  
						  if reset_sin_producto = '1' then
								reset_sin_producto <= '0';
						  end if;
						  
                end if;
            end if;
        end if;
    end process;

    -- calc_enable: sólo activo si hay solicitud pendiente, suficiente y no devolver por inventario
    calc_enable <= '1' when (request_pending = '1' and suficiente = '1' and devolver_s = '0') else '0';

    -- BCD conversion para displays de vuelta
    decenas_v  <= std_logic_vector(to_unsigned(devuelta_final / 10, 4));
    unidades_v <= std_logic_vector(to_unsigned(devuelta_final mod 10, 4));


    U_Teclado : Tecladomatricial
        port map (
            clk       => clk,
            reset     => (reset_parcial or reset_sin_producto),
            Fila      => fila,
            Columna   => columna,
            Tecla     => sel_teclado,
            Display_0 => Display_Tecla
        );

    U_Monedero : summonedas
        port map (
            Clk   => clk,
            Reset => (reset_parcial or reset_sin_producto),
            Sensor=> sensor,
            CNT   => dinero_int,
            D0    => D0,
            D1    => D1
        );

    U_Precios : Precios
        port map (
            sel => unsigned(sel_teclado),
            precio_out => precio_bits
        );

    precio_int <= to_integer(precio_bits);

    U_Comparador_precios : comparador_precios
        port map (
            clk => clk,
            reset => reset,
            dinero_ingresado => dinero_int,
            precio_producto  => precio_int,
            suficiente => suficiente
        );

    U_restador : restador_vueltas
        port map (
            clk            => clk,
            reset          => reset_parcial,
            enable         => calc_enable,
            dinero_total   => dinero_int,
            precio_producto=> precio_int,
            vuelta         => vuelta_s,
            hay_vuelta     => hay_vuelta_s,
            vuelta_lista   => vuelta_lista_s
        );

    purchase_req <= solicitar_btn;

    U_prueba4 : prueba4
        port map (
            clk => clk,
            reset => reset,
            solicitar => purchase_req,
            sel => unsigned(sel_teclado),

            producto => producto_s,
            devolver => devolver_s,
            alarma   => alarma_s,

            led_entrega => led_entrega_s,

            dispU => dispU,
            dispD => dispD
        );

    -- Salidas
    producto    <= producto_s;
    devolver    <= devolver_s;
    alarma      <= alarma_s;
    led_entrega <= led_entrega_s;

    U_divisor_alarma : Divisordefrecuenciaa
        port map (
            clk => clk,
            out1 => open,
            out2 => clk_2s
        );

    U_div500 : Divisor500ms
        port map (
            clk => clk,
            reset => reset,
            out500 => clk_500ms
        );

    U_BCD7SEG_Vueltas : bcd7seg
        port map (
            A => unidades_v,
            B => decenas_v,
            Display_0 => VD0,
            Display_1 => VD1
        );

end arch_SistemaMaquinaExpenderora;