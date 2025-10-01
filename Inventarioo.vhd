library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Inventarioo is
    port(
        clk : in  std_logic;
        reset : in  std_logic;
        solicitar : in  std_logic;                
        sel : in  unsigned(3 downto 0);

        producto : out std_logic;
        devolver : out std_logic;
        alarma : out std_logic 
    );
end Inventarioo;

architecture arch_Inventarioo of Inventarioo is
    
    type cajones_t is array(1 to 15) of integer range 0 to 3;
    signal cajones : cajones_t := (others => 3);
    signal total : integer range 0 to 45 := 45;
    
    signal ValorPrevio_solicitud : std_logic := '0';

    signal producto_registro : std_logic := '0';
    signal devolver_registro : std_logic := '0';
    signal alarma_registro : std_logic := '0';

    constant PULSO : integer := 5_000_000;
    signal producto_tiempo : integer range 0 to PULSO := 0;
    signal devolver_tiempo : integer range 0 to PULSO := 0;
	 
begin

    process(clk, reset)
    variable posicion_cajon : integer;
    variable nuevo_total : integer;
begin
    if reset = '1' then
        cajones <= (others => 3);
        total <= 45;
        ValorPrevio_solicitud <= '0';
        producto_registro <= '0';
        devolver_registro <= '0';
        alarma_registro <= '0';
        producto_tiempo <= 0;
        devolver_tiempo <= 0;

    elsif rising_edge(clk) then
        
        if producto_tiempo > 0 then
            producto_tiempo <= producto_tiempo - 1;
            producto_registro <= '1';
        else
            producto_registro <= '0';
        end if;

        if devolver_tiempo > 0 then
            devolver_tiempo <= devolver_tiempo - 1;
            devolver_registro <= '1';
        else
            devolver_registro <= '0';
        end if;

        if (ValorPrevio_solicitud = '0') and (solicitar = '1') then
            if total > 0 then
                posicion_cajon := to_integer(sel);
                if posicion_cajon >= 1 and posicion_cajon <= 15 then
                    if cajones(posicion_cajon) > 0 then
                        
                        nuevo_total := total - 1;

                        
                        cajones(posicion_cajon) <= cajones(posicion_cajon) - 1;
                        total <= nuevo_total;

                        
                        producto_tiempo <= PULSO;
                        producto_registro <= '1';

                        -- alarma solo si se acaba de entregar el último
                        if nuevo_total = 0 then
                            alarma_registro <= '1';
                        end if;
                    else
                        devolver_tiempo <= PULSO;
                        devolver_registro <= '1';
                    end if;
                else
                    devolver_tiempo <= PULSO;
                    devolver_registro <= '1';
                end if;
            else
                alarma_registro <= '1';
            end if;
        end if;

        ValorPrevio_solicitud <= solicitar;
    end if;
end process;
    
    producto <= producto_registro;
    devolver <= devolver_registro;
    alarma   <= alarma_registro;

end arch_Inventarioo;