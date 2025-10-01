library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity summonedas is
port (
    Clk      : in  std_logic;
    Reset    : in  std_logic;
    Sensor   : in  std_logic_vector(1 downto 0);
    CNT      : out integer range 0 to 99;
    D0       : out std_logic_vector(6 downto 0);  -- unidades
    D1       : out std_logic_vector(6 downto 0)   -- decenas
);
end summonedas;

architecture arch of summonedas is

    component contador_monedas_optico 
        Port ( 
            Clk      : in  std_logic;
            Reset    : in  std_logic;
            Sensor   : in  std_logic_vector(1 downto 0);
            CNT      : out integer range 0 to 99
        );
    end component;
	 
    component bin_dec_5bits is
        port (
            V  : in  std_logic_vector(4 downto 0);  
            D0 : out std_logic_vector(6 downto 0);  -- Unidades
            D1 : out std_logic_vector(6 downto 0)   -- Decenas
        );
    end component;
    
    -- Señales internas
    signal cnt_integer : integer range 0 to 99;
    signal cnt_vector  : std_logic_vector(4 downto 0);
      
begin
  
    -- Instanciar contador de monedas
    monedero : contador_monedas_optico 
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Sensor => Sensor,
            CNT    => cnt_integer  -- Conectar a señal interna
        );
    
    -- Convertir integer a std_logic_vector (5 bits)
    cnt_vector <= std_logic_vector(to_unsigned(cnt_integer, 5));
    
    -- Conectar salida principal
    CNT <= cnt_integer;
    
    -- Instanciar conversor para displays
    conversor : bin_dec_5bits
        port map (
            V  => cnt_vector,  -- Valor 5 bits
            D0 => D0,          -- unidades
            D1 => D1           -- decenas
        );
    
end arch;

