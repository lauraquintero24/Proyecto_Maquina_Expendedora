-- DispensadorCambio.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- monto: 0..99 con 10 = $1000 y 5 = $500
entity DispensadorCambio is
  generic(
    CLK_HZ  : integer := 50_000_000;
    ESP_MS  : integer := 700         -- espera entre giros para soltar moneda
  );
  port(
    reloj        : in  std_logic;
    reinicio     : in  std_logic;
    iniciar      : in  std_logic;                 -- pulso 1 ciclo para iniciar
    monto        : in  integer range 0 to 99;     -- devuelta a entregar

    pwm_500      : out std_logic;                 -- PWM servo 500
    pwm_1000     : out std_logic;                 -- PWM servo 1000

    ocupado      : out std_logic;                 -- 1 mientras entrega
    listo        : out std_logic                  -- pulso 1 ciclo al terminar
  );
end entity;

architecture rtl of DispensadorCambio is
  component ServoPWM is
    generic(
      CLK_HZ     : integer := 50_000_000;
      PERIOD_MS  : integer := 20;
      MIN_US     : integer := 1000;
      MAX_US     : integer := 2000;
      STEP_US_L  : integer := 20;
      STEP_US_R  : integer := 50
    );
    port(
      reloj     : in  std_logic;
      reinicio  : in  std_logic;
      ir_cero   : in  std_logic;
      ir_pos    : in  std_logic;
      rapido    : in  std_logic;
      pwm_servo : out std_logic;
      ocupado   : out std_logic;
      en_cero   : out std_logic;
      en_pos    : out std_logic
    );
  end component;

  -- órdenes a servos
  signal ir0_500, ir1_500, ir0_1000, ir1_1000 : std_logic := '0';
  signal dummy_busy1, dummy_busy2 : std_logic;
  signal dummy_c1, dummy_p1, dummy_c2, dummy_p2 : std_logic;

  -- “posición lógica” de cada servo
  signal en_home_500  : std_logic := '1';  -- asumimos arranque en 0°
  signal en_home_1000 : std_logic := '1';

  -- monedas por entregar
  signal n1000, n500  : integer range 0 to 9 := 0;

  -- temporización de espera entre giros
  constant ESP_TICKS  : integer := (CLK_HZ/1000) * ESP_MS;
  signal   espera_cnt : integer range 0 to ESP_TICKS := 0;

  type st_t is (IDLE, CARGA, PULSO_1000, ESPERA_1000, DEC_1000,
                         PULSO_500,  ESPERA_500,  DEC_500, FIN);
  signal st : st_t := IDLE;
begin
  -- servos en modo rápido
  U_S500: ServoPWM
    port map(
      reloj=>reloj, reinicio=>reinicio,
      ir_cero=>ir0_500, ir_pos=>ir1_500, rapido=>'1',
      pwm_servo=>pwm_500, ocupado=>dummy_busy1,
      en_cero=>dummy_c1,  en_pos=>dummy_p1
    );

  U_S1000: ServoPWM
    port map(
      reloj=>reloj, reinicio=>reinicio,
      ir_cero=>ir0_1000, ir_pos=>ir1_1000, rapido=>'1',
      pwm_servo=>pwm_1000, ocupado=>dummy_busy2,
      en_cero=>dummy_c2,   en_pos=>dummy_p2
    );

  ocupado <= '1' when st/=IDLE else '0';
  listo   <= '1' when st=FIN    else '0';

  process(reloj, reinicio)
    variable tmp   : integer;
    variable v1000 : integer;
    variable v500  : integer;
  begin
    if reinicio='1' then
      st <= IDLE;
      n1000 <= 0; n500 <= 0;
      espera_cnt <= 0;
      ir0_500<='0'; ir1_500<='0'; ir0_1000<='0'; ir1_1000<='0';
      en_home_500  <= '1';
      en_home_1000 <= '1';

    elsif rising_edge(reloj) then
      -- por defecto, sin pulsos a servos
      ir0_500<='0'; ir1_500<='0'; ir0_1000<='0'; ir1_1000<='0';

      case st is
        when IDLE =>
          if iniciar='1' and monto>0 then
            st <= CARGA;
          end if;

        when CARGA =>
          -- greedy: 10->1000, 5->500
          tmp   := monto;
          v1000 := tmp / 10;
          tmp   := tmp mod 10;
          if tmp >= 5 then
            v500 := 1;
          else
            v500 := 0;
          end if;

          n1000 <= v1000;
          n500  <= v500;

          espera_cnt <= 0;
          if v1000 > 0 then
            st <= PULSO_1000;
          elsif v500 > 0 then
            st <= PULSO_500;
          else
            st <= FIN;
          end if;

        -- ===== Monedas de 1000 =====
        when PULSO_1000 =>
          if en_home_1000='1' then
            ir1_1000 <= '1'; en_home_1000 <= '0';  -- 0 -> 180
          else
            ir0_1000 <= '1'; en_home_1000 <= '1';  -- 180 -> 0
          end if;
          espera_cnt <= 0;
          st <= ESPERA_1000;

        when ESPERA_1000 =>
          if espera_cnt >= ESP_TICKS then
            st <= DEC_1000;
          else
            espera_cnt <= espera_cnt + 1;
          end if;

        when DEC_1000 =>
          if n1000 > 1 then
            n1000 <= n1000 - 1;
            st <= PULSO_1000;
          elsif n1000 = 1 then
            n1000 <= 0;
            if n500 > 0 then st <= PULSO_500; else st <= FIN; end if;
          else
            if n500 > 0 then st <= PULSO_500; else st <= FIN; end if;
          end if;

        -- ===== Monedas de 500 =====
        when PULSO_500 =>
          if en_home_500='1' then
            ir1_500 <= '1'; en_home_500 <= '0';   -- 0 -> 180
          else
            ir0_500 <= '1'; en_home_500 <= '1';   -- 180 -> 0
          end if;
          espera_cnt <= 0;
          st <= ESPERA_500;

        when ESPERA_500 =>
          if espera_cnt >= ESP_TICKS then
            st <= DEC_500;
          else
            espera_cnt <= espera_cnt + 1;
          end if;

        when DEC_500 =>
          if n500 > 1 then
            n500 <= n500 - 1;
            st <= PULSO_500;
          elsif n500 = 1 then
            n500 <= 0;
            st <= FIN;
          else
            st <= FIN;
          end if;

        when FIN =>
          st <= IDLE;  -- hace que 'listo' dure 1 ciclo
      end case;
    end if;
  end process;
end architecture;