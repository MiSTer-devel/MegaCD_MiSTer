library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity MCD is
	port(
		CLK				: in std_logic;
		RST_N				: in std_logic;
		ENABLE			: in std_logic;
		MCD_RST_N      : out std_logic;
		PALSW				: in std_logic;

		EXT_VA   		: in std_logic_vector(17 downto 1);
		EXT_VDI			: in std_logic_vector(15 downto 0);
		EXT_VDO			: out std_logic_vector(15 downto 0);
		EXT_AS_N			: in std_logic;
		EXT_RNW			: in std_logic;
		EXT_LDS_N		: in std_logic;
		EXT_UDS_N		: in std_logic;
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
		
		ROM_DI			: in std_logic_vector(15 downto 0);
		ROM_CE_N			: out std_logic;
		ROM_RDY			: in std_logic;
		
		BRAM_A			: out std_logic_vector(13 downto 1);
		BRAM_DI			: in std_logic_vector(7 downto 0);
		BRAM_DO			: out std_logic_vector(7 downto 0);
		BRAM_WE			: out std_logic;
		
		CDD_STAT			: in std_logic_vector(39 downto 0);
		CDD_COMM			: out std_logic_vector(39 downto 0);
		CDD_SEND			: out std_logic;
		CDD_REC			: in std_logic;
		CDD_DM			: in std_logic;
		
		CDC_DATA			: in std_logic_vector(15 downto 0);
		CDC_DAT_WR		: in std_logic;
		CDC_SC_WR		: in std_logic;
		
		PCM_SL			: out signed(15 downto 0);
		PCM_SR			: out signed(15 downto 0);
		CDDA_SL			: out signed(15 downto 0);
		CDDA_SR			: out signed(15 downto 0);
		
		LED_RED			: out std_logic;
		LED_GREEN		: out std_logic;
		
		GG_RESET       : in std_logic;
		GG_EN          : in std_logic;
		GG_CODE        : in std_logic_vector(128 downto 0);
		GG_AVAILABLE   : out std_logic;
		
		DBG_S68K_A		: out std_logic_vector(23 downto 0)
	);
end MCD;

architecture rtl of MCD is

	signal S68K_A   		: std_logic_vector(23 downto 1);
	signal S68K_DI			: std_logic_vector(15 downto 0);
	signal S68K_DO			: std_logic_vector(15 downto 0);
	signal S68K_AS_N		: std_logic;
	signal S68K_RNW		: std_logic;
	signal S68K_UDS_N		: std_logic;
	signal S68K_LDS_N		: std_logic;
	signal S68K_DTACK_N	: std_logic;
	signal S68K_IPL_N		: std_logic_vector(2 downto 0);
	signal S68K_VPA_N		: std_logic;
	signal S68K_FC			: std_logic_vector(2 downto 0);
	signal S68K_HALT_N	: std_logic;
	signal S68K_RESET_N	: std_logic;
	signal S68K_CE_F		: std_logic;
	signal S68K_CE_R		: std_logic;
	
	signal WORDRAM0_A   	: std_logic_vector(15 downto 0);
	signal WORDRAM0_DI	: std_logic_vector(15 downto 0);
	signal WORDRAM0_DO	: std_logic_vector(15 downto 0);
	signal WORDRAM0_WR	: std_logic;
	signal WORDRAM1_A   	: std_logic_vector(15 downto 0);
	signal WORDRAM1_DI	: std_logic_vector(15 downto 0);
	signal WORDRAM1_DO	: std_logic_vector(15 downto 0);
	signal WORDRAM1_WR	: std_logic;
	
	signal PCM_A			: std_logic_vector(12 downto 0);
	signal PCM_DO			: std_logic_vector(7 downto 0);
	signal PCM_DI			: std_logic_vector(7 downto 0);
	signal PCM_WE_N		: std_logic;
	signal PCM_N			: std_logic;
	
	signal PRAM_N			: std_logic;
	signal BRAM_N			: std_logic;
	signal BROM_N			: std_logic;
	signal CDC_N			: std_logic;
	signal COE_N			: std_logic;
	signal CLWE_N			: std_logic;
	signal CUWE_N			: std_logic;
	signal INT_N			: std_logic;
	signal ERES_N			: std_logic;
	
	signal ASIC_DO			: std_logic_vector(15 downto 0);
	
	signal CDC_DO			: std_logic_vector(7 downto 0);
	signal CDC_HDO			: std_logic_vector(7 downto 0);
	signal CDC_HRD_N		: std_logic;
	signal CDC_DTEN_N		: std_logic;
	signal CDC_WAIT_N		: std_logic;
	signal CDC_INT_N		: std_logic;
	signal CDC_RAM_A_WR	: std_logic_vector(15 downto 1);
	signal CDC_RAM_A_RD	: std_logic_vector(15 downto 0);
	signal CDC_RAM_DI		: std_logic_vector(7 downto 0);
	signal CDC_RAM_DO		: std_logic_vector(15 downto 0);
	signal CDC_RAM_WE		: std_logic;
	
	signal PCM_RAM_ADDR_A: std_logic_vector(15 downto 0);
	signal PCM_RAM_ADDR_B: std_logic_vector(15 downto 0);
	signal PCM_RAM_DI_A	: std_logic_vector(7 downto 0);
	signal PCM_RAM_DI_B	: std_logic_vector(7 downto 0);
	signal PCM_RAM_DO_A	: std_logic_vector(7 downto 0);
	signal PCM_RAM_WE_A	: std_logic;
	
	signal ASIC_FD_DAT	: std_logic_vector(10 downto 0);
	signal ASIC_FD_WR		: std_logic;

	signal GENIE_DATA    : std_logic_vector(15 downto 0);
	
	component CODES
		generic
		(
			ADDR_WIDTH    : integer := 16;
			DATA_WIDTH    : integer := 8;
			BIG_ENDIAN    : integer := 0
		);
		port
		(
			clk           : in  std_logic;
			reset         : in  std_logic;
			enable        : in  std_logic;
			available     : out std_logic;
			code          : in  std_logic_vector(128 downto 0);
			addr_in       : in  std_logic_vector(23 downto 0);
			data_in       : in  std_logic_vector(15 downto 0);
			data_out      : out std_logic_vector(15 downto 0)
	  );
	end component; 
	
begin

	gg : CODES
	generic map(
		ADDR_WIDTH  => 24,
		DATA_WIDTH  => 16,
		BIG_ENDIAN  => 1
	)
	port map(
		clk         => CLK,
		reset       => GG_RESET,
		enable      => not GG_EN,
		available   => GG_AVAILABLE,
		code        => GG_CODE,
		addr_in     => S68K_A & '0',
		data_in     => S68K_DI,
		data_out    => GENIE_DATA
	);

	S68K :  entity work.M68K_WRAP
	port map(
		CLK   		=> CLK,
		RST_N      	=> RST_N,
		
		RESET_I_N	=> S68K_RESET_N,
		CLKEN_P   	=> S68K_CE_R,
		CLKEN_N		=> S68K_CE_F,
		A   			=> S68K_A,
		DI   			=> GENIE_DATA,
		DO   			=> S68K_DO,
		AS_N   		=> S68K_AS_N,
		RNW   		=> S68K_RNW,
		UDS_N   		=> S68K_UDS_N,
		LDS_N   		=> S68K_LDS_N,
		DTACK_N		=> S68K_DTACK_N,
		IPL_N   		=> S68K_IPL_N,
		VPA_N   		=> S68K_VPA_N,
		FC   			=> S68K_FC,
		HALT_I_N		=> S68K_HALT_N,
		BERR_N   	=> '1',
		BR_N   		=> '1',
		BGACK_N   	=> '1'
	);
	
	S68K_DI(7 downto 0) <= CDC_DO when CDC_N = '0' else
								  BRAM_DI when BRAM_N = '0' else
								  PCM_DO when PCM_N = '0' else
								  ASIC_DO(7 downto 0);
	S68K_DI(15 downto 8) <= ASIC_DO(15 downto 8);
	
	ASIC : entity work.ASIC
	port map(
		CLK   			=> CLK,
		RST_N       	=> RST_N,
		ENABLE      	=> ENABLE,
		
		S68K_A   		=> S68K_A(23 downto 1),
		S68K_DI   		=> S68K_DO,
		S68K_DO   		=> ASIC_DO,
		S68K_AS_N   	=> S68K_AS_N,
		S68K_RNW   		=> S68K_RNW,
		S68K_UDS_N   	=> S68K_UDS_N,
		S68K_LDS_N   	=> S68K_LDS_N,
		S68K_DTACK_N	=> S68K_DTACK_N,
		S68K_IPL_N   	=> S68K_IPL_N,
		S68K_VPA_N   	=> S68K_VPA_N,
		S68K_FC   		=> S68K_FC(1 downto 0),
		S68K_HALT_N   	=> S68K_HALT_N,
		S68K_RESET_N   => S68K_RESET_N,
		S68K_CE_F  	 	=> S68K_CE_F,
		S68K_CE_R   	=> S68K_CE_R,
		
		EXT_VA   		=> EXT_VA,
		EXT_VDI   		=> EXT_VDI,
		EXT_VDO   		=> EXT_VDO,
		EXT_AS_N   		=> EXT_AS_N,
		EXT_RNW   		=> EXT_RNW,
		EXT_UDS_N   	=> EXT_UDS_N,
		EXT_LDS_N   	=> EXT_LDS_N,
		EXT_DTACK_N   	=> EXT_DTACK_N,
		EXT_ASEL_N   	=> EXT_ASEL_N,
		EXT_VCLK_CE   	=> EXT_VCLK_CE,
		EXT_RAS2_N   	=> EXT_RAS2_N,
		EXT_ROM_N   	=> EXT_ROM_N,
		EXT_FDC_N   	=> EXT_FDC_N,
		
		PRG_A   			=> PRG_A,
		PRG_DI  			=> PRG_DI,
		PRG_DO  			=> PRG_DO,
		PRG_WRL_N  		=> PRG_WRL_N,
		PRG_WRH_N  		=> PRG_WRH_N,
		PRG_OE_N  		=> PRG_OE_N,
		PRG_RFS  		=> PRG_RFS,
		PRG_RDY  		=> PRG_RDY,
		
		PCM_A   			=> PCM_A,
		PCM_DI   		=> PCM_DI,
		PCM_WE_N   		=> PCM_WE_N,
		PCM_N   			=> PCM_N,
		
		ROM_DI   		=> ROM_DI,
		ROM_CE_N   		=> ROM_CE_N,
		ROM_RDY   		=> ROM_RDY,
		
		--PRAM_N  			=> PRAM_N,
		BRAM_N   		=> BRAM_N,
		--BROM_N   		=> BROM_N,
		CDC_N	  	 		=> CDC_N,
		COE_N	  	 		=> COE_N,
		CLWE_N   		=> CLWE_N,
		--CUWE_N   		=> CUWE_N,
		CDC_INT_N	   => CDC_INT_N,
		ERES_N   		=> ERES_N,
		
		CDC_HDI	   	=> CDC_HDO,
		CDC_HRD_N	   => CDC_HRD_N,
		CDC_DTEN_N	   => CDC_DTEN_N,
		CDC_WAIT_N	   => CDC_WAIT_N,
		
		CD_DI   			=> CDC_DATA,
		CD_SC_WR			=> CDC_SC_WR,
		
		CDD_STAT 		=> CDD_STAT,
		CDD_COMM 		=> CDD_COMM,
		CDD_SEND 		=> CDD_SEND,
		CDD_REC 			=> CDD_REC,
		CDD_DM 			=> CDD_DM,
		
		WORDRAM0_A   	=> WORDRAM0_A,
		WORDRAM0_DI   	=> WORDRAM0_DI,
		WORDRAM0_DO   	=> WORDRAM0_DO,
		WORDRAM0_WR   	=> WORDRAM0_WR,
		WORDRAM1_A    	=> WORDRAM1_A,
		WORDRAM1_DI   	=> WORDRAM1_DI,
		WORDRAM1_DO   	=> WORDRAM1_DO,
		WORDRAM1_WR   	=> WORDRAM1_WR,
		
		FD_DAT 			=> ASIC_FD_DAT,
		FD_WR 			=> ASIC_FD_WR,
		
		LED_RED   		=> LED_RED,
		LED_GREEN   	=> LED_GREEN
	);
	
	MCD_RST_N <= ERES_N;

	BRAM_A <= S68K_A(13 downto 1);
	BRAM_DO <= S68K_DO(7 downto 0);
	BRAM_WE <= not (CLWE_N or BRAM_N);
	
	
	WORDRAM0 : entity work.spram
	generic map(16,16)
	port map(
		clock		=> CLK,
		address	=> WORDRAM0_A,
		data		=> WORDRAM0_DO,
		wren		=> WORDRAM0_WR,
		q			=> WORDRAM0_DI
	);

	WORDRAM1 : entity work.spram
	generic map(16,16)
	port map(
		clock		=> CLK,
		address	=> WORDRAM1_A,
		data		=> WORDRAM1_DO,
		wren		=> WORDRAM1_WR,
		q			=> WORDRAM1_DI
	);
	
	
	CDC : entity work.CDC
	port map(
		CLK   		=> CLK,
		RESET_N     => ERES_N,
		ENABLE      => ENABLE,
		
		CLKEN_P   	=> S68K_CE_R,
		CLKEN_N		=> S68K_CE_F,
		DI   			=> S68K_DO(7 downto 0),
		DO   			=> CDC_DO,
		CS_N   		=> CDC_N,
		RS   			=> S68K_A(1),
		RD_N   		=> COE_N,
		WR_N   		=> CLWE_N,
		INT_N   		=> CDC_INT_N,
		
		HDO   		=> CDC_HDO,
		HRD_N   		=> CDC_HRD_N,
		DTEN_N   	=> CDC_DTEN_N,
		WAIT_N   	=> CDC_WAIT_N,
		
		CD_DI   		=> CDC_DATA,
		CD_WR   		=> CDC_DAT_WR,
		
		RAM_A_WR   	=> CDC_RAM_A_WR,
		RAM_A_RD   	=> CDC_RAM_A_RD,
		RAM_DI   	=> CDC_RAM_DI,
		RAM_DO   	=> CDC_RAM_DO,
		RAM_WE   	=> CDC_RAM_WE
	);
	
	CDC_RAM : entity work.dpram_dif
	generic map(14,8,13,16)
	port map(
		clock			=> CLK,
		address_a	=> CDC_RAM_A_RD(13 downto 0),
		q_a			=> CDC_RAM_DI,

		address_b	=> CDC_RAM_A_WR(13 downto 1),
		data_b		=> CDC_RAM_DO,
		wren_b		=> CDC_RAM_WE
	);
	
	
	PCM : entity work.PCM
	port map(
		CLK   		=> CLK,
		RST_N       => ERES_N,
		ENABLE      => ENABLE,
		PALSW			=> PALSW,
		
		CLKEN			=> S68K_CE_F,
		A   			=> PCM_A,--S68K_A(13 downto 1),
		DI   			=> PCM_DI,--S68K_DO(7 downto 0),
		DO   			=> PCM_DO,
		CS_N   		=> PCM_N,
		RD_N   		=> COE_N,
		WR_N   		=> PCM_WE_N,--CLWE_N,
		
		RAM_ADDR_A  => PCM_RAM_ADDR_A,
		RAM_DI_A   	=> PCM_RAM_DI_A,
		RAM_DO_A		=> PCM_RAM_DO_A,
		RAM_WE_A		=> PCM_RAM_WE_A,
		RAM_ADDR_B	=> PCM_RAM_ADDR_B,
		RAM_DI_B		=> PCM_RAM_DI_B,
		
		SL   			=> PCM_SL,
		SR   			=> PCM_SR
	);
	
	PCM_RAM : entity work.dpram 
	generic map(16)
	port map(
		clock			=> CLK,
		address_a	=> PCM_RAM_ADDR_A,
		data_a		=> PCM_RAM_DO_A,
		wren_a		=> PCM_RAM_WE_A,
		q_a			=> PCM_RAM_DI_A,

		address_b	=> PCM_RAM_ADDR_B,
		q_b			=> PCM_RAM_DI_B
	);
	
	CD_DAC : entity work.CD_DAC
	port map(
		CLK   		=> CLK,
		RST_N       => ERES_N,
		ENABLE      => '1',
		
		PALSW			=> PALSW,
		
		CD_DI   		=> CDC_DATA,
		CD_WR   		=> CDC_DAT_WR,
		
		FD_DI   		=> ASIC_FD_DAT,
		FD_WR   		=> ASIC_FD_WR,
		
		DM   			=> CDD_DM,
		
		SL   			=> CDDA_SL,
		SR   			=> CDDA_SR
	);
	
	DBG_S68K_A <= S68K_A & "0";

end rtl;