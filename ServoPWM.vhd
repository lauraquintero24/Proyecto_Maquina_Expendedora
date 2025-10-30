-- ServoPWM.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ServoPWM is
  generic(
    CLK_HZ     : integer := 50_000_000;
    PERIOD_MS  : integer := 20;     -- 50 Hz
    MIN_US     : integer := 1000;   -- 1.0 ms = 0°
    MAX_US     : integer := 2000;   -- 2.0 ms = 180°
    STEP_US_L  : integer := 20;     -- paso lento
    STEP_US_R  : integer := 50      -- paso rápido
  );
  port(
    reloj      : in  std_logic;
    reinicio   : in  std_logic;
    ir_cero    : in  std_logic;     -- ir a 0°
    ir_pos     : in  std_logic;     -- ir a 180°
    rapido     : in  std_logic;     -- 1 = rápido
    pwm_servo  : out std_logic;
    ocupado    : out std_logic;     -- 1 mientras mueve
    en_cero    : out std_logic;     -- 1 cuando está en 0°
    en_pos     : out std_logic      -- 1 cuando está en 180°
  );
end entity;

architecture rtl of ServoPWM is
  -- constantes de tiempo en ciclos
  constant PERIOD_CYC : integer := (CLK_HZ/1000) * PERIOD_MS;
  constant MIN_CYC    : integer := (CLK_HZ/1_000_000) * MIN_US;
  constant MAX_CYC    : integer := (CLK_HZ/1_000_000) * MAX_US;
  constant STEP_L     : integer := (CLK_HZ/1_000_000) * STEP_US_L;
  constant STEP_R     : integer := (CLK_HZ/1_000_000) * STEP_US_R;

  -- funciones auxiliares para VHDL-93
  function MIN_INT(a,b: integer) return integer is
  begin
    if a < b then return a; else return b; end if;
  end function;
  function MAX_INT(a,b: integer) return integer is
  begin
    if a > b then return a; else return b; end if;
  end function;

  -- sincronización de entradas y detección de flanco
  signal ir_cero_s0,  ir_cero_s1  : std_logic := '0';
  signal ir_pos_s0,   ir_pos_s1   : std_logic := '0';
  signal rapido_s0,   rapido_s1   : std_logic := '0';

  type st_t is (ESPERA, MOVIENDO);
  signal st : st_t := ESPERA;

  signal cnt_periodo : integer := 0;
  signal ancho_pulso : integer := MIN_CYC;
  signal objetivo    : integer := MIN_CYC;
  signal paso_usos   : integer := STEP_L;
begin
  -- PWM 50 Hz
  pwm_servo <= '1' when cnt_periodo < ancho_pulso else '0';

  process(reloj, reinicio)
  begin
    if reinicio='1' then
      st          <= ESPERA;
      cnt_periodo <= 0;
      ancho_pulso <= MIN_CYC;
      objetivo    <= MIN_CYC;
      ir_cero_s0  <= '0'; ir_cero_s1 <= '0';
      ir_pos_s0   <= '0'; ir_pos_s1  <= '0';
      rapido_s0   <= '0'; rapido_s1  <= '0';
      paso_usos   <= STEP_L;
    elsif rising_edge(reloj) then
      -- sync entradas
      ir_cero_s0 <= ir_cero;  ir_cero_s1 <= ir_cero_s0;
      ir_pos_s0  <= ir_pos;   ir_pos_s1  <= ir_pos_s0;
      rapido_s0  <= rapido;   rapido_s1  <= rapido_s0;

      -- velocidad
      if rapido_s1='1' then paso_usos <= STEP_R; else paso_usos <= STEP_L; end if;

      -- flancos (rising)
      if (ir_cero_s1='1' and ir_cero_s0='0') then
        objetivo <= MIN_CYC; st <= MOVIENDO;
      elsif (ir_pos_s1='1' and ir_pos_s0='0') then
        objetivo <= MAX_CYC; st <= MOVIENDO;
      end if;

      -- base 20 ms
      if cnt_periodo = PERIOD_CYC-1 then
        cnt_periodo <= 0;

        if st = MOVIENDO then
          if ancho_pulso < objetivo then
            ancho_pulso <= MIN_INT(ancho_pulso + paso_usos, objetivo);
          elsif ancho_pulso > objetivo then
            ancho_pulso <= MAX_INT(ancho_pulso - paso_usos, objetivo);
          else
            st <= ESPERA;
          end if;
        end if;

      else
        cnt_periodo <= cnt_periodo + 1;
      end if;
    end if;
  end process;

  ocupado <= '1' when st=MOVIENDO else '0';
  en_cero <= '1' when ancho_pulso=MIN_CYC else '0';
  en_pos  <= '1' when ancho_pulso=MAX_CYC else '0';
end architecture;