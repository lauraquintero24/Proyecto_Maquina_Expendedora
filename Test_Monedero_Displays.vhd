library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_Monedero_Displays is
  port(
    reloj    : in  std_logic;
    reinicio : in  std_logic;
    sensores : in  std_logic_vector(1 downto 0);  -- (0)=500, (1)=1000

    -- 500: unidades y decenas
    D500_U  : out std_logic_vector(6 downto 0);
    D500_D  : out std_logic_vector(6 downto 0);

    -- 1000: unidades y decenas
    D1000_U : out std_logic_vector(6 downto 0);
    D1000_D : out std_logic_vector(6 downto 0)
  );
end;

architecture arch_Test_Monedero_Displays of Test_Monedero_Displays is
  component contador_monedas_optico is
    generic(
      FREC_HZ     : integer := 50_000_000;
      ACTIVO_BAJO : boolean := true;
      CONFIRM_US  : integer := 300;
      LIBRE_US    : integer := 1
    );
    port(
      reloj    : in  std_logic;
      reinicio : in  std_logic;
      sensores : in  std_logic_vector(1 downto 0);
      conteo   : out integer range 0 to 99
    );
  end component;

  component bcd7seg is
    port(
      A : in  std_logic_vector(3 downto 0); -- unidades
      B : in  std_logic_vector(3 downto 0); -- decenas
      Display_0 : out std_logic_vector(6 downto 0);
      Display_1 : out std_logic_vector(6 downto 0)
    );
  end component;

  signal cnt500     : integer range 0 to 99 := 0;  -- #500
  signal cnt1000_2  : integer range 0 to 99 := 0;  -- suma de a 2
  signal mon1000    : integer range 0 to 99 := 0;  -- #monedas de 1000

  signal n500_u,  n500_d  : std_logic_vector(3 downto 0);
  signal n1000_u, n1000_d : std_logic_vector(3 downto 0);
begin
  -- Solo 500 -> bit1=0, bit0=sensores(0)
  u500: contador_monedas_optico
    port map(
      reloj=>reloj, reinicio=>reinicio,
      sensores => '0' & sensores(0),
      conteo => cnt500
    );

  -- Solo 1000 -> bit1=sensores(1), bit0=0
  u1000: contador_monedas_optico
    port map(
      reloj=>reloj, reinicio=>reinicio,
      sensores => sensores(1) & '0',
      conteo => cnt1000_2
    );

  -- Normaliza: cada 1000 suma 2 -> monedas reales
  mon1000 <= cnt1000_2 / 2;

  -- Dígitos BCD 0..99
  n500_d   <= std_logic_vector(to_unsigned(cnt500/10, 4));
  n500_u   <= std_logic_vector(to_unsigned(cnt500 mod 10, 4));
  n1000_d  <= std_logic_vector(to_unsigned(mon1000/10, 4));
  n1000_u  <= std_logic_vector(to_unsigned(mon1000 mod 10, 4));

  -- Displays usando tu bcd7seg
  U7_500: bcd7seg
    port map(A=>n500_u,  B=>n500_d,  Display_0=>D500_U,  Display_1=>D500_D);

  U7_1000: bcd7seg
    port map(A=>n1000_u, B=>n1000_d, Display_0=>D1000_U, Display_1=>D1000_D);
end arch_Test_Monedero_Displays;