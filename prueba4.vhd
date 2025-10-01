library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prueba4 is
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
end prueba4;

architecture arch_prueba4 of prueba4 is
    -- salidas internas del inventario
    signal producto_entrada : std_logic := '0'; -- indicador del inventario: hay producto
    signal devolver_entrada : std_logic := '0';
    signal alarma_entrada : std_logic := '0';

    -- señales de control entre latch y contador
    signal pedido_activo : std_logic := '0'; -- latch: mantiene pedido en curso
    signal producto_listo : std_logic := '0'; -- contador: terminó la cuenta

	 -- señal para alarma
	 signal clk_2s : std_logic :='0';
	 
	 -- señal para parpadeo cada 500ms
	 signal clk_500ms : std_logic;
	 
    -- componentes
    component Inventarioo is
		 port(
			  clk : in  std_logic;
			  reset : in  std_logic;
			  solicitar : in  std_logic;                
			  sel : in  unsigned(3 downto 0);

			  producto : out std_logic;
			  devolver : out std_logic;
			  alarma : out std_logic 
		 );
    end component;
	 

    component contador3 is
        port (
            Clock : in  std_logic;
            Reset : in  std_logic;
            Start : in  std_logic;
            Sal_D1 : out std_logic_vector(6 downto 0);
            Sal_D2 : out std_logic_vector(6 downto 0);
            Producto_entregado : out std_logic
        );
    end component;
	 

    component LatchSolicitud is
        port (
            clk : in  std_logic;
            reset : in  std_logic;
            prod_ok: in  std_logic;
            prod_listo : in  std_logic;
            pedido_activo: out std_logic
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
	 
	 
	 component LedEntrega is
		 port (
			  clk : in  std_logic;
			  reset : in  std_logic;
			  producto_listo : in  std_logic;
			  solicitar : in  std_logic;
			  clk_500ms : in  std_logic;
			  led_out : out std_logic
		 );
	 end component;

begin
    -- Inventario: entrega producto_entrada =1 cuando el pedido es valido
    U_inv: Inventarioo
        port map (
            clk => clk,
            reset => reset,
            solicitar => solicitar,
            sel => sel,
            producto => producto_entrada,   -- aquí representa "producto disponible/confirmado"
            devolver => devolver_entrada,
            alarma => alarma_entrada
        );

    -- LatchPedido (captura producto_entrada y mantiene pedido_activo hasta prod_listo)
    U_latch: LatchSolicitud
        port map (
            clk => clk,
            reset => reset,
            prod_ok => producto_entrada,
            prod_listo => producto_listo,
            pedido_activo=> pedido_activo
        );

    -- Contador 30s: START usa pedido_activo
    U_cnt: contador3
        port map (
            Clock => clk,
            Reset => reset,
            Start => pedido_activo,  -- <- nivel estable
            Sal_D1 => dispU,
            Sal_D2 => dispD,
            Producto_entregado => producto_listo
        );
		  
	 U_divisor_alarma: Divisordefrecuenciaa
		 port map (
			   clk => clk,
				out1 => open,
				out2 => clk_2s
		  );
		  
	 U_div500: Divisor500ms
		 port map (
			  clk => clk,
			  reset => reset,
			  out500 => clk_500ms
		 );

	 U_ledEntrega: LedEntrega
		 port map (
			  clk => clk,
			  reset => reset,
			  producto_listo => producto_listo,
			  solicitar => solicitar,
			  clk_500ms => clk_500ms,
			  led_out => led_entrega
		 );
		
    -- salida final: LED de entrega se enciende cuando el contador terminó
    producto <= producto_listo;
    devolver <= devolver_entrada;
	 
	 -- alarma: si inventario detecta total=0, entonces parpadea cada 2s
    alarma <= clk_2s when (alarma_entrada = '1') else '0';
end arch_prueba4;