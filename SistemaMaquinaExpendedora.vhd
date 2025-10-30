library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SistemaMaquinaExpendedora is
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

        dispU : out std_logic_vector(6 downto 0); -- unidades de cambio
        dispD : out std_logic_vector(6 downto 0); -- decenas de cambio

        VD0 : out std_logic_vector(6 downto 0); -- devuelta unidades
        VD1 : out std_logic_vector(6 downto 0);  -- devuelta decenas
		  
        pwm_500p         : out std_logic;  -- PWM para el servo de 500
        pwm_1000p        : out std_logic   -- PWM para el servo de 1000
    );
end SistemaMaquinaExpendedora;

architecture arch_SistemaMaquinaExpendedora of SistemaMaquinaExpendedora is
    -- Declaración de señales de PWM para controlar los servos
    signal pwm_500 : std_logic;
    signal pwm_1000 : std_logic;

    -- señales internas
    signal sel_teclado   : std_logic_vector(3 downto 0);
    signal dinero_int    : integer range 0 to 99 := 0;  -- Total dinero ingresado
    signal precio_bits   : unsigned(4 downto 0) := (others => '0');
    signal precio_int    : integer range 0 to 99 := 0;

    signal purchase_req  : std_logic := '0'; -- Requerimiento de compra
    signal suficiente    : std_logic := '0';

    -- Restador / devuelta
    signal vuelta_s       : integer range 0 to 99 := 0;
    signal hay_vuelta_s   : std_logic := '0';
    signal vuelta_lista_s : std_logic := '0';

    -- Señales provenientes de prueba4
    signal producto_s : std_logic := '0';
    signal devolver_s : std_logic := '0';
    signal alarma_s   : std_logic := '0';
 
    -- Señales internas necesarias para los servos
    signal led_ocupado : std_logic;
    signal led_listo   : std_logic;
    signal led_entrega_s : std_logic := '0';

    -- Divisores de frecuencia
    signal clk_2s   : std_logic;
    signal clk_500ms: std_logic;

    -- Devuelta a mostrar (valores BCD)
    signal decenas_v  : std_logic_vector(3 downto 0);
    signal unidades_v : std_logic_vector(3 downto 0);

    -- Reset parcial para reiniciar monedas/teclado/devuelta cuando se entregue producto
    signal reset_parcial : std_logic := '0';

    -- Señal que guarda la devuelta final que se mostrará (se limpia con reset_parcial)
    signal devuelta_final : integer range 0 to 99 := 0;

    -- Para detectar flanco de solicitar_btn y manejar la petición (UN solo proceso lo maneja)
    signal solicitar_prev  : std_logic := '0';
    signal request_pending : std_logic := '0';

    -- Señal combinacional para habilitar restador
    signal calc_enable     : std_logic := '0';
    
    signal reset_sin_producto : std_logic := '0';

    -- Componentes
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

    -- Aquí agregamos los servos para dispensar cambio
    component DispensadorCambio is
        generic(
            CLK_HZ  : integer := 50_000_000;
            ESP_MS  : integer := 700
        );
        port(
            reloj        : in  std_logic;
            reinicio     : in  std_logic;
            iniciar      : in  std_logic;        -- Pulso 1 ciclo para iniciar
            monto        : in  integer range 0 to 99;  -- Monto a devolver

            pwm_500      : out std_logic;        -- PWM servo 500
            pwm_1000     : out std_logic;        -- PWM servo 1000

            ocupado      : out std_logic;        -- 1 mientras entrega
            listo        : out std_logic         -- Pulso 1 ciclo al terminar
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

    -- Integración de los demás módulos: Teclado, monedas, precios, comparador, restador
    -- Reemplazando partes según necesidad (sólo mostramos los instanciados en este ejemplo)
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

    -- Componente para dispensar el cambio usando los servos
    U_CAMBIO: DispensadorCambio
        port map(
            reloj => clk,
            reinicio => reset,
            iniciar => purchase_req,  -- Al pulsar el botón de compra
            monto => devuelta_final,  -- Devolución calculada
            pwm_500 => pwm_500,      -- Señal PWM para el servo de 500
            pwm_1000 => pwm_1000,    -- Señal PWM para el servo de 1000
            ocupado => led_ocupado,  -- Señal ocupada durante la entrega
            listo => led_listo       -- Señal lista después de entrega
        );

	 pwm_1000p <= pwm_1000;
	 pwm_500p <= pwm_500;
	 
    -- Salidas para el proceso final
    producto    <= producto_s;
    devolver    <= devolver_s;
    alarma      <= alarma_s;
    led_entrega <= led_entrega_s;

    -- Otros componentes, divisor de frecuencia y otros módulos según se necesite
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

end arch_SistemaMaquinaExpendedora;