library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_DispensadorCambio is
  port(
    reloj         : in  std_logic;                      -- CLOCK_50
    reinicio      : in  std_logic;                      -- SW
    btn_iniciar   : in  std_logic;                      -- botón activo-alto

    sw_decenas    : in  std_logic_vector(3 downto 0);   -- 0..9
    sw_unidades   : in  std_logic_vector(3 downto 0);   -- 0..9

    -- PWM a servos
    pwm_500       : out std_logic;
    pwm_1000      : out std_logic;

    -- Indicadores
    led_ocupado   : out std_logic;
    led_listo     : out std_logic;

    -- Displays del monto
    dispU_monto   : out std_logic_vector(6 downto 0);   -- unidades
    dispD_monto   : out std_logic_vector(6 downto 0)    -- decenas
  );
end;

architecture rtl of Test_DispensadorCambio is
  component DispensadorCambio is
    generic(
      CLK_HZ  : integer := 50_000_000;
      ESP_MS  : integer := 700
    );
    port(
      reloj        : in  std_logic;
      reinicio     : in  std_logic;
      iniciar      : in  std_logic;
      monto        : in  integer range 0 to 99;
      pwm_500      : out std_logic;
      pwm_1000     : out std_logic;
      ocupado      : out std_logic;
      listo        : out std_logic
    );
  end component;

  component bcd7seg is
    port(
      A : in  std_logic_vector(3 downto 0);  -- unidades
      B : in  std_logic_vector(3 downto 0);  -- decenas
      Display_0 : out std_logic_vector(6 downto 0);
      Display_1 : out std_logic_vector(6 downto 0)
    );
  end component;

  -- monto como entero 0..99
  signal monto_i : integer range 0 to 99 := 0;

  -- sincronización y flanco para iniciar
  signal b_d, b_q : std_logic := '0';
  signal start_pulso : std_logic := '0';

  -- señales de estado
  signal s_busy, s_done : std_logic;
begin
  -- cálculo del monto desde los switches BCD
  monto_i <= to_integer(unsigned(sw_decenas)) * 10
             + to_integer(unsigned(sw_unidades));

  -- sync botón y pulso 1 ciclo
  process(reloj) begin
    if rising_edge(reloj) then
      b_d <= btn_iniciar; b_q <= b_d;
    end if;
  end process;
  start_pulso <= '1' when (b_q='1' and b_d='0') else '0';

  -- displays para ver el monto pedido
  UDISP: bcd7seg
    port map(
      A => sw_unidades,
      B => sw_decenas,
      Display_0 => dispU_monto,
      Display_1 => dispD_monto
    );

  -- dispensador de cambio
  U_CAMBIO: DispensadorCambio
    port map(
      reloj=>reloj,
      reinicio=>reinicio,        -- puedes usar reinicio parcial si quieres abortar
      iniciar=>start_pulso,
      monto=>monto_i,
      pwm_500=>pwm_500,
      pwm_1000=>pwm_1000,
      ocupado=>s_busy,
      listo=>s_done
    );

  led_ocupado <= s_busy;
  led_listo   <= s_done;
end;