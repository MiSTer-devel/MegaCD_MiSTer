library IEEE;
use IEEE.Std_Logic_1164.all;
library STD;
use ieee.numeric_std.all;

package ASIC_PKG is  
		
	type WordRamState_t is (
		WRS_IDLE,
		WRS_READ,
		WRS_WRITE,
		WRS_END
	);
	
	type PrgRamState_t is (
		PRS_IDLE,
		PRS_WAIT,
		PRS_READ,
		PRS_WRITE,
		PRS_END,
		PRS_DMA_WAIT,
		PRS_DMA_WRITE,
		PRS_DMA_END,
		PRS_REFRESH_WAIT,
		PRS_REFRESH,
		PRS_REFRESH_END
	);
	
	type RomState_t is (
		ROMS_IDLE,
		ROMS_WAIT,
		ROMS_ACCESS,
		ROMS_END
	);
	
	type WordRamAccess_t is (
		WRA_IDLE,
		WRA_M68K_ACCESS,
		WRA_S68K_ACCESS,
		WRA_DMA_ACCESS,
		WRA_GFX_ACCESS,
		WRA_M68K_END,
		WRA_S68K_END,
		WRA_DMA_END,
		WRA_GFX_END
	);
	
	type GfxState_t is (
		GS_IDLE,
		GS_XY_READ,
		GS_XY_WAIT,
		GS_STAMP_READ,
		GS_STAMP_WAIT,
		GS_DOT_READ,
		GS_DOT_WAIT,
		GS_WRITE,
		GS_WRITE_WAIT,
		GS_END
	);
	
	type PcmAccess_t is (
		PCMA_IDLE,
		PCMA_DMA_HALT0,
		PCMA_DMA_HALT1,
		PCMA_DMA_HALT2,
		PCMA_DMA_WRITE,
		PCMA_END
	);
	
	type DMAState_t is (
		DS_IDLE,
		DS_CDC_READ,
		DS_WRITE,
		DS_WRITE_WAIT,
		DS_END
	);
	
	type HaltState_t is (
		HS_IDLE,
		HS_HALT0,
		HS_HALT1,
		HS_HALT2,
		HS_EXEC,
		HS_END
	);
	
	type WordRam_r is record
		A 				: std_logic_vector(16 downto 1);
		DO 			: std_logic_vector(15 downto 0);
		RNW 			: std_logic_vector(3 downto 0);
		EXEC 			: std_logic;
		PM 			: std_logic_vector(1 downto 0);
		DOT_IMAGE 	: std_logic_vector(1 downto 0);
	end record;
	
	type Graphic_r is record
		X 		: std_logic_vector(23 downto 0);
		Y 		: std_logic_vector(23 downto 0);
		DX 	: std_logic_vector(23 downto 0);
		DY 	: std_logic_vector(23 downto 0);
		SD 	: std_logic_vector(15 downto 0);
		NIB 	: std_logic_vector(1 downto 0);
	end record;

	
	type reg8x16_t is array(0 to 7) of std_logic_vector(15 downto 0);
	type reg64x16_t is array(0 to 63) of std_logic_vector(15 downto 0);
	
	function GetFontData(sb: std_logic_vector(15 downto 0); cs0: std_logic_vector(3 downto 0); cs1: std_logic_vector(3 downto 0); word: integer range 0 to 3) return std_logic_vector;
	function GetWriteColor(new_dat: std_logic_vector(3 downto 0); old_dat: std_logic_vector(3 downto 0); pm: std_logic_vector(1 downto 0)) return std_logic_vector;
	
end ASIC_PKG;

package body ASIC_PKG is

	function GetFontData(sb: std_logic_vector(15 downto 0); cs0: std_logic_vector(3 downto 0); cs1: std_logic_vector(3 downto 0); word: integer range 0 to 3) return std_logic_vector is
		variable bits: std_logic_vector(3 downto 0); 
		variable res: std_logic_vector(15 downto 0); 
	begin
		case word is
			when 0 =>		bits := sb(15 downto 12);
			when 1 =>		bits := sb(11 downto  8);
			when 2 =>		bits := sb( 7 downto  4);
			when others => bits := sb( 3 downto  0);
		end case;
		
		if bits(0) = '0' then
			res(3 downto 0) := cs0;
		else
			res(3 downto 0) := cs1;
		end if;
		
		if bits(1) = '0' then
			res(7 downto 4) := cs0;
		else
			res(7 downto 4) := cs1;
		end if;
		
		if bits(2) = '0' then
			res(11 downto 8) := cs0;
		else
			res(11 downto 8) := cs1;
		end if;
		
		if bits(3) = '0' then
			res(15 downto 12) := cs0;
		else
			res(15 downto 12) := cs1;
		end if;
		
		return res;
	end function;
	
	function GetWriteColor(new_dat: std_logic_vector(3 downto 0); old_dat: std_logic_vector(3 downto 0); pm: std_logic_vector(1 downto 0)) return std_logic_vector is
		variable res: std_logic_vector(3 downto 0); 
	begin
		res := old_dat;
		if (new_dat /= x"0" and pm = "10") or (old_dat = x"0" and pm = "01") or pm = "00" then
			res:= new_dat;
		end if;

		return res;
	end function;

end package body ASIC_PKG;
