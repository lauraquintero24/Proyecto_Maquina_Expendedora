-- Inventarioo.vhd  |  RAM 15x2 + FSM  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Inventarioooo is
    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        solicitar : in  std_logic;                -- pulso del usuario
        sel       : in  unsigned(3 downto 0);     -- 1..15 válidos

        producto  : out std_logic;                -- pulso (PULSO ciclos) si entrega
        devolver  : out std_logic;                -- pulso si no hay/selección inválida
        alarma    : out std_logic                 -- 1 cuando total llega a 0
    );
end Inventarioooo;

architecture arch_Inventarioooo of Inventarioooo is
    -------------------------------------------------------------------------
    -- Memoria: 15 cajones x 2 bits (0..3 por cajón)
    -------------------------------------------------------------------------
    type ram_t is array(0 to 14) of unsigned(1 downto 0);
    signal ram_inv : ram_t := (others => to_unsigned(3,2));  -- arranque: 3 c/u
    -- Sugerencia a síntesis (opcional):
    attribute ramstyle : string;
    attribute ramstyle of ram_inv : signal is "M9K";

    -- Total global 0..45
    signal total : integer range 0 to 45 := 45;

    -- Temporización de pulsos de salida
    constant PULSO : integer := 5_000_000;  -- ~100 ms @ 50 MHz
    signal t_prod  : integer range 0 to PULSO := 0;
    signal t_dev   : integer range 0 to PULSO := 0;

    signal producto_reg : std_logic := '0';
    signal devolver_reg : std_logic := '0';
    signal alarma_reg   : std_logic := '0';

    -- FSM
    type st_t is (ESPERA, LEE, DECIDE, ESCRIBE_OK, EMITE_OK);
    signal st : st_t := ESPERA;

    -- Captura de solicitud y dirección válida
    signal sol_prev : std_logic := '0';
    signal dir      : integer range 0 to 14 := 0;
    signal dir_val  : std_logic := '0';

    -- Registro de stock leído
    signal stock_rd : integer range 0 to 3 := 0;

    -- Constante 1 en 2 bits
    constant UNO2 : unsigned(1 downto 0) := to_unsigned(1,2);
begin
    -- Asignación de salidas
    producto <= producto_reg;
    devolver <= devolver_reg;
    alarma   <= alarma_reg;

    -------------------------------------------------------------------------
    -- Máquina de estados + generación de pulsos
    -------------------------------------------------------------------------
    process(clk, reset)
        variable sel_i : integer;
    begin
        if reset = '1' then
            ram_inv      <= (others => to_unsigned(3,2));
            total        <= 45;
            t_prod       <= 0;
            t_dev        <= 0;
            producto_reg <= '0';
            devolver_reg <= '0';
            alarma_reg   <= '0';
            st           <= ESPERA;
            sol_prev     <= '0';
            dir_val      <= '0';
            dir          <= 0;
            stock_rd     <= 0;

        elsif rising_edge(clk) then
            -- Pulsos de salida
            if t_prod > 0 then
                t_prod <= t_prod - 1;
                producto_reg <= '1';
            else
                producto_reg <= '0';
            end if;

            if t_dev > 0 then
                t_dev <= t_dev - 1;
                devolver_reg <= '1';
            else
                devolver_reg <= '0';
            end if;

            -- Detección de flanco de solicitar y validación de selección
            dir_val <= '0';
            if (sol_prev = '0') and (solicitar = '1') then
                sel_i := to_integer(sel);
                if sel_i >= 1 and sel_i <= 15 then
                    dir     <= sel_i - 1;  -- 0..14
                    dir_val <= '1';
                else
                    -- selección inválida -> devolver
                    t_dev <= PULSO;
                end if;
            end if;
            sol_prev <= solicitar;

            -- FSM
            case st is
                when ESPERA =>
                    if dir_val = '1' then
                        if total = 0 then
                            alarma_reg <= '1';     -- sin inventario global
                            -- no transita; queda en ESPERA
                        else
                            st <= LEE;
                        end if;
                    end if;

                when LEE =>
                    -- lectura "síncrona": registrar valor leído
                    stock_rd <= to_integer(ram_inv(dir));
                    st <= DECIDE;

                when DECIDE =>
                    if stock_rd > 0 then
                        st <= ESCRIBE_OK;
                    else
                        -- cajón vacío -> devolver
                        t_dev <= PULSO;
                        st    <= ESPERA;
                    end if;

                when ESCRIBE_OK =>
                    -- decrementa cajón y total
                    ram_inv(dir) <= ram_inv(dir) - UNO2;
                    if total > 0 then
                        -- si tras esta entrega el total pasa a 0, deja alarma en 1
                        if total = 1 then
                            alarma_reg <= '1';
                        end if;
                        total <= total - 1;
                    end if;
                    st <= EMITE_OK;

                when EMITE_OK =>
                    t_prod <= PULSO;                -- pulso de "producto"
                    st     <= ESPERA;
            end case;
        end if;
    end process;
end arch_Inventarioooo;