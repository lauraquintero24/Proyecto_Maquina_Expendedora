library ieee;
use ieee.std_logic_1164.all;

entity bin_dec_5bits is
	port
	(
		-- Input ports
		V	: in  std_logic_vector(4 downto 0);  

		-- Output ports
		D0 	: out std_logic_vector(6 downto 0);  -- Unidades
		D1 	: out std_logic_vector(6 downto 0)   -- Decenas
	);
end bin_dec_5bits;


architecture arch_bin_dec of bin_dec_5bits is

	component comparador_5bits 
		port( V : in  std_logic_vector(4 downto 0);
				Z : out std_logic_vector(1 downto 0) );
	end component;

	component cir_A_5bits 
		port( V : in  std_logic_vector(4 downto 0);
				D0 : out std_logic_vector(3 downto 0) );
	end component;

	component cir_B_5bits 
		port( Z : in  std_logic_vector(1 downto 0);
				D1 : out std_logic_vector(3 downto 0) );
	end component;

	component dec_bcd 
		port( A, B : in  std_logic_vector(3 downto 0);
				D0, D1 : out std_logic_vector(6 downto 0) );
	end component;

	signal Z_sig    : std_logic_vector(1 downto 0);
	signal D0_A_sig : std_logic_vector(3 downto 0);
	signal D1_B_sig : std_logic_vector(3 downto 0);
    
begin
	
	U1: comparador_5bits port map (V => V, Z => Z_sig);
	U2: cir_A_5bits port map (V => V, D0 => D0_A_sig);
	U3: cir_B_5bits port map (Z => Z_sig, D1 => D1_B_sig);
	U4: dec_bcd port map (A => D0_A_sig, B => D1_B_sig, D0 => D0, D1 => D1);
	
end arch_bin_dec;