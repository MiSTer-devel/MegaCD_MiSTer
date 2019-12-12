library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.ASIC_PKG.all; 


entity ASIC is
	port(
		CLK				: in std_logic;
		RST_N				: in std_logic;
		ENABLE			: in std_logic;
		
		S68K_A   		: in std_logic_vector(23 downto 1);
		S68K_DI			: in std_logic_vector(15 downto 0);
		S68K_DO			: out std_logic_vector(15 downto 0);
		S68K_AS_N		: in std_logic;
		S68K_RNW			: in std_logic;
		S68K_UDS_N		: in std_logic;
		S68K_LDS_N		: in std_logic;
		S68K_DTACK_N	: out std_logic;
		S68K_IPL_N		: out std_logic_vector(2 downto 0);
		S68K_VPA_N		: out std_logic;
		S68K_FC			: in std_logic_vector(1 downto 0);
		S68K_HALT_N		: out std_logic;
		S68K_RESET_N	: out std_logic;
		S68K_CE_F		: out std_logic;
		S68K_CE_R		: out std_logic;
		
		EXT_VA   		: in std_logic_vector(17 downto 1);
		EXT_VDI			: in std_logic_vector(15 downto 0);
		EXT_VDO			: out std_logic_vector(15 downto 0);
		EXT_AS_N			: in std_logic;
		EXT_RNW			: in std_logic;
		EXT_UDS_N		: in std_logic;
		EXT_LDS_N		: in std_logic;
		EXT_DTACK_N		: out std_logic;
		EXT_ASEL_N		: in std_logic;
		EXT_VCLK_CE		: in std_logic;
		EXT_RAS2_N		: in std_logic;
		EXT_ROM_N		: in std_logic;
		EXT_FDC_N		: in std_logic;
		
		PRG_A				: out std_logic_vector(17 downto 0);
		PRG_DI			: in std_logic_vector(15 downto 0);
		PRG_DO			: out std_logic_vector(15 downto 0);
		PRG_WRL_N		: out std_logic;	
		PRG_WRH_N		: out std_logic;	
		PRG_OE_N			: out std_logic;
		PRG_RFS			: out std_logic;
		PRG_RDY			: in std_logic;
		
		PCM_A				: out std_logic_vector(12 downto 0);
		PCM_DI			: out std_logic_vector(7 downto 0);
		PCM_WE_N			: out std_logic;
		PCM_N				: out std_logic;
		
		ROM_DI			: in std_logic_vector(15 downto 0);
		ROM_CE_N			: out std_logic;
		ROM_RDY			: in std_logic;
		
		PRAM_N			: out std_logic;
		BRAM_N			: out std_logic;
		BROM_N			: out std_logic;
		CDC_N				: out std_logic;
		COE_N				: out std_logic;
		CLWE_N			: out std_logic;
		CUWE_N			: out std_logic;
		CDC_INT_N		: in std_logic;
		ERES_N			: out std_logic;
		
		CDC_HDI			: in std_logic_vector(7 downto 0);
		CDC_HRD_N		: out std_logic;
		CDC_DTEN_N		: in std_logic;
		CDC_WAIT_N		: in std_logic;
		
		CD_DI				: in std_logic_vector(15 downto 0);
		CD_SC_WR			: in std_logic;
		
		CDD_STAT			: in std_logic_vector(39 downto 0);
		CDD_COMM			: out std_logic_vector(39 downto 0);
		CDD_SEND			: out std_logic;
		CDD_REC			: in std_logic;
		CDD_DM			: in std_logic;
		
		WORDRAM0_A   	: out std_logic_vector(15 downto 0);
		WORDRAM0_DI		: in std_logic_vector(15 downto 0);
		WORDRAM0_DO		: out std_logic_vector(15 downto 0);
		WORDRAM0_WR		: out std_logic;
		WORDRAM1_A   	: out std_logic_vector(15 downto 0);
		WORDRAM1_DI		: in std_logic_vector(15 downto 0);
		WORDRAM1_DO		: out std_logic_vector(15 downto 0);
		WORDRAM1_WR		: out std_logic;
		
		LED_RED			: out std_logic;
		LED_GREEN		: out std_logic
	);
end ASIC;

architecture rtl of ASIC is

	constant VER : std_logic_vector(3 downto 0) := x"0";
	
	signal EN 							: std_logic;
	signal CLK_CNT 					: unsigned(1 downto 0) := (others => '0');
	signal CLK_12M_F 					: std_logic;
	signal CLK_12M_R 					: std_logic;
	
	signal M68K_GA_SEL 				: std_logic;
	signal S68K_GA_SEL 				: std_logic;
	signal S68K_SC_SEL 				: std_logic;
	signal M68K_PRG_RAM_SEL 		: std_logic;
	signal S68K_PRG_RAM_SEL 		: std_logic;
	signal M68K_WORD_RAM_SEL 		: std_logic;
	signal S68K_WORD_RAM_SEL 		: std_logic;
	signal S68K_PCM_SEL 				: std_logic;
	signal S68K_BRAM_SEL 			: std_logic;
	signal DMA_PRG_RAM_SEL 			: std_logic;
	signal DMA_WORD_RAM_SEL 		: std_logic;
	signal DMA_PCM_SEL 				: std_logic;
	signal M68K_REG_DTACK_N 		: std_logic;
	signal M68K_PRGRAM_DTACK_N 	: std_logic;
	signal M68K_WORDRAM_DTACK_N	: std_logic;
	signal M68K_REG_DO 				: std_logic_vector(15 downto 0);
	signal M68K_PRGRAM_DO 			: std_logic_vector(15 downto 0);
	signal M68K_WORDRAM_DO 			: std_logic_vector(15 downto 0);
	signal S68K_REG_DTACK_N 		: std_logic;
	signal S68K_PRGRAM_DTACK_N 	: std_logic;
	signal S68K_WORDRAM_DTACK_N 	: std_logic;
	signal S68K_PCM_DTACK_N 		: std_logic;
	signal S68K_BRAM_DTACK_N 		: std_logic;
	signal S68K_REG_DO 				: std_logic_vector(15 downto 0);
	signal S68K_PRGRAM_DO 			: std_logic_vector(15 downto 0);
	signal S68K_WORDRAM_DO 			: std_logic_vector(15 downto 0);
	signal S68K_MDR 					: std_logic_vector(15 downto 0);
	signal RFS_PRGRAM_DTACK_N 		: std_logic;
	
		
	--PRG_RAM
	signal PRMS 						: PrgRamState_t;
	signal PRSS 						: PrgRamState_t;
	signal PRG_RAM_ADDR 				: std_logic_vector(18 downto 1);
	signal PRG_RAM_DO 				: std_logic_vector(15 downto 0);
	signal PRG_RAM_WRL 				: std_logic;
	signal PRG_RAM_WRH 				: std_logic;
	signal PRG_RAM_RD 				: std_logic;
	signal PRG_RAM_RFS 				: std_logic;
	signal PRG_RAM_RFS_TIMER 		: unsigned(9 downto 0);
	signal PRG_RAM_RFS_SCHED 		: std_logic;
	
	--WORD_RAM
	signal WR0A 						: WordRamAccess_t;
	signal WR1A 						: WordRamAccess_t;
	signal WORD_RAM_1M0_DI 			: std_logic_vector(15 downto 0);
	signal WORD_RAM_1M1_DI 			: std_logic_vector(15 downto 0);
	signal WORD_RAM_1M0_DO 			: std_logic_vector(15 downto 0);
	signal WORD_RAM_1M1_DO 			: std_logic_vector(15 downto 0);
	signal WORD_RAM_1M0_WR 			: std_logic;
	signal WORD_RAM_1M1_WR 			: std_logic;
	signal WR0S 						: WordRamState_t;
	signal WR1S 						: WordRamState_t;
	signal WR0R 						: WordRam_r;
	signal WR1R 						: WordRam_r;
	signal LAST_M68K_WORDRAM_DO	: std_logic_vector(15 downto 0);
	
	--BROM
	signal ROMS 						: RomState_t;
	signal M68K_ROM_DTACK_N 		: std_logic;
	signal M68K_ROM_DO 				: std_logic_vector(15 downto 0);
	signal M68K_ROM_SEL 				: std_logic;
	
	--Grafics
	signal GS 							: GfxState_t;
	signal GFX 							: Graphic_r;
	signal VA 							: std_logic_vector(17 downto 1);
	signal IMAGE_DOT 					: unsigned(2 downto 0);
	signal IMAGE_LINE 				: unsigned(18 downto 3);
	signal IMAGE_CELL 				: unsigned(18 downto 6);
	signal HDOTS 						: std_logic_vector(8 downto 0);
	signal VDOTS 						: std_logic_vector(7 downto 0);
	signal GFX_WORDRAM_DO 			: std_logic_vector(15 downto 0);
	signal GFX_DO 						: std_logic_vector(15 downto 0);
	signal WR_GFX_RUN 				: std_logic;
	signal GFX_ADDR 					: std_logic_vector(17 downto 1);
	signal GFX_SEL 					: std_logic;
	signal GFX_RMW 					: std_logic;
	
	--DMA
	signal DS 							: DMAState_t;
	signal DMA_ADDR 					: std_logic_vector(18 downto 1);
	signal DMA_DAT 					: std_logic_vector(15 downto 0);
	signal DMA_BYTE 					: std_logic;
	signal DMA_RUN 					: std_logic;
	signal PR_DMA_RUN 				: std_logic;
	signal WR_DMA_RUN 				: std_logic;
	signal PCM_DMA_RUN 				: std_logic;
	
	--G/A registers
	signal RES0 						: std_logic;
	signal LEDR 						: std_logic;
	signal LEDG 						: std_logic;
	signal SRES 						: std_logic;
	signal SBRQ 						: std_logic;
	signal IFL2 						: std_logic;
	signal MODE 						: std_logic;
	signal DMNA0 						: std_logic;
	signal DMNA1 						: std_logic;
	signal RET0 						: std_logic;
	signal RET1 						: std_logic;
	signal PM 							: std_logic_vector(1 downto 0);
	signal BK 							: std_logic_vector(1 downto 0);
	signal WP 							: std_logic_vector(7 downto 0);
	signal DD 							: std_logic_vector(2 downto 0);
	signal EDT 							: std_logic;
	signal DSR 							: std_logic;
	signal HD 							: std_logic_vector(15 downto 0);
	signal DMAA 						: std_logic_vector(18 downto 3);
	signal HIB 							: std_logic_vector(15 downto 0);
	signal SW 							: std_logic_vector(11 downto 0);
	signal CFS 							: std_logic_vector(7 downto 0);
	signal CFM 							: std_logic_vector(7 downto 0);
	signal CC 							: reg8x16_t;
	signal CS 							: reg8x16_t;
	signal TM 							: std_logic_vector(7 downto 0);
	signal IEN 							: std_logic_vector(6 downto 1);
	signal SC0 							: std_logic_vector(3 downto 0);
	signal SC1 							: std_logic_vector(3 downto 0);
	signal SB 							: std_logic_vector(15 downto 0);
	signal RPT 							: std_logic;
	signal STS 							: std_logic;
	signal SMS 							: std_logic;
	signal GRON 						: std_logic;
	signal SMBA 						: std_logic_vector(17 downto 7);
	signal VCS 							: std_logic_vector(4 downto 0);
	signal ISA 							: std_logic_vector(17 downto 5);
	signal LN		 					: std_logic_vector(2 downto 0);
	signal DOT 							: std_logic_vector(2 downto 0);
	signal HW 							: std_logic_vector(8 downto 0);
	signal VW 							: std_logic_vector(7 downto 0);
	signal TVBA 						: std_logic_vector(17 downto 3);
--	signal STA 							: std_logic_vector(6 downto 1);
--	signal SAOR 						: std_logic;
--	signal SBA 							: reg64x16_t;
	signal HOCK 						: std_logic;
	signal CDDS 						: std_logic_vector(39 downto 0);
	signal CDDC 						: std_logic_vector(39 downto 0);
	
	signal MAIN_RST_EXEC 			: std_logic;
	signal SUB_RST_EXEC 				: std_logic;
	signal MCD_RST_DONE 				: std_logic;
	signal RST_CNT 					: unsigned(2 downto 0);
	signal RET_REQ 					: std_logic;
	signal RET_SET 					: std_logic;
	signal DMNA_REQ 					: std_logic;
	signal DMNA_SET 					: std_logic;
	signal MODE_REQ 					: std_logic;
	signal DMA_ADDR_SET 				: std_logic;
	signal VW_SET 						: std_logic;
	signal TIME_CLK_CNT 				: unsigned(8 downto 0);
	signal TIMER 						: unsigned(7 downto 0);
	signal INT_PEND 					: std_logic_vector(6 downto 1);
	signal INT_ACK 					: std_logic_vector(6 downto 1);
	signal INT_VPA_N 					: std_logic;
	signal INT_IPL 					: std_logic_vector(2 downto 0);
	signal OLD_IEN1 					: std_logic;
	signal OLD_IEN2 					: std_logic;
	signal OLD_IEN4 					: std_logic;
	signal OLD_IEN5 					: std_logic;
	signal CDD_REC_OLD 				: std_logic;
	signal HOCK_OLD 					: std_logic;
	signal CD_SC_WR_OLD 				: std_logic;
	signal CDD_STAT_RECEIVED 		: std_logic;
--	signal SC_CNT 						: unsigned(5 downto 0);
	signal CDC_HRD 					: std_logic;
	signal MAIN_CPU_CDC_READ 		: std_logic;
	signal SUB_CPU_CDC_READ 		: std_logic;
	signal OLD_CDC_INT_N 			: std_logic;
	signal SW_CLR 						: std_logic;
	signal TIMER_SET 					: std_logic;
	signal GEN_S68K_HALT				: std_logic;
	
	signal PCMA 						: PcmAccess_t;
	signal PCM_DMA_ADDR 				: std_logic_vector(12 downto 0);
	signal PCM_DMA_DO 				: std_logic_vector(7 downto 0);
	signal PCM_DMA_WR 				: std_logic;
	signal PCM_S68K_HALT 			: std_logic;
	signal PCM_HALT_WAIT 			: unsigned(1 downto 0);
	
	signal HS 							: HaltState_t;
	signal HALT_WAIT 					: unsigned(1 downto 0);
	signal S68K_HALT 					: std_logic;
			
begin

	EN <= ENABLE;
	
	process( CLK )
	begin
		if rising_edge(CLK) then
			if EN = '1' then
				CLK_CNT <= CLK_CNT + 1;
			end if;
		end if;
	end process;
	
	CLK_12M_F <= EN when CLK_CNT = "01" else '0';
	CLK_12M_R <= EN when CLK_CNT = "11" else '0';
	
	
	--Reset
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			ERES_N <= '0';
			MCD_RST_DONE <= '1';
			RST_CNT <= (others => '1');
		elsif rising_edge(CLK) then
			if EN = '1' then
				MCD_RST_DONE <= '0';
				RST_CNT <= RST_CNT - 1;
				if MAIN_RST_EXEC = '1' or SUB_RST_EXEC = '1' then
					ERES_N <= '0';
					MCD_RST_DONE <= '1';
					RST_CNT <= "111";
				elsif RST_CNT = 0 then
					ERES_N <= '1';
				end if;
			end if;
		end if;
	end process;

	--Wordram memory mode
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			RET0 <= '1';
			RET1 <= '1';
			DMNA0 <= '0';
			DMNA1 <= '0';
			RET_REQ <= '0';
			RET_SET <= '0';
			DMNA_REQ <= '0';
			DMNA_SET <= '0';
			
			MODE <= '0';
		elsif rising_edge(CLK) then
			if M68K_GA_SEL = '1' and EXT_VA(5 downto 1) = "00001" and EXT_RNW = '0' and EXT_LDS_N = '0' and M68K_REG_DTACK_N = '1' then
				if EXT_VDI(1) = '1' then
					DMNA0 <= '1';
					RET0 <= '0';
				elsif EXT_VDI(1) = '0' then
					DMNA1 <= '1';
				end if;
			end if;
				
			if EN = '1' then
				if S68K_GA_SEL = '1' and S68K_A(7 downto 1) = "0000001" and S68K_RNW = '0' and S68K_REG_DTACK_N = '1' then
					if S68K_DI(0) = '1' then
						RET0 <= '1';
						DMNA0 <= '0';
					end if;
					RET1 <= S68K_DI(0);
					if RET1 /= S68K_DI(0) then
						DMNA1 <= '0';
					end if;
					
					MODE <= S68K_DI(2);
				end if;
			end if;
		end if;
	end process;
	
	
	--DMA
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			HD <= (others => '0');
			DSR <= '0';
			EDT <= '0';
			DS <= DS_IDLE;
			DMA_ADDR <= (others => '0');
			DMA_DAT <= (others => '0');
			DMA_BYTE <= '0';
			DMA_RUN <= '0';
			CDC_HRD <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				if DMA_ADDR_SET = '1' then
					DMA_ADDR <= DMAA(18 downto 3) & "00";
					EDT <= '0';
					DS <= DS_IDLE;
				end if;
				
				case DS is
					when DS_IDLE =>
						if CDC_DTEN_N = '0' then
							if CDC_WAIT_N = '1' then
								CDC_HRD <= '1';
								DS <= DS_CDC_READ;
								
								DMA_RUN <= DD(2);
							end if;
							EDT <= '0';
						elsif CDC_DTEN_N = '1' then
							DMA_RUN <= '0';
							if DMA_RUN = '1' and DD(2) = '1' then
								DSR <= '0';
							end if;
							EDT <= '1';
						end if;
						
					when DS_CDC_READ =>
						if CDC_WAIT_N = '0' then
							CDC_HRD <= '0';
							
							if DMA_BYTE = '0' and DD /= "100" then
								DMA_DAT(15 downto 8) <= CDC_HDI;
								DMA_BYTE <= '1';
								DS <= DS_IDLE;
							else
								DMA_DAT(7 downto 0) <= CDC_HDI;
								DMA_BYTE <= '0';
								DSR <= '1';
								DS <= DS_WRITE;
							end if;
						end if;
					
					when DS_WRITE =>
						case DD is
							when "010" | "011" =>
								HD <= DMA_DAT;
								DS <= DS_WRITE_WAIT;
							
							when "100" =>
								if PCM_DMA_RUN = '1' then
									DS <= DS_WRITE_WAIT;
								end if;
							
							when "101" =>
								if PR_DMA_RUN = '1' then
									DS <= DS_WRITE_WAIT;
								end if;
								
							when "111" =>
								if WR_DMA_RUN = '1' then
									DS <= DS_WRITE_WAIT;
								end if;
								
							when others =>
								DS <= DS_IDLE;
						end case;
						
					when DS_WRITE_WAIT =>
						case DD is
							when "010" =>
								if MAIN_CPU_CDC_READ = '1' then
									DSR <= '0';
									DS <= DS_IDLE;
								end if;
								
							when "011" =>
								if SUB_CPU_CDC_READ = '1' then
									DSR <= '0';
									DS <= DS_IDLE;
								end if;
							
							when "100" =>
								if PCM_DMA_RUN = '0' then
									DMA_ADDR <= std_logic_vector( unsigned(DMA_ADDR) + 1 );
									DS <= DS_IDLE;
								end if;
							
							when "101" =>
								if PR_DMA_RUN = '0' then
									DMA_ADDR <= std_logic_vector( unsigned(DMA_ADDR) + 1 );
									DS <= DS_IDLE;
								end if;
								
							when "111" =>
								if WR_DMA_RUN = '0' then
									DMA_ADDR <= std_logic_vector( unsigned(DMA_ADDR) + 1 );
									DS <= DS_IDLE;
								end if;
								
							when others =>
								DS <= DS_IDLE;
						end case;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	CDC_HRD_N <= not CDC_HRD;
	
	
	--Genesis GA
	M68K_GA_SEL <= '1' when EXT_FDC_N = '0' and (EXT_LDS_N = '0' or EXT_UDS_N = '0') and EXT_AS_N = '0' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			M68K_REG_DTACK_N <= '1';
			MAIN_RST_EXEC <= '0';
			SRES <= '0';
			SBRQ <= '1';
			IFL2 <= '0';
			BK <= (others => '0');
			WP <= (others => '0');
			HIB <= (others => '1');
			CFM <= (others => '0');
			CC <= (others => (others => '0'));
			INT_PEND(2) <= '0';
			MAIN_CPU_CDC_READ <= '0';
			
		elsif rising_edge(CLK) then
			MAIN_RST_EXEC <= '0';
			
			OLD_IEN2 <= IEN(2);
			if INT_ACK(2) = '1' and INT_PEND(2) = '1' then
				INT_PEND(2) <= '0';
				IFL2 <= '0';
			elsif IEN(2) = '0' and OLD_IEN2 = '1' and INT_PEND(2) = '1' then
				INT_PEND(2) <= '0';
				IFL2 <= '0';
			end if;
			
			if MAIN_CPU_CDC_READ = '1' and DS = DS_IDLE then
				MAIN_CPU_CDC_READ <= '0';
			end if;
			
			if M68K_GA_SEL = '1' and M68K_REG_DTACK_N = '1' then
				if EXT_RNW = '0' then
					case EXT_VA(5 downto 1) is
						when "00000" =>			--$A12000 BUSREQ,RESET
							if EXT_LDS_N = '0' then
								SRES <= EXT_VDI(0);
								SBRQ <= EXT_VDI(1);
								MAIN_RST_EXEC <= not EXT_VDI(0);
							end if;
							if EXT_UDS_N = '0' then
								if EXT_VDI(8) = '1' and IEN(2) = '1' then
									INT_PEND(2) <= '1';
									IFL2 <= '1';
								end if;
							end if;
						when "00001" =>			--$A12002 Memory mode/Write protect
							if EXT_LDS_N = '0' then
								BK <= EXT_VDI(7 downto 6);
							end if;
							if EXT_UDS_N = '0' then
								WP <= EXT_VDI(15 downto 8);
							end if;
						when "00010" => null;	--$A12004 CDC mode (read only)
						when "00011" =>			--$A12006 H-INT vector
							if EXT_LDS_N = '0' then
								HIB(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								HIB(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "00100" => null;	--$A12008 CDC host data (read only)
						when "00101" => null;	--$A1200A Reserved
						when "00110" => null;	--$A1200C Stop watch (read only)
						when "00111" =>			--$A1200E Communication flag
							CFM <= EXT_VDI(15 downto 8);
						when "01000" =>			--$A12010 Communication command 0
							if EXT_LDS_N = '0' then
								CC(0)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(0)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01001" =>			--$A12012 Communication command 1
							if EXT_LDS_N = '0' then
								CC(1)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(1)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01010" =>			--$A12014 Communication command 2
							if EXT_LDS_N = '0' then
								CC(2)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(2)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01011" =>			--$A12016 Communication command 3
							if EXT_LDS_N = '0' then
								CC(3)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(3)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01100" =>			--$A12018 Communication command 4
							if EXT_LDS_N = '0' then
								CC(4)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(4)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01101" =>			--$A1201A Communication command 5
							if EXT_LDS_N = '0' then
								CC(5)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(5)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01110" =>			--$A1201C Communication command 6
							if EXT_LDS_N = '0' then
								CC(6)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(6)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "01111" =>			--$A1201E Communication command 7
							if EXT_LDS_N = '0' then
								CC(7)(7 downto 0) <= EXT_VDI(7 downto 0);
							end if;
							if EXT_UDS_N = '0' then
								CC(7)(15 downto 8) <= EXT_VDI(15 downto 8);
							end if;
						when "10000" => null;	--$A12020 Communication status 0 (read only)
						when "10001" => null;	--$A12022 Communication status 1 (read only)
						when "10010" => null;	--$A12024 Communication status 2 (read only)
						when "10011" => null;	--$A12026 Communication status 3 (read only)
						when "10100" => null;	--$A12028 Communication status 4 (read only)
						when "10101" => null;	--$A1202A Communication status 5 (read only)
						when "10110" => null;	--$A1202C Communication status 6 (read only)
						when "10111" => null;	--$A1202E Communication status 7 (read only)
						when others => null;
					end case;
				else
					case EXT_VA(5 downto 1) is
						when "00000" =>			--$A12000 BUSREQ,RESET
							M68K_REG_DO <= IEN(2) & "000000" & IFL2 & "000000" & SBRQ & SRES;
						when "00001" =>			--$A12002 Memory mode/Write protect
							M68K_REG_DO(15 downto 2) <= WP & BK & "000" & MODE;
							if MODE = '0' then
								M68K_REG_DO(1 downto 0) <= DMNA0 & RET0;
							else
								M68K_REG_DO(1 downto 0) <= DMNA1 & RET1;
							end if;
						when "00010" =>			--$A12004 CDC mode
							M68K_REG_DO <= EDT & DSR & "000" & DD & x"00";
						when "00011" =>			--$A12006 H-INT vector
							M68K_REG_DO <= HIB;
						when "00100" =>			--$A12008 CDC host data
							M68K_REG_DO <= HD;
							MAIN_CPU_CDC_READ <= '1';
						when "00101" => null;	--$A1200A reserved
						when "00110" =>			--$A1200C Stop watch
							M68K_REG_DO <= "0000" & SW;
						when "00111" =>			--$A1200E Communication flag
							M68K_REG_DO <= CFM & CFS;
						when "01000" =>			--$A12010 Communication command 0
							M68K_REG_DO <= CC(0);
						when "01001" =>			--$A12012 Communication command 1
							M68K_REG_DO <= CC(1);
						when "01010" =>			--$A12014 Communication command 2
							M68K_REG_DO <= CC(2);
						when "01011" =>			--$A12016 Communication command 3
							M68K_REG_DO <= CC(3);
						when "01100" =>			--$A12018 Communication command 4
							M68K_REG_DO <= CC(4);
						when "01101" =>			--$A1201A Communication command 5
							M68K_REG_DO <= CC(5);
						when "01110" =>			--$A1201C Communication command 6
							M68K_REG_DO <= CC(6);
						when "01111" =>			--$A1201E Communication command 7
							M68K_REG_DO <= CC(7);
						when "10000" =>			--$A12020 Communication status 0
							M68K_REG_DO <= CS(0);
						when "10001" =>			--$A12022 Communication status 1
							M68K_REG_DO <= CS(1);
						when "10010" =>			--$A12024 Communication status 2
							M68K_REG_DO <= CS(2);
						when "10011" =>			--$A12026 Communication status 3
							M68K_REG_DO <= CS(3);
						when "10100" =>			--$A12028 Communication status 4
							M68K_REG_DO <= CS(4);
						when "10101" =>			--$A1202A Communication status 5
							M68K_REG_DO <= CS(5);
						when "10110" =>			--$A1202C Communication status 6
							M68K_REG_DO <= CS(6);
						when "10111" =>			--$A1202E Communication status 7
							M68K_REG_DO <= CS(7);
						when others => null;
					end case;
				end if;
				M68K_REG_DTACK_N <= '0';
			elsif M68K_REG_DTACK_N = '0' and EXT_AS_N = '1' then
				M68K_REG_DTACK_N <= '1';
			end if;
		end if;
	end process;
	
	--Genesis BIOS ROM & HINT vector
	M68K_ROM_SEL <= '1' when EXT_ROM_N = '0' and EXT_VA(17) = '0' and (EXT_LDS_N = '0' or EXT_UDS_N = '0') and EXT_ASEL_N = '0' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			ROMS <= ROMS_IDLE;
			M68K_ROM_DTACK_N <= '1';
			ROM_CE_N <= '1';
		elsif rising_edge(CLK) then
			case ROMS is
				when ROMS_IDLE =>
					if M68K_ROM_SEL = '1' and M68K_ROM_DTACK_N = '1' then
						if EXT_RNW = '0' then
							M68K_ROM_DTACK_N <= '0';
							ROMS <= ROMS_END;
						elsif EXT_VA(16 downto 2) = "0"&x"007"&"00" then
							if EXT_VA(1) = '0' then
								M68K_ROM_DO <= x"FFFF";
							else
								M68K_ROM_DO <= HIB;
							end if;
							M68K_ROM_DTACK_N <= '0';
							ROMS <= ROMS_END;
						else
							ROM_CE_N <= '0';
							ROMS <= ROMS_WAIT;
						end if;
					end if;
					
				when ROMS_WAIT =>
					if ROM_RDY = '0' then
						ROMS <= ROMS_ACCESS;
					end if;
				
				when ROMS_ACCESS =>
					if ROM_RDY = '1' then
						M68K_ROM_DO <= ROM_DI;
						M68K_ROM_DTACK_N <= '0';
						
						ROMS <= ROMS_END;
					end if;
					
				when ROMS_END => 
					if M68K_ROM_DTACK_N = '0' and EXT_ASEL_N = '1' then
						M68K_ROM_DTACK_N <= '1';
						ROM_CE_N <= '1';
						ROMS <= ROMS_IDLE;
					end if;
					
				when others => null;
			end case;
		end if;
	end process;
	
	EXT_DTACK_N <= M68K_REG_DTACK_N and M68K_PRGRAM_DTACK_N and M68K_WORDRAM_DTACK_N and M68K_ROM_DTACK_N;
	EXT_VDO <= M68K_REG_DO when M68K_REG_DTACK_N = '0' else
				  M68K_PRGRAM_DO when M68K_PRGRAM_DTACK_N = '0' else
				  M68K_WORDRAM_DO when M68K_WORDRAM_DTACK_N = '0' else
				  M68K_ROM_DO when M68K_ROM_DTACK_N = '0' else
				  M68K_REG_DO;
				  
	
	--S68K GA
	S68K_GA_SEL <= '1' when S68K_A(19 downto 8) = x"F80" and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
	S68K_SC_SEL <= '1' when S68K_A(19 downto 8) = x"F81" and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
				
	process( RST_N, CLK )
	variable NEW_STA : std_logic_vector(6 downto 0);
	begin
		if RST_N = '0' then
			S68K_REG_DTACK_N <= '1';
			S68K_REG_DO <= (others => '0');
			RES0 <= '1';
			LEDG <= '0';
			LEDR <= '0';
--			MODE <= '0';
			PM <= (others => '0');
			CFS <= (others => '0');
			CS <= (others => (others => '0'));
			IEN <= (others => '0');
			DD <= (others => '0');
			DMAA <= (others => '0');
			HOCK <= '0';
			RPT <= '0';
			STS <= '0';
			SMS <= '0';
			GRON <= '0';
			SMBA <= (others => '0');
			VCS <= (others => '0');
			ISA <= (others => '0');
			LN <= (others => '0');
			DOT <= (others => '0');
			HW <= (others => '0');
			VW <= (others => '0');
			TVBA <= (others => '0');
			CDDS <= x"F000000000";
			CDDC <= x"FFFFFFFFFF";
--			STA <= (others => '0');
--			SAOR <= '0';
--			SBA <= (others => (others => '0'));
			SUB_RST_EXEC <= '0';
			DMA_ADDR_SET <= '0';
			VW_SET <= '0';
			TIME_CLK_CNT <= (others => '0');
			TIMER <= (others => '0');
			SUB_CPU_CDC_READ <= '0';
			CDD_SEND <= '0';
			CDD_REC_OLD <= '0';
--			SC_CNT <= (others => '0');
			OLD_CDC_INT_N <= '1';
			HOCK_OLD <= '0';
			SW_CLR <= '0';
			
			INT_PEND(3) <= '0';
			INT_PEND(4) <= '0';
			INT_PEND(5) <= '0';
			INT_PEND(6) <= '0';
			
			CDD_STAT_RECEIVED <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				SUB_RST_EXEC <= '0';
				if MCD_RST_DONE = '1' then
					RES0 <= '1';
				end if;
				
				DMA_ADDR_SET <= '0';
				VW_SET <= '0';
				
				if GS = GS_END then
					GRON <= '0';
				end if;
			
				--CDD Status
				OLD_IEN4 <= IEN(4);
				if INT_ACK(4) = '1' and INT_PEND(4) = '1' then
					INT_PEND(4) <= '0';
--				elsif IEN(4) = '0' and OLD_IEN4 = '1' and INT_PEND(4) = '1' then
--					INT_PEND(4) <= '0';
				end if;
				
				CDD_REC_OLD <= CDD_REC;
				HOCK_OLD <= HOCK;
				if CDD_REC = '1' and CDD_REC_OLD = '0' then
					CDD_STAT_RECEIVED <= '1';
				elsif HOCK = '1' and HOCK_OLD = '0' then
					CDD_STAT_RECEIVED <= '1';
				end if;
				
				if CDD_STAT_RECEIVED = '1' and HOCK = '1' then
					CDDS <= CDD_STAT;
					CDD_STAT_RECEIVED <= '0';
					INT_PEND(4) <= '1';
				end if;
				
				CDD_SEND <= '0';
				
				if SUB_CPU_CDC_READ = '1' and DS = DS_IDLE then
					SUB_CPU_CDC_READ <= '0';
				end if;
				
				if S68K_GA_SEL = '1' and S68K_REG_DTACK_N = '1' then
					if S68K_RNW = '0' then
						case S68K_A(7 downto 1) is
							when "0000000" =>			--$FF8000 Reset
								if S68K_LDS_N = '0' then
									RES0 <= S68K_DI(0);
									SUB_RST_EXEC <= not S68K_DI(0);
								end if;
								if S68K_UDS_N = '0' then
									LEDR <= S68K_DI(8);
									LEDG <= S68K_DI(9);
								end if;
							when "0000001" =>			--$FF8002 Memory mode
	--							if S68K_LDS_N = '0' then
--									MODE <= S68K_DI(2);
									PM <= S68K_DI(4 downto 3);
	--							end if;
							when "0000010" =>			--$FF8004 CDC Mode/CDC register address (extern)
								if S68K_UDS_N = '0' then
									DD <= S68K_DI(10 downto 8);
									DMAA <= (others => '0');
									DMA_ADDR_SET <= '1';
								end if;
							when "0000011" => null;	--$FF8006 CDC register data (extern)
							when "0000100" =>	null;	--$FF8008 CDC host data (read only)
							when "0000101" =>			--$FF800A CDC DMA address
								DMAA(18 downto 3) <= S68K_DI(15 downto 0);
								DMA_ADDR_SET <= '1';
							when "0000110" =>			--$FF800C Stop Watch
								SW_CLR <= '1';
							when "0000111" =>			--$FF800E Communication flag
								CFS <= S68K_DI(7 downto 0);
							when "0001000" => null;	--$FF8010 Communication command 0 (read only)
							when "0001001" => null;	--$FF8012 Communication command 1 (read only)
							when "0001010" => null;	--$FF8014 Communication command 2 (read only)
							when "0001011" => null;	--$FF8016 Communication command 3 (read only)
							when "0001100" => null;	--$FF8018 Communication command 4 (read only)
							when "0001101" => null;	--$FF801A Communication command 5 (read only)
							when "0001110" => null;	--$FF801C Communication command 6 (read only)
							when "0001111" => null;	--$FF801E Communication command 7 (read only)
							when "0010000" =>			--$FF8020 Communication status 0
								if S68K_LDS_N = '0' then
									CS(0)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(0)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010001" =>			--$FF8022 Communication status 1
								if S68K_LDS_N = '0' then
									CS(1)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(1)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010010" =>			--$FF8024 Communication status 2
								if S68K_LDS_N = '0' then
									CS(2)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(2)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010011" =>			--$FF8026 Communication status 3
								if S68K_LDS_N = '0' then
									CS(3)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(3)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010100" =>			--$FF8028 Communication status 4
								if S68K_LDS_N = '0' then
									CS(4)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(4)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010101" =>			--$FF802A Communication status 5
								if S68K_LDS_N = '0' then
									CS(5)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(5)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010110" =>			--$FF802C Communication status 6
								if S68K_LDS_N = '0' then
									CS(6)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(6)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0010111" =>			--$FF802E Communication status 7
								if S68K_LDS_N = '0' then
									CS(7)(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									CS(7)(15 downto 8) <= S68K_DI(15 downto 8);
								end if;
							when "0011000" =>			--$FF8030 Timer
								TM <= S68K_DI(7 downto 0);	
								TIMER_SET <= '1';
							when "0011001" =>			--$FF8032 Inerrupt mask control
								if S68K_LDS_N = '0' then
									IEN <= S68K_DI(6 downto 1);	
								end if;
							when "0011010" => null;	--$FF8034 CD fader
							when "0011011" =>			--$FF8036 CDD control
								if S68K_LDS_N = '0' then
									HOCK <= S68K_DI(2);
								end if;
							when "0011100" => null;	--$FF8038 CDD status 0,1 (read only)
							when "0011101" => null;	--$FF803A CDD status 2,3 (read only)
							when "0011110" => null;	--$FF803C CDD status 4,5 (read only)
							when "0011111" => null;	--$FF803E CDD status 6,7 (read only)
							when "0100000" => null;	--$FF8040 CDD status 8,9 (read only)
							when "0100001" =>			--$FF8042 CDD command 0,1
								if S68K_LDS_N = '0' then
									CDDC(7 downto 4) <= S68K_DI(3 downto 0);	
								end if;
								if S68K_UDS_N = '0' then
									CDDC(3 downto 0) <= S68K_DI(11 downto 8);	
								end if;
							when "0100010" =>			--$FF8044 CDD command 2,3
								if S68K_LDS_N = '0' then
									CDDC(15 downto 12) <= S68K_DI(3 downto 0);	
								end if;
								if S68K_UDS_N = '0' then
									CDDC(11 downto 8) <= S68K_DI(11 downto 8);	
								end if;
							when "0100011" =>			--$FF8046 CDD command 4,5
								if S68K_LDS_N = '0' then
									CDDC(23 downto 20) <= S68K_DI(3 downto 0);	
								end if;
								if S68K_UDS_N = '0' then
									CDDC(19 downto 16) <= S68K_DI(11 downto 8);	
								end if;
							when "0100100" =>			--$FF8048 CDD command 6,7
								if S68K_LDS_N = '0' then
									CDDC(31 downto 28) <= S68K_DI(3 downto 0);	
								end if;
								if S68K_UDS_N = '0' then
									CDDC(27 downto 24) <= S68K_DI(11 downto 8);	
								end if;
							when "0100101" =>			--$FF804A CDD command 8,9
								if S68K_LDS_N = '0' then
									CDDC(39 downto 36) <= S68K_DI(3 downto 0);
									CDD_SEND <= HOCK;
								end if;
								if S68K_UDS_N = '0' then
									CDDC(35 downto 32) <= S68K_DI(11 downto 8);
								end if;
							when "0100110" =>			--$FF804C Font color
								if S68K_LDS_N = '0' then
									SC0 <= S68K_DI(3 downto 0);	
									SC1 <= S68K_DI(7 downto 4);
								end if;
							when "0100111" =>			--$FF804E Font bit
								if S68K_LDS_N = '0' then
									SB(7 downto 0) <= S68K_DI(7 downto 0);	
								end if;
								if S68K_UDS_N = '0' then
									SB(15 downto 8) <= S68K_DI(15 downto 8);	
								end if;
							when "0101000" => null;	--$FF8050 Font data (read only)
							when "0101001" => null;	--$FF8052 Font data (read only)
							when "0101010" => null;	--$FF8054 Font data (read only)
							when "0101011" => null;	--$FF8056 Font data (read only)
							when "0101100" =>			--$FF8058 Stamp data size
								if S68K_LDS_N = '0' then
									RPT <= S68K_DI(0);
									STS <= S68K_DI(1);
									SMS <= S68K_DI(2);
								end if;
							when "0101101" =>			--$FF805A Stamp map base address
								if S68K_LDS_N = '0' then
									SMBA(9 downto 7) <= S68K_DI(7 downto 5);
								end if;
								if S68K_UDS_N = '0' then
									SMBA(17 downto 10) <= S68K_DI(15 downto 8);
								end if;
							when "0101110" =>			--$FF805C Image buffer V cell size
								if S68K_LDS_N = '0' then
									VCS <= S68K_DI(4 downto 0);
								end if;
							when "0101111" =>			--$FF805E Image buffer start address
								if S68K_LDS_N = '0' then
									ISA(9 downto 5) <= S68K_DI(7 downto 3);
								end if;
								if S68K_UDS_N = '0' then
									ISA(17 downto 10) <= S68K_DI(15 downto 8);
								end if;
							when "0110000" =>			--$FF8060 Image buffer offest
								if S68K_LDS_N = '0' then
									DOT <= S68K_DI(2 downto 0);
									LN <= S68K_DI(5 downto 3);
								end if;
							when "0110001" =>			--$FF8062 Image buffer H dot size
								if S68K_LDS_N = '0' then
									HW(7 downto 0) <= S68K_DI(7 downto 0);
								end if;
								if S68K_UDS_N = '0' then
									HW(8) <= S68K_DI(8);
								end if;
							when "0110010" =>			--$FF8064 Image buffer V dot size
								VW <= S68K_DI(7 downto 0);
								VW_SET <= '1';
							when "0110011" =>			--$FF8066 Trace vector base address
								TVBA(17 downto 3) <= S68K_DI(15 downto 1);
								GRON <= '1';
							when "0110100" => null;	--$FF8068 Subcode address (read only)
							when others => null;
						end case;
					else
						case S68K_A(7 downto 1) is
							when "0000000" =>			--$FF8000
								S68K_REG_DO <= "000000" & LEDG & LEDR & VER & "000" & RES0;
							when "0000001" =>			--$FF8002
								S68K_REG_DO(15 downto 2) <= WP & "000" & PM & MODE;
								if MODE = '0' then
									S68K_REG_DO(1 downto 0) <= DMNA0 & RET0;
								else
									S68K_REG_DO(1 downto 0) <= DMNA1 & RET1;
								end if;
							when "0000010" =>			--$FF8004 CDC Mode/CDC register address (extern)
								S68K_REG_DO <= EDT & DSR & "000" & DD & x"00";
							when "0000011" => null;	--$FF8006 CDC register data (extern)
							when "0000100" =>			--$FF8008 CDC host data
								S68K_REG_DO <= HD;
								SUB_CPU_CDC_READ <= '1';
							when "0000101" =>			--$FF800A CDC DMA address
								S68K_REG_DO <= DMA_ADDR(18 downto 3);--DMAA;
							when "0000110" =>			--$FF800C Stop Watch
								S68K_REG_DO <= "0000" & SW;
							when "0000111" =>			--$FF800E Communication flag
								S68K_REG_DO <= CFM & CFS;
							when "0001000" =>			--$FF8010 Communication command 0
								S68K_REG_DO <= CC(0);
							when "0001001" =>			--$FF8012 Communication command 1
								S68K_REG_DO <= CC(1);
							when "0001010" =>			--$FF8014 Communication command 2
								S68K_REG_DO <= CC(2);
							when "0001011" =>			--$FF8016 Communication command 3
								S68K_REG_DO <= CC(3);
							when "0001100" =>			--$FF8018 Communication command 4
								S68K_REG_DO <= CC(4);
							when "0001101" =>			--$FF801A Communication command 5
								S68K_REG_DO <= CC(5);
							when "0001110" =>			--$FF801C Communication command 6
								S68K_REG_DO <= CC(6);
							when "0001111" =>			--$FF801E Communication command 7
								S68K_REG_DO <= CC(7);
							when "0010000" =>			--$FF8020 Communication status 0
								S68K_REG_DO <= CS(0);
							when "0010001" =>			--$FF8022 Communication status 1
								S68K_REG_DO <= CS(1);
							when "0010010" =>			--$FF8024 Communication status 2
								S68K_REG_DO <= CS(2);
							when "0010011" =>			--$FF8026 Communication status 3
								S68K_REG_DO <= CS(3);
							when "0010100" =>			--$FF8028 Communication status 4
								S68K_REG_DO <= CS(4);
							when "0010101" =>			--$FF802A Communication status 5
								S68K_REG_DO <= CS(5);
							when "0010110" =>			--$FF802C Communication status 6
								S68K_REG_DO <= CS(6);
							when "0010111" =>			--$FF802E Communication status 7
								S68K_REG_DO <= CS(7);
							when "0011000" =>			--$FF8030 Timer
								S68K_REG_DO <= x"00" & TM;	
							when "0011001" =>			--$FF8032 Inerrupt mask control
								S68K_REG_DO <= x"00" & "0" & IEN & "0";	
							when "0011010" =>			--$FF8034 CD fader
								S68K_REG_DO <= x"0000";	---------------------------------------------------
							when "0011011" =>			--$FF8036 CDD control
								S68K_REG_DO <= "0000000" & CDD_DM & "00000" & HOCK & "00";
							when "0011100" =>			--$FF8038 CDD status 0,1
								S68K_REG_DO <= x"0" & CDDS(3 downto 0) & x"0" & CDDS(7 downto 4);
							when "0011101" =>			--$FF803A CDD status 2,3
								S68K_REG_DO <= x"0" & CDDS(11 downto 8) & x"0" & CDDS(15 downto 12);
							when "0011110" =>			--$FF803C CDD status 4,5
								S68K_REG_DO <= x"0" & CDDS(19 downto 16) & x"0" & CDDS(23 downto 20);
							when "0011111" =>			--$FF803E CDD status 6,7
								S68K_REG_DO <= x"0" & CDDS(27 downto 24) & x"0" & CDDS(31 downto 28);
							when "0100000" =>			--$FF8040 CDD status 8,9
								S68K_REG_DO <= x"0" & CDDS(35 downto 32) & x"0" & CDDS(39 downto 36);
							when "0100001" =>			--$FF8042 CDD command 0,1
								S68K_REG_DO <= x"0" & CDDC(3 downto 0) & x"0" & CDDC(7 downto 4);
							when "0100010" =>			--$FF8044 CDD command 2,3
								S68K_REG_DO <= x"0" & CDDC(11 downto 8) & x"0" & CDDC(15 downto 12);
							when "0100011" =>			--$FF8046 CDD command 4,5
								S68K_REG_DO <= x"0" & CDDC(19 downto 16) & x"0" & CDDC(23 downto 20);
							when "0100100" =>			--$FF8048 CDD command 6,7
								S68K_REG_DO <= x"0" & CDDC(27 downto 24) & x"0" & CDDC(31 downto 28);
							when "0100101" =>			--$FF804A CDD command 8,9
								S68K_REG_DO <= x"0" & CDDC(35 downto 32) & x"0" & CDDC(39 downto 36);
							when "0100110" =>			--$FF804C Font color
								S68K_REG_DO <= x"00" & SC1 & SC0;	
							when "0100111" =>			--$FF804E Font bit
								S68K_REG_DO <= SB;	
							when "0101000" =>			--$FF8050 Font data
								S68K_REG_DO <= GetFontData(SB, SC0, SC1, 0);
							when "0101001" =>			--$FF8052 Font data
								S68K_REG_DO <= GetFontData(SB, SC0, SC1, 1);
							when "0101010" =>			--$FF8054 Font data
								S68K_REG_DO <= GetFontData(SB, SC0, SC1, 2);
							when "0101011" =>			--$FF8056 Font data
								S68K_REG_DO <= GetFontData(SB, SC0, SC1, 3);
							when "0101100" =>			--$FF8058 Stamp data size
								S68K_REG_DO <= GRON & "000000000000" & SMS & STS & RPT;	
							when "0101101" =>			--$FF805A Stamp map base address
								S68K_REG_DO <= SMBA & "00000";
							when "0101110" =>			--$FF805C Image buffer V cell size
								S68K_REG_DO <= "00000000000" & VCS;
							when "0101111" =>			--$FF805E Image buffer start address
								S68K_REG_DO <= ISA & "000";
							when "0110000" =>			--$FF8060 Image buffer offest
								S68K_REG_DO <= "0000000000" & LN & DOT;
							when "0110001" =>			--$FF8062 Image buffer H dot size
								S68K_REG_DO <= "0000000" & HW;
							when "0110010" =>			--$FF8064 Image buffer V dot size
								S68K_REG_DO <= "00000000" & VDOTS;
							when "0110011" =>			--$FF8066 Trace vector base address
								S68K_REG_DO <= TVBA(17 downto 3) & "0";
							when "0110100" =>			--$FF8068 Subcode address
								S68K_REG_DO <= (others => '0');
--								S68K_REG_DO <= "00000000" & SAOR & STA & "0";
							when others =>
								S68K_REG_DO <= S68K_MDR;
						end case;
					end if;
					S68K_REG_DTACK_N <= '0';
				elsif S68K_REG_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
					S68K_REG_DTACK_N <= '1';
				end if;
			
				--Subcode
--				if (INT_ACK(6) = '1' or IEN(6) = '0') and INT_PEND(6) = '1' then
--					INT_PEND(6) <= '0';
--				end if;
--				
--				CD_SC_WR_OLD <= CD_SC_WR;
--				if CD_SC_WR = '1' and CD_SC_WR_OLD = '0' then
--					NEW_STA := std_logic_vector( (SAOR&unsigned(STA)) + 49 );
--					
--					SBA(to_integer(unsigned(NEW_STA(5 downto 0)) + SC_CNT)) <= CD_DI(7 downto 0)&CD_DI(15 downto 8);
--					SC_CNT <= SC_CNT + 1;
--					if SC_CNT = 48 then
--						SC_CNT <= (others => '0');
--						
--						STA <= NEW_STA(5 downto 0);
--						SAOR <= NEW_STA(6);
--						
--						if IEN(6) = '1' then
--							INT_PEND(6) <= '1';
--						end if;
--					end if;
--				end if;
			
				if S68K_SC_SEL = '1' and S68K_REG_DTACK_N = '1' then-- and PCM_S68K_HALT = '0'
					if S68K_RNW = '1' then
						S68K_REG_DO <= (others => '0');
--						S68K_REG_DO <= SBA(to_integer(unsigned(S68K_A(6 downto 1))));
					end if;
					S68K_REG_DTACK_N <= '0';
				elsif S68K_REG_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
					S68K_REG_DTACK_N <= '1';
				end if;
				
				--Timer
				if (INT_ACK(3) = '1' or IEN(3) = '0') and INT_PEND(3) = '1' then
					INT_PEND(3) <= '0';
				end if;
				
				if CLK_12M_F = '1' then
					TIME_CLK_CNT <= TIME_CLK_CNT + 1;
					if TIME_CLK_CNT = "110011100" then
						TIME_CLK_CNT <= (others => '0');
						
						if SW_CLR = '1' then
							SW <= (others => '0');
							SW_CLR <= '0';
						else
							SW <= std_logic_vector( unsigned(SW) + 1 );
						end if;
						
						if TIMER_SET = '1' then
							TIMER <= unsigned(TM);
							TIMER_SET <= '0';
						elsif TIMER /= x"00" then
							TIMER <= TIMER - 1;
							if TIMER = 1 and IEN(3) = '1' and INT_PEND(3) = '0' then
								INT_PEND(3) <= '1';
							end if;
						else
							TIMER <= unsigned(TM);
						end if;
					end if;
				end if;
			
				--CDC interrupt
				if CLK_12M_F = '1' then
					OLD_CDC_INT_N <= CDC_INT_N;
					OLD_IEN5 <= IEN(5);
					if INT_ACK(5) = '1' and INT_PEND(5) = '1' then
						INT_PEND(5) <= '0';
					elsif CDC_INT_N = '0' and OLD_CDC_INT_N = '1' and INT_PEND(5) = '0' then
						INT_PEND(5) <= '1';
					elsif CDC_INT_N = '1' and OLD_CDC_INT_N = '0' and INT_PEND(5) = '1' then
						INT_PEND(5) <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	CDD_COMM <= CDDC;

	LED_RED <= LEDR;
	LED_GREEN <= LEDG;
	
	
	
	--PRG-RAM
	S68K_PRG_RAM_SEL <= '1' when S68K_A(19) = '0' and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
	M68K_PRG_RAM_SEL <= '1' when EXT_ROM_N = '0' and EXT_VA(17) = '1' and (EXT_LDS_N = '0' or EXT_UDS_N = '0') and EXT_ASEL_N = '0' else '0';
	DMA_PRG_RAM_SEL <= '1' when DD = "101" and DS = DS_WRITE else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			PRMS <= PRS_IDLE;
			PRSS <= PRS_IDLE;
			PRG_RAM_DO <= (others => '0');
			PRG_RAM_WRL <= '0';
			PRG_RAM_WRH <= '0';
			PRG_RAM_RD <= '0';
			M68K_PRGRAM_DTACK_N <= '1';
			S68K_PRGRAM_DTACK_N <= '1';
			PR_DMA_RUN <= '0';
			PRG_RAM_RFS <= '0';
			RFS_PRGRAM_DTACK_N <= '1';
			PRG_RAM_RFS_TIMER <= (others => '0');
			PRG_RAM_RFS_SCHED <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				PRG_RAM_RFS_TIMER <= PRG_RAM_RFS_TIMER + 1;
				if PRG_RAM_RFS_TIMER = "0101111111" then		-- ~15us
					PRG_RAM_RFS_TIMER <= (others => '0');
					PRG_RAM_RFS_SCHED <= '1';
				end if;
				
				case PRMS is
					when PRS_IDLE =>
						if SBRQ = '0' and SRES = '1' then
							if M68K_PRG_RAM_SEL = '1' and M68K_PRGRAM_DTACK_N = '1' then
								M68K_PRGRAM_DTACK_N <= '0';
								PRMS <= PRS_END;
							end if;
						else
--							if PRG_RAM_RFS_SCHED = '1' then
--								PRG_RAM_RFS <= '1';
--								PRMS <= PRS_REFRESH_WAIT;
--							els
							if M68K_PRG_RAM_SEL = '1' and M68K_PRGRAM_DTACK_N = '1' then
								PRG_RAM_ADDR <= BK & EXT_VA(16 downto 1);
								PRG_RAM_DO <= EXT_VDI;
								PRG_RAM_WRL <= not EXT_LDS_N and not EXT_RNW;
								PRG_RAM_WRH <= not EXT_UDS_N and not EXT_RNW;
								PRG_RAM_RD <= EXT_RNW;
								PRMS <= PRS_WAIT;
							elsif (EXT_LDS_N = '0' or EXT_UDS_N = '0') and EXT_ASEL_N = '0' and RFS_PRGRAM_DTACK_N = '1' then
								PRG_RAM_RFS <= '1';
								RFS_PRGRAM_DTACK_N <= '0';
								PRMS <= PRS_REFRESH_WAIT;
								PRG_RAM_RFS_TIMER <= (others => '0');
							end if;
						end if;
						
					when PRS_WAIT =>
						if PRG_RDY = '0' then
							if PRG_RAM_RD = '1' then
								PRMS <= PRS_READ;
							else
								PRMS <= PRS_WRITE;
							end if;
						end if;
					
					when PRS_READ =>
						if PRG_RDY = '1' then
							PRG_RAM_RD <= '0';
							
							M68K_PRGRAM_DO <= PRG_DI;
							M68K_PRGRAM_DTACK_N <= '0';
							PRMS <= PRS_END;
						end if;
					
					when PRS_WRITE =>
						PRG_RAM_WRL <= '0';
						PRG_RAM_WRH <= '0';
						
						M68K_PRGRAM_DTACK_N <= '0';
						PRMS <= PRS_END;
					
					when PRS_REFRESH_WAIT =>
						if PRG_RDY = '0' then
							PRMS <= PRS_REFRESH;
						end if;
						
					when PRS_REFRESH =>
						if PRG_RDY = '1' then
							PRG_RAM_RFS <= '0';
							PRMS <= PRS_REFRESH_END;
						end if;
						
					when PRS_END => 
						if M68K_PRGRAM_DTACK_N = '0' and EXT_ASEL_N = '1' then
							M68K_PRGRAM_DTACK_N <= '1';
							PRMS <= PRS_IDLE;
						end if;
						
					when PRS_REFRESH_END => 
						if RFS_PRGRAM_DTACK_N = '0' and EXT_ASEL_N = '1' then
							RFS_PRGRAM_DTACK_N <= '1';
							PRMS <= PRS_IDLE;
--						elsif PRG_RAM_RFS_SCHED = '1' then
--							PRG_RAM_RFS_SCHED <= '0';
--							PRMS <= PRS_IDLE;
						end if;
						
					when others => null;
				end case;
				
				case PRSS is
					when PRS_IDLE =>
						if PRG_RAM_RFS_SCHED = '1' and SBRQ = '0' and SRES = '1' and HS = HS_EXEC then
							PRG_RAM_RFS <= '1';
							PRSS <= PRS_REFRESH_WAIT;
						elsif DMA_PRG_RAM_SEL = '1' and SBRQ = '0' and SRES = '1' then
							PRG_RAM_ADDR <= DMA_ADDR;
							PRG_RAM_DO <= DMA_DAT;
							if DMA_ADDR(18 downto 9) >= "00"&WP then
								PRG_RAM_WRL <= '1';
								PRG_RAM_WRH <= '1';
								PRG_RAM_RD <= '0';
								PRSS <= PRS_DMA_WAIT;
							else
								PRG_RAM_WRL <= '0';
								PRG_RAM_WRH <= '0';
								PRG_RAM_RD <= '0';
								PRSS <= PRS_END;
							end if;
							PR_DMA_RUN <= '1';
						elsif S68K_PRG_RAM_SEL = '1' and S68K_PRGRAM_DTACK_N = '1' then
							PRG_RAM_ADDR <= S68K_A(18 downto 1);
							PRG_RAM_DO <= S68K_DI;
							if S68K_RNW = '1' or S68K_A(18 downto 9) >= "00"&WP then
								PRG_RAM_WRL <= not S68K_LDS_N and not S68K_RNW;
								PRG_RAM_WRH <= not S68K_UDS_N and not S68K_RNW;
								PRG_RAM_RD <= S68K_RNW;
								PRSS <= PRS_WAIT;
							else 
								PRG_RAM_WRL <= '0';
								PRG_RAM_WRH <= '0';
								PRG_RAM_RD <= '0';
								S68K_PRGRAM_DTACK_N <= '0';
								PRSS <= PRS_END;
							end if;
						elsif (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' and RFS_PRGRAM_DTACK_N = '1' then
							PRG_RAM_RFS <= '1';
							RFS_PRGRAM_DTACK_N <= '0';
							PRSS <= PRS_REFRESH_WAIT;
							PRG_RAM_RFS_TIMER <= (others => '0');
						end if;
					
					when PRS_WAIT =>
						if PRG_RDY = '0' then
							if PRG_RAM_RD = '1' then
								PRSS <= PRS_READ;
							else
								PRSS <= PRS_WRITE;
							end if;
						end if;
						
					when PRS_READ =>
						if PRG_RDY = '1' then
							PRG_RAM_RD <= '0';
	
							S68K_PRGRAM_DO <= PRG_DI;
							S68K_PRGRAM_DTACK_N <= '0';
							
							PRSS <= PRS_END;
						end if;
					
					when PRS_WRITE =>
						PRG_RAM_WRL <= '0';
						PRG_RAM_WRH <= '0';

						S68K_PRGRAM_DTACK_N <= '0';
						
						PRSS <= PRS_END;
						
					when PRS_DMA_WAIT =>
						if PRG_RDY = '0' then
							PRSS <= PRS_DMA_WRITE;
						end if;
						
					when PRS_DMA_WRITE =>
						if PRG_RDY = '1' then
							PRSS <= PRS_DMA_END;
	
							PRG_RAM_WRL <= '0';
							PRG_RAM_WRH <= '0';
						end if;
						
					when PRS_REFRESH_WAIT =>
						if PRG_RDY = '0' then
							PRSS <= PRS_REFRESH;
						end if;
						
					when PRS_REFRESH =>
						if PRG_RDY = '1' then
							PRG_RAM_RFS <= '0';
							PRSS <= PRS_REFRESH_END;
						end if;
						
					when PRS_END => 
						if S68K_PRGRAM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
							S68K_PRGRAM_DTACK_N <= '1';
							PRSS <= PRS_IDLE;
						end if;
						
					when PRS_DMA_END => 
						if PR_DMA_RUN = '1' then
							PR_DMA_RUN <= '0';
							PRSS <= PRS_IDLE;
						end if;
						
					when PRS_REFRESH_END => 
						if RFS_PRGRAM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
							RFS_PRGRAM_DTACK_N <= '1';
							PRSS <= PRS_IDLE;
						elsif PRG_RAM_RFS_SCHED = '1' then
							PRG_RAM_RFS_SCHED <= '0';
							PRSS <= PRS_IDLE;
						end if;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	PRAM_N <= '0' when PRMS /= PRS_IDLE or PRSS /= PRS_IDLE else '1';	
	PRG_A <= PRG_RAM_ADDR;
	PRG_DO <= PRG_RAM_DO;
	PRG_WRL_N <= not PRG_RAM_WRL;
	PRG_WRH_N <= not PRG_RAM_WRH;
	PRG_OE_N <= not PRG_RAM_RD;
	PRG_RFS <= PRG_RAM_RFS;
	
	
	--WORD-RAM
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			WR0S <= WRS_IDLE;
			WORD_RAM_1M0_DI <= (others => '0');
			WORD_RAM_1M0_WR <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				case WR0S is
					when WRS_IDLE =>
						if WR0R.EXEC = '1' then
							WR0S <= WRS_READ;
						end if;
						
					when WRS_READ =>
						case WR0R.DOT_IMAGE is
							when "11" =>   WORD_RAM_1M0_DI <= x"0" & WORDRAM0_DI( 7 downto  4) & x"0" & WORDRAM0_DI( 3 downto 0);
							when "10" =>   WORD_RAM_1M0_DI <= x"0" & WORDRAM0_DI(15 downto 12) & x"0" & WORDRAM0_DI(11 downto 8);
							when others => WORD_RAM_1M0_DI <= WORDRAM0_DI;
						end case;
						
						if WR0R.RNW(0) = '0' then
							WORD_RAM_1M0_DO(3 downto 0) <= GetWriteColor(WR0R.DO( 3 downto 0), WORDRAM0_DI( 3 downto  0), WR0R.PM);
						else
							WORD_RAM_1M0_DO(3 downto 0) <= WORDRAM0_DI(3 downto 0);
						end if;
						if WR0R.RNW(1) = '0' then
							WORD_RAM_1M0_DO(7 downto 4) <= GetWriteColor(WR0R.DO(7 downto 4), WORDRAM0_DI(7 downto 4), WR0R.PM);
						else
							WORD_RAM_1M0_DO(7 downto 4) <= WORDRAM0_DI(7 downto 4);
						end if;
						if WR0R.RNW(2) = '0' then
							WORD_RAM_1M0_DO(11 downto 8) <= GetWriteColor(WR0R.DO(11 downto 8), WORDRAM0_DI(11 downto 8), WR0R.PM);
						else
							WORD_RAM_1M0_DO(11 downto 8) <= WORDRAM0_DI(11 downto 8);
						end if;
						if WR0R.RNW(3) = '0' then
							WORD_RAM_1M0_DO(15 downto 12) <= GetWriteColor(WR0R.DO(15 downto 12), WORDRAM0_DI(15 downto 12), WR0R.PM);
						else
							WORD_RAM_1M0_DO(15 downto 12) <= WORDRAM0_DI(15 downto 12);
						end if;
						WORD_RAM_1M0_WR <= '1';
						
						WR0S <= WRS_WRITE;
					
					when WRS_WRITE =>
						WORD_RAM_1M0_WR <= '0';
						WR0S <= WRS_END;
					
					when WRS_END =>
						if WR0R.EXEC = '0' then
							WR0S <= WRS_IDLE;
						end if;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			WR1S <= WRS_IDLE;
			WORD_RAM_1M1_DI <= (others => '0');
			WORD_RAM_1M1_WR <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				case WR1S is
					when WRS_IDLE =>
						if WR1R.EXEC = '1' then
							WR1S <= WRS_READ;
						end if;
					
					when WRS_READ =>
						case WR1R.DOT_IMAGE is
							when "11" =>   WORD_RAM_1M1_DI <= x"0" & WORDRAM1_DI( 7 downto  4) & x"0" & WORDRAM1_DI( 3 downto 0);
							when "10" =>   WORD_RAM_1M1_DI <= x"0" & WORDRAM1_DI(15 downto 12) & x"0" & WORDRAM1_DI(11 downto 8);
							when others => WORD_RAM_1M1_DI <= WORDRAM1_DI;
						end case;
						
						if WR1R.RNW(0) = '0' then
							WORD_RAM_1M1_DO(3 downto 0) <= GetWriteColor(WR1R.DO(3 downto 0), WORDRAM1_DI(3 downto  0), WR1R.PM);
						else
							WORD_RAM_1M1_DO(3 downto 0) <= WORDRAM1_DI(3 downto 0);
						end if;
						if WR1R.RNW(1) = '0' then
							WORD_RAM_1M1_DO(7 downto 4) <= GetWriteColor(WR1R.DO(7 downto 4), WORDRAM1_DI(7 downto 4), WR1R.PM);
						else
							WORD_RAM_1M1_DO(7 downto 4) <= WORDRAM1_DI(7 downto 4);
						end if;
						if WR1R.RNW(2) = '0' then
							WORD_RAM_1M1_DO(11 downto 8) <= GetWriteColor(WR1R.DO(11 downto 8), WORDRAM1_DI(11 downto 8), WR1R.PM);
						else
							WORD_RAM_1M1_DO(11 downto 8) <= WORDRAM1_DI(11 downto 8);
						end if;
						if WR1R.RNW(3) = '0' then
							WORD_RAM_1M1_DO(15 downto 12) <= GetWriteColor(WR1R.DO(15 downto 12), WORDRAM1_DI(15 downto 12), WR1R.PM);
						else
							WORD_RAM_1M1_DO(15 downto 12) <= WORDRAM1_DI(15 downto 12);
						end if;
						WORD_RAM_1M1_WR <= '1';
						
						WR1S <= WRS_WRITE;
					
					when WRS_WRITE =>
						WORD_RAM_1M1_WR <= '0';
						WR1S <= WRS_END;
					
					when WRS_END =>
						if WR1R.EXEC = '0' then
							WR1S <= WRS_IDLE;
						end if;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	
	M68K_WORD_RAM_SEL <= '1' when EXT_RAS2_N = '0' and (EXT_LDS_N = '0' or EXT_UDS_N = '0') and EXT_ASEL_N = '0' else '0';
	S68K_WORD_RAM_SEL <= '1' when S68K_A(19 downto 16) >= x"8" and S68K_A(19 downto 16) <= x"D" and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
	DMA_WORD_RAM_SEL <= '1' when DD = "111" and DS = DS_WRITE else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			M68K_WORDRAM_DTACK_N <= '1';
			S68K_WORDRAM_DTACK_N <= '1';
			WR0R <= ((others => '0'),(others => '0'),"1111",'0',"00","00");
			WR1R <= ((others => '0'),(others => '0'),"1111",'0',"00","00");
			WR_DMA_RUN <= '0';
			WR0A <= WRA_IDLE;
			WR1A <= WRA_IDLE;
		elsif rising_edge(CLK) then
			if EN = '1' then
				case WR0A is
					when WRA_IDLE =>
						WR0R.DOT_IMAGE <= (others => '0');
						if MODE = '1' then	--1M MODE
							if RET1 = '0' then 
								if M68K_WORD_RAM_SEL = '1' and M68K_WORDRAM_DTACK_N = '1' then
									WR0R.A <= EXT_VA(16 downto 1);
									WR0R.DO <= EXT_VDI;
									WR0R.RNW <= (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_LDS_N) & (EXT_RNW or EXT_LDS_N);
									WR0R.PM <= "00";
									WR0R.EXEC <= '1';
									WR0A <= WRA_M68K_ACCESS;
								end if;
							else
								if DMA_WORD_RAM_SEL = '1' then
									WR0R.A <= DMA_ADDR(16 downto 1);
									WR0R.DO <= DMA_DAT;
									WR0R.RNW <= "0000";
									WR0R.PM <= "00";
									WR0R.EXEC <= '1';
									WR0A <= WRA_DMA_ACCESS;
									WR_DMA_RUN <= '1';
								elsif S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 17) = "110" and S68K_WORDRAM_DTACK_N = '1' then
									WR0R.A <= S68K_A(16 downto 1);
									WR0R.DO <= S68K_DI;
									WR0R.RNW <= (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_LDS_N) & (S68K_RNW or S68K_LDS_N);
									WR0R.PM <= "00";
									WR0R.EXEC <= '1';
									WR0A <= WRA_S68K_ACCESS;
									S68K_WORDRAM_DTACK_N <= '0';
								elsif S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 18) = "10" and S68K_WORDRAM_DTACK_N = '1' then
									WR0R.A <= S68K_A(17 downto 2);
									WR0R.DO <= S68K_DI(11 downto 8) & S68K_DI(3 downto 0) & S68K_DI(11 downto 8) & S68K_DI(3 downto 0);
									WR0R.RNW(0) <= S68K_RNW or S68K_LDS_N or not S68K_A(1);
									WR0R.RNW(1) <= S68K_RNW or S68K_UDS_N or not S68K_A(1);
									WR0R.RNW(2) <= S68K_RNW or S68K_LDS_N or     S68K_A(1);
									WR0R.RNW(3) <= S68K_RNW or S68K_UDS_N or     S68K_A(1);
									WR0R.PM <= PM;
									WR0R.DOT_IMAGE <= "1" & S68K_A(1);
									WR0R.EXEC <= '1';
									WR0A <= WRA_S68K_ACCESS;
									S68K_WORDRAM_DTACK_N <= '0';
								end if;
							end if;
						else						--2M MODE
							if M68K_WORD_RAM_SEL = '1' and EXT_VA(1) = '0' and M68K_WORDRAM_DTACK_N = '1' then
								if RET0 = '0' then
									M68K_WORDRAM_DTACK_N <= '0';
									WR0A <= WRA_M68K_END;
								else
									WR0R.A <= EXT_VA(17 downto 2);
									WR0R.DO <= EXT_VDI;
									WR0R.RNW <= (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_LDS_N) & (EXT_RNW or EXT_LDS_N);
									WR0R.PM <= "00";
									WR0R.EXEC <= '1';
									WR0A <= WRA_M68K_ACCESS;
								end if;
							elsif RET0 = '0' and DMA_WORD_RAM_SEL = '1' and DMA_ADDR(1) = '0' then
								WR0R.A <= DMA_ADDR(17 downto 2);
								WR0R.DO <= DMA_DAT;
								WR0R.RNW <= "0000";
								WR0R.PM <= "00";
								WR0R.EXEC <= '1';
								WR0A <= WRA_DMA_ACCESS;
								WR_DMA_RUN <= '1';
							elsif RET0 = '0' and GFX_SEL = '1' and GFX_ADDR(1) = '0' then
								WR0R.A <= GFX_ADDR(17 downto 2);
								WR0R.DO <= GFX_DO;
								WR0R.RNW <= not (GFX_RMW&GFX_RMW&GFX_RMW&GFX_RMW);
								WR0R.PM <= PM and (GFX_RMW&GFX_RMW);
								WR0R.EXEC <= '1';
								WR0A <= WRA_GFX_ACCESS;
								WR_GFX_RUN <= '1';
							elsif RET0 = '0' and S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 18) = "10" and S68K_A(1) = '0' and S68K_WORDRAM_DTACK_N = '1' then
								WR0R.A <= S68K_A(17 downto 2);
								WR0R.DO <= S68K_DI;
								WR0R.RNW <= (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_LDS_N) & (S68K_RNW or S68K_LDS_N);
								WR0R.PM <= "00";
								WR0R.EXEC <= '1';
								WR0A <= WRA_S68K_ACCESS;
								S68K_WORDRAM_DTACK_N <= '0';
							end if;
						end if;
					
					when WRA_M68K_ACCESS =>
						if WR0S = WRS_END then
							WR0R.EXEC <= '0';
							LAST_M68K_WORDRAM_DO <= WORD_RAM_1M0_DI;
							if EXT_AS_N = '0' then
								M68K_WORDRAM_DO <= WORD_RAM_1M0_DI;
							else
								M68K_WORDRAM_DO <= LAST_M68K_WORDRAM_DO;
							end if;
							M68K_WORDRAM_DTACK_N <= '0';
							WR0A <= WRA_M68K_END;
						end if;
					
					when WRA_S68K_ACCESS =>
						if WR0S = WRS_END then
							WR0R.EXEC <= '0';
							S68K_WORDRAM_DO <= WORD_RAM_1M0_DI;
								
							WR0A <= WRA_S68K_END;
						end if;
					
					when WRA_DMA_ACCESS =>
						if WR0S = WRS_END then
							WR0R.EXEC <= '0';
								
							WR0A <= WRA_DMA_END;
						end if;
						
					when WRA_GFX_ACCESS =>
						if WR0S = WRS_END then
							WR0R.EXEC <= '0';
							GFX_WORDRAM_DO <= WORD_RAM_1M0_DI;
								
							WR0A <= WRA_GFX_END;
						end if;
	
					when WRA_M68K_END => 
						if M68K_WORDRAM_DTACK_N = '0' and EXT_ASEL_N = '1' then
							M68K_WORDRAM_DTACK_N <= '1';
							WR0A <= WRA_IDLE;
						end if;
					
					when WRA_S68K_END => 
						if S68K_WORDRAM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
							S68K_WORDRAM_DTACK_N <= '1';
							WR0A <= WRA_IDLE;
						end if;
						
					when WRA_DMA_END => 
						if WR_DMA_RUN = '1' then
							WR_DMA_RUN <= '0';
							WR0A <= WRA_IDLE;
						end if;
						
					when WRA_GFX_END => 
						if WR_GFX_RUN = '1' then
							WR_GFX_RUN <= '0';
							WR0A <= WRA_IDLE;
						end if;
						
					when others => null;
				end case;
				
				case WR1A is
					when WRA_IDLE =>
						WR1R.DOT_IMAGE <= (others => '0');
						if MODE = '1' then	--1M MODE
							if RET1 = '1' then 
								if M68K_WORD_RAM_SEL = '1' and M68K_WORDRAM_DTACK_N = '1' then
									WR1R.A <= EXT_VA(16 downto 1);
									WR1R.DO <= EXT_VDI;
									WR1R.RNW <= (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_LDS_N) & (EXT_RNW or EXT_LDS_N);
									WR1R.PM <= "00";
									WR1R.EXEC <= '1';
									WR1A <= WRA_M68K_ACCESS;
								end if;
							else
								if DMA_WORD_RAM_SEL = '1' then
									WR1R.A <= DMA_ADDR(16 downto 1);
									WR1R.DO <= DMA_DAT;
									WR1R.RNW <= "0000";
									WR1R.PM <= "00";
									WR1R.EXEC <= '1';
									WR1A <= WRA_DMA_ACCESS;
									WR_DMA_RUN <= '1';
								elsif S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 17) = "110" and S68K_WORDRAM_DTACK_N = '1' then
									WR1R.A <= S68K_A(16 downto 1);
									WR1R.DO <= S68K_DI;
									WR1R.RNW <= (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_LDS_N) & (S68K_RNW or S68K_LDS_N);
									WR1R.PM <= "00";
									WR1R.EXEC <= '1';
									WR1A <= WRA_S68K_ACCESS;
									S68K_WORDRAM_DTACK_N <= '0';
								elsif S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 18) = "10" and S68K_WORDRAM_DTACK_N = '1' then
									WR1R.A <= S68K_A(17 downto 2);
									WR1R.DO <= S68K_DI(11 downto 8) & S68K_DI(3 downto 0) & S68K_DI(11 downto 8) & S68K_DI(3 downto 0);
									WR1R.RNW(0) <= S68K_RNW or S68K_LDS_N or not S68K_A(1);
									WR1R.RNW(1) <= S68K_RNW or S68K_UDS_N or not S68K_A(1);
									WR1R.RNW(2) <= S68K_RNW or S68K_LDS_N or     S68K_A(1);
									WR1R.RNW(3) <= S68K_RNW or S68K_UDS_N or     S68K_A(1);
									WR1R.PM <= PM;
									WR1R.DOT_IMAGE <= "1" & S68K_A(1);
									WR1R.EXEC <= '1';
									WR1A <= WRA_S68K_ACCESS;
									S68K_WORDRAM_DTACK_N <= '0';
								end if;
							end if;
						else						--2M MODE
							if M68K_WORD_RAM_SEL = '1' and EXT_VA(1) = '1' and M68K_WORDRAM_DTACK_N = '1' then
								if RET0 = '0' then
									M68K_WORDRAM_DTACK_N <= '0';
									WR1A <= WRA_M68K_END;
								else
									WR1R.A <= EXT_VA(17 downto 2);
									WR1R.DO <= EXT_VDI;
									WR1R.RNW <= (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_UDS_N) & (EXT_RNW or EXT_LDS_N) & (EXT_RNW or EXT_LDS_N);
									WR1R.PM <= "00";
									WR1R.EXEC <= '1';
									WR1A <= WRA_M68K_ACCESS;
								end if;
							elsif RET0 = '0' and DMA_WORD_RAM_SEL = '1' and DMA_ADDR(1) = '1' then
								WR1R.A <= DMA_ADDR(17 downto 2);
								WR1R.DO <= DMA_DAT;
								WR1R.RNW <= "0000";
								WR1R.PM <= "00";
								WR1R.EXEC <= '1';
								WR1A <= WRA_DMA_ACCESS;
								WR_DMA_RUN <= '1';
							elsif RET0 = '0' and GFX_SEL = '1' and GFX_ADDR(1) = '1' then
								WR1R.A <= GFX_ADDR(17 downto 2);
								WR1R.DO <= GFX_DO;
								WR1R.RNW <= not (GFX_RMW&GFX_RMW&GFX_RMW&GFX_RMW);
								WR1R.PM <= PM and (GFX_RMW&GFX_RMW);
								WR1R.EXEC <= '1';
								WR1A <= WRA_GFX_ACCESS;
								WR_GFX_RUN <= '1';
							elsif RET0 = '0' and S68K_WORD_RAM_SEL = '1' and S68K_A(19 downto 18) = "10" and S68K_A(1) = '1' and S68K_WORDRAM_DTACK_N = '1' then
								WR1R.A <= S68K_A(17 downto 2);
								WR1R.DO <= S68K_DI;
								WR1R.RNW <= (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_UDS_N) & (S68K_RNW or S68K_LDS_N) & (S68K_RNW or S68K_LDS_N);
								WR1R.PM <= "00";
								WR1R.EXEC <= '1';
								WR1A <= WRA_S68K_ACCESS;
								S68K_WORDRAM_DTACK_N <= '0';
							end if;
						end if;
						
					when WRA_M68K_ACCESS =>
						if WR1S = WRS_END then
							WR1R.EXEC <= '0';
							LAST_M68K_WORDRAM_DO <= WORD_RAM_1M1_DI;
							if EXT_AS_N = '0' then
								M68K_WORDRAM_DO <= WORD_RAM_1M1_DI;
							else
								M68K_WORDRAM_DO <= LAST_M68K_WORDRAM_DO;
							end if;
							M68K_WORDRAM_DTACK_N <= '0';
							WR1A <= WRA_M68K_END;
						end if;
					
					when WRA_S68K_ACCESS =>
						if WR1S = WRS_END then
							WR1R.EXEC <= '0';
							S68K_WORDRAM_DO <= WORD_RAM_1M1_DI;
								
							WR1A <= WRA_S68K_END;
						end if;
					
					when WRA_DMA_ACCESS =>
						if WR1S = WRS_END then
							WR1R.EXEC <= '0';
								
							WR1A <= WRA_DMA_END;
						end if;
						
					when WRA_GFX_ACCESS =>
						if WR1S = WRS_END then
							WR1R.EXEC <= '0';
							GFX_WORDRAM_DO <= WORD_RAM_1M1_DI;
								
							WR1A <= WRA_GFX_END;
						end if;
						
					when WRA_M68K_END => 
						if M68K_WORDRAM_DTACK_N = '0' and EXT_ASEL_N = '1' then
							M68K_WORDRAM_DTACK_N <= '1';
							WR1A <= WRA_IDLE;
						end if;
					
					when WRA_S68K_END => 
						if S68K_WORDRAM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
							S68K_WORDRAM_DTACK_N <= '1';
							WR1A <= WRA_IDLE;
						end if;
						
					when WRA_DMA_END => 
						if WR_DMA_RUN = '1' then
							WR_DMA_RUN <= '0';
							WR1A <= WRA_IDLE;
						end if;
						
					when WRA_GFX_END => 
						if WR_GFX_RUN = '1' then
							WR_GFX_RUN <= '0';
							WR1A <= WRA_IDLE;
						end if;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	--Graphics
	process( RST_N, CLK )
	variable X : std_logic_vector(23 downto 11);
	variable Y : std_logic_vector(23 downto 11);
	variable STAMP_X : std_logic_vector(16 downto 0);
	variable STAMP_Y : std_logic_vector(16 downto 0);
	variable STAMP_BASE : std_logic_vector(17 downto 1);
	variable STAMP_N : std_logic_vector(10 downto 0);
	variable STAMP_A : std_logic_vector(17 downto 1);
	variable STAMP_DATA_ADDR : std_logic_vector(17 downto 1);
	variable PIX_X : std_logic_vector(4 downto 0);
	variable PIX_Y : std_logic_vector(4 downto 0);
	variable COLOR : std_logic_vector(3 downto 0);
	variable IMAGE_DATA_ADDR : std_logic_vector(18 downto 0);
	variable OUTSIDE : std_logic;
	begin
		if RST_N = '0' then
			GS <= GS_IDLE;
			GFX_ADDR <= (others => '0');
			GFX_SEL <= '0';
			GFX_RMW <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				OLD_IEN1 <= IEN(1);
				if INT_ACK(1) = '1' and INT_PEND(1) = '1' then
					INT_PEND(1) <= '0';
				elsif IEN(1) = '0' and OLD_IEN1 = '1' and INT_PEND(1) = '1' then
					INT_PEND(1) <= '0';
				end if;
				
				if VW_SET = '1' then
					VDOTS <= VW;
				end if;
				
				if RPT = '1' then
					if SMS = '0' then
						X := "00000" & GFX.X(18 downto 11);
						Y := "00000" & GFX.Y(18 downto 11);
					else
						X := "0" & GFX.X(22 downto 11);
						Y := "0" & GFX.Y(22 downto 11);
					end if;
				else
					X := GFX.X(23 downto 11);
					Y := GFX.Y(23 downto 11);
				end if;
				
				if (SMS = '0' and (X(23 downto 19) /= "00000" or Y(23 downto 19) /= "00000")) or
					(SMS = '1' and (X(23 downto 23) /= "0" or Y(23 downto 23) /= "0")) then
					OUTSIDE := '1';
				else
					OUTSIDE := '0';
				end if;
					
				IMAGE_DATA_ADDR := std_logic_vector( (unsigned(ISA) & "000000") + unsigned(IMAGE_LINE&IMAGE_DOT) + (unsigned(IMAGE_CELL) & "000000") );
				STAMP_N := GFX.SD(10 downto 0);
				case GS is
					when GS_IDLE => 
						if GRON = '1' and CLK_12M_R = '1' then
							VA <= TVBA & "00";
							IMAGE_DOT <= unsigned(DOT);
							IMAGE_LINE <= "0000000000000" & unsigned(LN);
							IMAGE_CELL <= "0000000000000";
							HDOTS <= HW;
							GFX_DO <= x"0000";
							GS <= GS_XY_READ;
						end if;
						
					when GS_XY_READ => 
						if CLK_12M_R = '1' then
							GFX_ADDR <= VA;
							GFX_SEL <= '1';
							GFX_RMW <= '0';
							GS <= GS_XY_WAIT;
						end if;
						
					when GS_XY_WAIT =>
						if GFX_SEL = '1' and WR_GFX_RUN = '1' then
							GFX_SEL <= '0';
						elsif GFX_SEL = '0' and WR_GFX_RUN = '0' and CLK_12M_R = '1' then
							case VA(2 downto 1) is
								when "00" => 	GFX.X <= GFX_WORDRAM_DO & x"00";
								when "01" => 	GFX.Y <= GFX_WORDRAM_DO & x"00";
								when "10" => 	GFX.DX <= (7 downto 0 => GFX_WORDRAM_DO(15)) & GFX_WORDRAM_DO;
								when others => GFX.DY <= (7 downto 0 => GFX_WORDRAM_DO(15)) & GFX_WORDRAM_DO;
							end case;
							
							VA <= std_logic_vector( unsigned(VA) + 1 );
							if VA(2 downto 1) = "11" then
								GS <= GS_STAMP_READ;
							else
								GS <= GS_XY_READ;
							end if;
						end if;
							
					when GS_STAMP_READ =>
						if STS = '0' then
							STAMP_X := "00000000" & X(23 downto 15);
							if SMS = '0' then
								STAMP_Y := "0000" & Y(23 downto 15) & "0000";
								STAMP_BASE := SMBA(17 downto 9) & "00" & "000000";
							else
								STAMP_Y := Y(23 downto 15) & "00000000";
								STAMP_BASE := SMBA(17) & "0000000000" & "000000";
							end if;
						else
							STAMP_X := "000000000" & X(23 downto 16);
							if SMS = '0' then
								STAMP_Y := "000000" & Y(23 downto 16) & "000";
								STAMP_BASE := SMBA(17 downto 7) & "000000";
							else
								STAMP_Y := "00" & Y(23 downto 16) & "0000000";
								STAMP_BASE := SMBA(17 downto 15) & "00000000" & "000000";
							end if;
						end if;
						
						STAMP_A := std_logic_vector( unsigned(STAMP_BASE) + unsigned(STAMP_Y) + unsigned(STAMP_X) );
						
						if CLK_12M_R = '1' then
							GFX_ADDR <= STAMP_A;
							GFX_SEL <= '1';
							GFX_RMW <= '0';
							GS <= GS_STAMP_WAIT;
						end if;
					
					when GS_STAMP_WAIT =>
						if GFX_SEL = '1' and WR_GFX_RUN = '1' then
							GFX_SEL <= '0';
						elsif GFX_SEL = '0' and WR_GFX_RUN = '0' and CLK_12M_R = '1' then
							GFX.SD <= GFX_WORDRAM_DO;
							GS <= GS_DOT_READ;
						end if;
							
					when GS_DOT_READ =>
						case GFX.SD(15 downto 13) is
							when "000" =>
								PIX_X := 	 X(15 downto 11);
								PIX_Y := 	 Y(15 downto 11);
							when "001" =>
								PIX_X := not Y(15 downto 11);
								PIX_Y := 	 X(15 downto 11);
							when "010" =>
								PIX_X := not X(15 downto 11);
								PIX_Y := not Y(15 downto 11);
							when "011" =>
								PIX_X := 	 Y(15 downto 11);
								PIX_Y := not X(15 downto 11);
							when "100" =>
								PIX_X := not X(15 downto 11);
								PIX_Y := 	 Y(15 downto 11);
							when "101" =>
								PIX_X := not Y(15 downto 11);
								PIX_Y := not X(15 downto 11);
							when "110" =>
								PIX_X := 	 X(15 downto 11);
								PIX_Y := not Y(15 downto 11);
							when others => 
								PIX_X := 	 Y(15 downto 11);
								PIX_Y := 	 X(15 downto 11);
						end case;
						GFX.NIB <= PIX_X(1 downto 0);
						
						if STS = '0' then
							STAMP_DATA_ADDR := STAMP_N(10 downto 0) & PIX_X(3) & PIX_Y(3) & PIX_Y(2 downto 0) & PIX_X(2);
						else 
							STAMP_DATA_ADDR := STAMP_N(10 downto 2) & PIX_X(4 downto 3) & PIX_Y(4 downto 3) & PIX_Y(2 downto 0) & PIX_X(2);
						end if;
						
						if CLK_12M_R = '1' then
							GFX_ADDR <= STAMP_DATA_ADDR;
							GFX_SEL <= '1';
							GFX_RMW <= '0';
							GS <= GS_DOT_WAIT;
						end if;
					
					when GS_DOT_WAIT =>
						if GFX_SEL = '1' and WR_GFX_RUN = '1' then
							GFX_SEL <= '0';
						elsif GFX_SEL = '0' and WR_GFX_RUN = '0' and CLK_12M_R = '1' then
							if STAMP_N = "00000000000" or OUTSIDE = '1' then
								COLOR := (others => '0');
							else
								case GFX.NIB is
									when "00" => COLOR := GFX_WORDRAM_DO(15 downto 12);
									when "01" => COLOR := GFX_WORDRAM_DO(11 downto 8);
									when "10" => COLOR := GFX_WORDRAM_DO(7 downto 4);
									when others => COLOR := GFX_WORDRAM_DO(3 downto 0);
								end case;
							end if;
							
							case IMAGE_DOT(1 downto 0) is
								when "00" => GFX_DO(15 downto 12) <= COLOR;
								when "01" => GFX_DO(11 downto 8) <= COLOR;
								when "10" => GFX_DO(7 downto 4) <= COLOR;
								when others => GFX_DO(3 downto 0) <= COLOR;
							end case;
							
							GFX.X <= std_logic_vector( unsigned(GFX.X) + unsigned(GFX.DX) );
							GFX.Y <= std_logic_vector( unsigned(GFX.Y) + unsigned(GFX.DY) );
							
							IMAGE_DOT(1 downto 0) <= IMAGE_DOT(1 downto 0) + 1;
							HDOTS <= std_logic_vector( unsigned(HDOTS) - 1 );
							if HDOTS = "000000001" or IMAGE_DOT(1 downto 0) = "11" then
								GS <= GS_WRITE;
							else
								GS <= GS_STAMP_READ;
							end if;
						end if;
	
					when GS_WRITE =>					
						if CLK_12M_R = '1' then
							GFX_ADDR <= IMAGE_DATA_ADDR(18 downto 2);
							GFX_SEL <= '1';
							GFX_RMW <= '1';
							GS <= GS_WRITE_WAIT;
						end if;
						
					when GS_WRITE_WAIT =>
						if GFX_SEL = '1' and WR_GFX_RUN = '1' then
							GFX_SEL <= '0';
							GFX_RMW <= '0';
						elsif GFX_SEL = '0' and WR_GFX_RUN = '0' and CLK_12M_R = '1' then
							IMAGE_DOT(2) <= not IMAGE_DOT(2);
							if IMAGE_DOT(2) = '1' then
								IMAGE_CELL <= IMAGE_CELL + unsigned(VCS) + 1;
							end if;
	
							if HDOTS = "000000000" then
								HDOTS <= HW;
								IMAGE_DOT <= unsigned(DOT);
								IMAGE_LINE <= IMAGE_LINE + 1;
								IMAGE_CELL <= "0000000000000";
								VDOTS <= std_logic_vector( unsigned(VDOTS) - 1 );
								if VDOTS = "00000001" then
									GS <= GS_END;
								else
									GS <= GS_XY_READ;
								end if;
							else
								GS <= GS_STAMP_READ;
							end if;
							
							GFX_DO <= x"0000";
						end if;
								
					when GS_END =>
						if IEN(1) = '1' then
							INT_PEND(1) <= '1';
						end if;
						GS <= GS_IDLE;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;

	
	process( MODE, RET1, EXT_VA, WR0R, WR1R )
	variable MWR_AS : std_logic_vector(16 downto 1);
	variable MWR_AD : std_logic_vector(16 downto 1);
	begin
		if MODE = '0' then						--2M mode
			WORDRAM0_A <= WR0R.A;
			WORDRAM1_A <= WR1R.A;
		else											--1M mode
			if RET1 = '0' then
				MWR_AS := WR0R.A;
			else
				MWR_AS := WR1R.A;
			end if;
				
			if EXT_VA(17) = '0' then							--$200000-$21FFFF 1M WORD-RAM 0/1 
				MWR_AD := MWR_AS;
			else														--$220000-$23FFFF VRAM image 1M WORD-RAM 0/1 
				if EXT_VA(17 downto 16) = "10" then			--$200000-$20FFFF -> $220000-$22FFFF V32 cells
					MWR_AD := "0" & MWR_AS(9 downto 5) & MWR_AS(4 downto 2) & MWR_AS(15 downto 10) & MWR_AS(1);
				elsif EXT_VA(17 downto 15) = "110" then	--$210000-$217FFF -> $230000-$237FFF V16 cells
					MWR_AD := "10" & MWR_AS(8 downto 5) & MWR_AS(4 downto 2) & MWR_AS(14 downto 9) & MWR_AS(1);
				elsif EXT_VA(17 downto 14) = "1110" then	--$218000-$21BFFF -> $238000-$23BFFF V8 cells
					MWR_AD := "110" & MWR_AS(7 downto 5) & MWR_AS(4 downto 2) & MWR_AS(13 downto 8) & MWR_AS(1);
				elsif EXT_VA(17 downto 13) = "11110" then	--$21C000-$21DFFF -> $23C000-$23DFFF V4 cells
					MWR_AD := "1110" & MWR_AS(6 downto 5) & MWR_AS(4 downto 2) & MWR_AS(12 downto 7) & MWR_AS(1);
				else													--$21E000-$21FFFF -> $23E000-$23FFFF V4 cells
					MWR_AD := "1111" & MWR_AS(6 downto 5) & MWR_AS(4 downto 2) & MWR_AS(12 downto 7) & MWR_AS(1);
				end if;
			end if;
			
			if RET1 = '0' then
				WORDRAM0_A <= MWR_AD;
				WORDRAM1_A <= WR1R.A;
			else
				WORDRAM0_A <= WR0R.A;
				WORDRAM1_A <= MWR_AD;
			end if;
		end if;
	end process;
	
	WORDRAM0_DO <= WORD_RAM_1M0_DO;
	WORDRAM1_DO <= WORD_RAM_1M1_DO;
	WORDRAM0_WR <= WORD_RAM_1M0_WR;
	WORDRAM1_WR <= WORD_RAM_1M1_WR;
	
	
	
	--S68K PCM
	S68K_PCM_SEL <= '1' when S68K_A(19 downto 15) = x"F" & "0" and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
	DMA_PCM_SEL <= '1' when DD = "100" and DS = DS_WRITE else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			S68K_PCM_DTACK_N <= '1';
			PCMA <= PCMA_IDLE;
			PCM_DMA_ADDR <= (others => '0');
			PCM_DMA_DO <= (others => '0');
			PCM_DMA_WR <= '0';
			PCM_DMA_RUN <= '0';
			PCM_S68K_HALT <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				if S68K_PCM_SEL = '1' and S68K_PCM_DTACK_N = '1' then
					S68K_PCM_DTACK_N <= '0';
				elsif S68K_PCM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
					S68K_PCM_DTACK_N <= '1';
				end if;
				
				case PCMA is
					when PCMA_IDLE => 
						if DMA_PCM_SEL = '1' then
							PCM_DMA_ADDR <= "1" & DMA_ADDR(12 downto 1);
							PCM_DMA_DO <= DMA_DAT(7 downto 0);
							PCM_DMA_RUN <= '1';
							PCMA <= PCMA_DMA_HALT0;
						end if;
					
					when PCMA_DMA_HALT0 =>
						if S68K_AS_N = '1' and CLK_12M_R = '1' then
							PCMA <= PCMA_DMA_HALT1;
						end if;
						
					when PCMA_DMA_HALT1 =>
						if S68K_AS_N = '0' and CLK_12M_R = '1' then
							PCM_S68K_HALT <= '1';
							PCMA <= PCMA_DMA_HALT2;
						end if;
						
					when PCMA_DMA_HALT2 =>
						if S68K_AS_N = '1' and CLK_12M_R = '1' then
							PCM_HALT_WAIT <= PCM_HALT_WAIT + 1;
							if PCM_HALT_WAIT = 1 then
								PCM_HALT_WAIT <= "00";
								PCM_S68K_HALT <= '0';
								PCM_DMA_WR <= '1';
								PCMA <= PCMA_DMA_WRITE;
							end if;
						end if;
					
					when PCMA_DMA_WRITE =>
						if CLK_12M_R = '1' then
							PCM_HALT_WAIT <= PCM_HALT_WAIT + 1;
							if PCM_HALT_WAIT = 1 then
								PCM_HALT_WAIT <= "00";
								PCMA <= PCMA_END;
							end if;
						end if;
					
					when PCMA_END => 
						if PCM_DMA_RUN = '1' then
							PCM_DMA_RUN <= '0';
							PCM_DMA_WR <= '0';
							PCMA <= PCMA_IDLE;
						end if;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	PCM_A <= PCM_DMA_ADDR when PCMA = PCMA_DMA_WRITE else S68K_A(13 downto 1);
	PCM_DI <= PCM_DMA_DO when PCMA = PCMA_DMA_WRITE else S68K_DI(7 downto 0);
	PCM_WE_N <= not PCM_DMA_WR when PCMA = PCMA_DMA_WRITE else S68K_LDS_N or S68K_RNW;
	PCM_N <= '0' when S68K_PCM_SEL = '1' else 
				'0' when PCMA = PCMA_DMA_WRITE else
				'1';
	
	
	--S68K BRAM
	S68K_BRAM_SEL <= '1' when S68K_A(19 downto 16) = x"E" and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			S68K_BRAM_DTACK_N <= '1';
		elsif rising_edge(CLK) then
			if EN = '1' then
				if S68K_BRAM_SEL = '1' and S68K_BRAM_DTACK_N = '1' then
					S68K_BRAM_DTACK_N <= '0';
				elsif S68K_BRAM_DTACK_N = '0' and S68K_LDS_N = '1' and S68K_UDS_N = '1' then
					S68K_BRAM_DTACK_N <= '1';
				end if;
			end if;
		end if;
	end process;
	BRAM_N <= '0' when S68K_BRAM_SEL = '1' else '1';
	
		
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			HS <= HS_IDLE;
			HALT_WAIT <= (others => '0');
			S68K_HALT <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' then
				case HS is
					when HS_IDLE => 
						if PRG_RAM_RFS_SCHED = '1' and SBRQ = '0' and SRES = '1' then
							HS <= HS_HALT0;
						end if;
					
					when HS_HALT0 =>
						if S68K_AS_N = '1' and CLK_12M_R = '1' then
							HS <= HS_HALT1;
						end if;
						
					when HS_HALT1 =>
						if S68K_AS_N = '0' and CLK_12M_R = '1' then
							S68K_HALT <= '1';
							HS <= HS_HALT2;
						end if;
						
					when HS_HALT2 =>
						if S68K_AS_N = '1' and CLK_12M_R = '1' then
							HALT_WAIT <= HALT_WAIT + 1;
							if HALT_WAIT = 1 then
								HALT_WAIT <= "00";
								S68K_HALT <= '0';
								HS <= HS_EXEC;
							end if;
						end if;
					
					when HS_EXEC =>
						if CLK_12M_R = '1' then
							HALT_WAIT <= HALT_WAIT + 1;
							if HALT_WAIT = 1 then
								HALT_WAIT <= "00";
								HS <= HS_END;
							end if;
						end if;
					
					when HS_END => 
						HS <= HS_IDLE;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	--S68K Interrupts
	process( S68K_A, S68K_AS_N, S68K_FC, S68K_RNW, INT_PEND, IEN )
	begin
		INT_ACK <= (others => '0');
		INT_VPA_N <= '1';
		if S68K_RNW = '1' and S68K_AS_N = '0' and S68K_FC = "11" then
			case S68K_A(3 downto 1) is
				when "001" => INT_ACK(1) <= '1';
				when "010" => INT_ACK(2) <= '1';
				when "011" => INT_ACK(3) <= '1';
				when "100" => INT_ACK(4) <= '1';
				when "101" => INT_ACK(5) <= '1';
				when "110" => INT_ACK(6) <= '1';
				when others => null;
			end case;
			INT_VPA_N <= '0';
		end if;
		
		if INT_PEND(6) = '1' and IEN(6) = '1' then
			INT_IPL <= "110";
		elsif INT_PEND(5) = '1' and IEN(5) = '1' then
			INT_IPL <= "101";
		elsif INT_PEND(4) = '1' and IEN(4) = '1' then
			INT_IPL <= "100";	
		elsif INT_PEND(3) = '1' and IEN(3) = '1' then
			INT_IPL <= "011";
		elsif INT_PEND(2) = '1' and IEN(2) = '1' then
			INT_IPL <= "010";
		elsif INT_PEND(1) = '1' and IEN(1) = '1' then
			INT_IPL <= "001";
		else
			INT_IPL <= "000";
		end if;
	end process;
	
	--S68K MDR
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			S68K_MDR <= (others => '0');
		elsif rising_edge(CLK) then
			if EN = '1' then
				if S68K_RNW = '1' and (S68K_LDS_N = '0' or S68K_UDS_N = '0') and S68K_AS_N = '0' then
					if S68K_REG_DTACK_N = '0' then
						S68K_MDR <= S68K_REG_DO;
					elsif S68K_PRGRAM_DTACK_N = '0' then
						S68K_MDR <= S68K_PRGRAM_DO;
					elsif S68K_WORDRAM_DTACK_N = '0' then
						S68K_MDR <= S68K_WORDRAM_DO;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			GEN_S68K_HALT <= '0';
		elsif rising_edge(CLK) then
			if EN = '1' and CLK_12M_R = '1' then
				GEN_S68K_HALT <= SBRQ;
			end if;
		end if;
	end process;
				  
	S68K_CE_F <= CLK_12M_F;
	S68K_CE_R <= CLK_12M_R;
	S68K_HALT_N <= not (GEN_S68K_HALT or PCM_S68K_HALT or S68K_HALT);
	S68K_RESET_N <= SRES;
	S68K_VPA_N <= INT_VPA_N;
	S68K_IPL_N <= not INT_IPL;
	S68K_DTACK_N <= S68K_REG_DTACK_N and S68K_PRGRAM_DTACK_N and S68K_WORDRAM_DTACK_N and S68K_PCM_DTACK_N and S68K_BRAM_DTACK_N;
	S68K_DO <= S68K_REG_DO when S68K_REG_DTACK_N = '0' else
				  S68K_PRGRAM_DO when S68K_PRGRAM_DTACK_N = '0' else
				  S68K_WORDRAM_DO when S68K_WORDRAM_DTACK_N = '0' else
				  S68K_MDR;
				  
	BROM_N <= '0' when EXT_ROM_N = '0' and EXT_VA(17) = '0' and EXT_VA(16 downto 2) /= "0"&x"007"&"00" and EXT_ASEL_N = '0' else '1';
	CDC_N <= '0' when S68K_A(19 downto 2) = x"F800" & "01" and S68K_LDS_N = '0' and S68K_AS_N = '0' else '1';
	
	CLWE_N <= S68K_LDS_N or S68K_RNW;
	CUWE_N <= S68K_UDS_N or S68K_RNW;
	COE_N <= (S68K_LDS_N and S68K_UDS_N) or not S68K_RNW;
	
end rtl;
