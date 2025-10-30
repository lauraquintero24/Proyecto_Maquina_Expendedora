library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- sensores(0)=500, sensores(1)=1000. salida conteo en unidades de 500.
entity contador_monedas_optico is
  generic(
    FREC_HZ     : integer := 50_000_000;
    ACTIVO_BAJO : boolean := true;   -- FC-51 normalmente activo-bajo
    CONFIRM_US  : integer := 300;    -- tiempo mínimo tapado para validar
    LIBRE_US    : integer := 1       -- tiempo mínimo libre para rearmar
  );
  port(
    reloj    : in  std_logic;
    reinicio : in  std_logic;
    sensores : in  std_logic_vector(1 downto 0);
    conteo   : out integer range 0 to 99       -- 500=>+1, 1000=>+2
  );
end contador_monedas_optico;

architecture arch_contador_monedas_optico of contador_monedas_optico is
  constant TICK_POR_US : integer := FREC_HZ/1_000_000;
  constant CONFIRM_TC  : integer := CONFIRM_US*TICK_POR_US;
  constant LIBRE_TC    : integer := LIBRE_US*TICK_POR_US;

  -- sincronización
  signal s1,s2 : std_logic_vector(1 downto 0) := (others=>'1');
  signal activo: std_logic_vector(1 downto 0);

  type st_t is (ESPERA_LIBRE, CONFIRMAR_TAPADO, WAIT_CLEAR);
  signal st500, st1000 : st_t := ESPERA_LIBRE;
  signal ct500, ct1000 : integer range 0 to integer'high := 0;
  signal p500, p1000   : std_logic := '0';

  signal conteo_i : integer range 0 to 99 := 0;

  function sat_add(a,b,maxv:integer) return integer is
    variable r: integer := a+b;
  begin
    if r>maxv then return maxv; else return r; end if;
  end;
begin
  conteo <= conteo_i;

  -- doble FF por canal
  process(reloj) begin
    if rising_edge(reloj) then
      s1 <= sensores;
      s2 <= s1;
    end if;
  end process;

  -- normaliza activo='1' cuando hay moneda
  gen_act: for i in 0 to 1 generate
    activo(i) <= (not s2(i)) when ACTIVO_BAJO else s2(i);
  end generate;

  -- FSM 500
  process(reloj, reinicio) begin
    if reinicio='1' then
      st500 <= WAIT_CLEAR;  -- esperar haz libre tras reset
      ct500 <= 0;
      p500  <= '0';
    elsif rising_edge(reloj) then
      p500<='0';
      case st500 is
        when ESPERA_LIBRE =>
          ct500<=0;
          if activo(0)='1' then st500<=CONFIRMAR_TAPADO; ct500<=1; end if;

        when CONFIRMAR_TAPADO =>
          if activo(0)='1' then
            if ct500>=CONFIRM_TC then p500<='1'; st500<=WAIT_CLEAR; ct500<=0;
            else ct500<=ct500+1; end if;
          else
            st500<=ESPERA_LIBRE; ct500<=0;
          end if;

        when WAIT_CLEAR =>
          if activo(0)='0' then
            if ct500>=LIBRE_TC then st500<=ESPERA_LIBRE; ct500<=0;
            else ct500<=ct500+1; end if;
          else
            ct500<=0;
          end if;
      end case;
    end if;
  end process;

  -- FSM 1000
  process(reloj, reinicio) begin
    if reinicio='1' then
      st1000 <= WAIT_CLEAR;
      ct1000 <= 0;
      p1000  <= '0';
    elsif rising_edge(reloj) then
      p1000<='0';
      case st1000 is
        when ESPERA_LIBRE =>
          ct1000<=0;
          if activo(1)='1' then st1000<=CONFIRMAR_TAPADO; ct1000<=1; end if;

        when CONFIRMAR_TAPADO =>
          if activo(1)='1' then
            if ct1000>=CONFIRM_TC then p1000<='1'; st1000<=WAIT_CLEAR; ct1000<=0;
            else ct1000<=ct1000+1; end if;
          else
            st1000<=ESPERA_LIBRE; ct1000<=0;
          end if;

        when WAIT_CLEAR =>
          if activo(1)='0' then
            if ct1000>=LIBRE_TC then st1000<=ESPERA_LIBRE; ct1000<=0;
            else ct1000<=ct1000+1; end if;
          else
            ct1000<=0;
          end if;
      end case;
    end if;
  end process;

  -- Acumulador en unidades de 500
  process(reloj, reinicio)
    variable inc : integer range 0 to 2;
  begin
    if reinicio='1' then
      conteo_i <= 0;
    elsif rising_edge(reloj) then
      inc := 0;
      if p500='1'  then inc := inc + 1; end if;  -- 500 => +1
      if p1000='1' then inc := inc + 2; end if;  -- 1000 => +2
      conteo_i <= sat_add(conteo_i, inc, 99);
    end if;
  end process;
end arch_contador_monedas_optico;