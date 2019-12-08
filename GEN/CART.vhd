library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity CART is
	port(
		CLK			: in std_logic;
		RST_N			: in std_logic;
		ENABLE		: in std_logic;
		
		ROM_MODE		: in std_logic := '0';
		RAM_ID		: in std_logic_vector(7 downto 0);
		
		VA   			: in std_logic_vector(23 downto 1);
		VDI			: in std_logic_vector(15 downto 0);
		VDO			: out std_logic_vector(15 downto 0);
		AS_N			: in std_logic;
		RNW			: in std_logic;
		LDS_N			: in std_logic;
		UDS_N			: in std_logic;
		DTACK_N		: out std_logic;
		ASEL_N		: in std_logic;
		VCLK_CE		: in std_logic;
		CE0_N			: in std_logic;
		CART_N		: out std_logic;
		
		ROM_CE_N		: out std_logic;
		ROM_DI		: in std_logic_vector(15 downto 0);
		ROM_RDY		: in std_logic;
		
		RAM_CE_N		: out std_logic;
		RAM_DI		: in std_logic_vector(15 downto 0);
		RAM_RDY		: in std_logic
	);
end CART;

architecture rtl of CART is

	type MemState_t is (
		MS_IDLE,
		MS_WAIT,
		MS_ACCESS,
		MS_END
	);
	
	signal ROMS 				: MemState_t;
	signal RAMS 				: MemState_t;
	signal CART_ROM_SEL 		: std_logic;
	signal CART_RAM_SEL 		: std_logic;
	signal CART_ROM_DTACK_N : std_logic;
	signal CART_RAM_DTACK_N : std_logic;
	signal CART_ROM_DO 		: std_logic_vector(15 downto 0);
	signal CART_RAM_DO 		: std_logic_vector(15 downto 0);

begin

	CART_ROM_SEL <= ROM_MODE when CE0_N = '0' and (LDS_N = '0' or UDS_N = '0') and ASEL_N = '0' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			ROMS <= MS_IDLE;
			CART_ROM_DTACK_N <= '1';
			CART_ROM_DO <= (others => '0');
			ROM_CE_N <= '1';
		elsif rising_edge(CLK) then
			case ROMS is
				when MS_IDLE =>
					if CART_ROM_SEL = '1' and CART_ROM_DTACK_N = '1' then
						if RNW = '0' then
							CART_ROM_DTACK_N <= '0';
							ROMS <= MS_END;
						else
							ROM_CE_N <= '0';
							ROMS <= MS_WAIT;
						end if;
					end if;
					
				when MS_WAIT =>
					if ROM_RDY = '0' then
						ROMS <= MS_ACCESS;
					end if;
				
				when MS_ACCESS =>
					if ROM_RDY = '1' then
						CART_ROM_DO <= ROM_DI;
						CART_ROM_DTACK_N <= '0';
						
						ROMS <= MS_END;
					end if;
					
				when MS_END => 
					if CART_ROM_DTACK_N = '0' and ASEL_N = '1' then
						CART_ROM_DTACK_N <= '1';
						ROM_CE_N <= '1';
						ROMS <= MS_IDLE;
					end if;
					
				when others => null;
			end case;
		end if;
	end process;
	
	
	CART_RAM_SEL <= not ROM_MODE when CE0_N = '0' and (LDS_N = '0' or UDS_N = '0') and ASEL_N = '0' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			RAMS <= MS_IDLE;
			CART_RAM_DTACK_N <= '1';
			CART_RAM_DO <= (others => '0');
			RAM_CE_N <= '1';
		elsif rising_edge(CLK) then
			case RAMS is
				when MS_IDLE =>
					if CART_RAM_SEL = '1' and CART_RAM_DTACK_N = '1' then
						if VA(21) = '0' and RNW = '1' then						--RAM CART ID
							CART_RAM_DTACK_N <= '0';
							CART_RAM_DO <= x"FF" & RAM_ID;
							RAMS <= MS_END;
						elsif VA(21 downto 20) = "10" and LDS_N = '0' then	--RAM CART memory
							RAM_CE_N <= '0';
							RAMS <= MS_WAIT;
						else																--RAM CART write protection TODO
							CART_RAM_DTACK_N <= '0';
							CART_RAM_DO <= x"FFFF";
							RAMS <= MS_END;
						end if;
					end if;
					
				when MS_WAIT =>
					if RAM_RDY = '0' then
						RAMS <= MS_ACCESS;
					end if;
				
				when MS_ACCESS =>
					if RAM_RDY = '1' then
						CART_RAM_DO <= x"FF" & RAM_DI(7 downto 0);
						CART_RAM_DTACK_N <= '0';
						
						RAMS <= MS_END;
					end if;
					
				when MS_END => 
					if CART_RAM_DTACK_N = '0' and ASEL_N = '1' then
						CART_RAM_DTACK_N <= '1';
						RAM_CE_N <= '1';
						RAMS <= MS_IDLE;
					end if;
					
				when others => null;
			end case;
		end if;
	end process;
	
	VDO <= CART_ROM_DO when CART_ROM_DTACK_N = '0' else CART_RAM_DO;
	DTACK_N <= CART_ROM_DTACK_N and CART_RAM_DTACK_N;
	
	CART_N <= not ROM_MODE;

end rtl;
