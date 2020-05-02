library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity M68K_WRAP is
	port(
		CLK			: in std_logic;
		RST_N			: in std_logic;
		
		RESET_I_N	: in std_logic;
		CLKEN_P 		: in std_logic;
		CLKEN_N 		: in std_logic;
		A   			: out std_logic_vector(23 downto 1);
		DI				: in std_logic_vector(15 downto 0);
		DO				: out std_logic_vector(15 downto 0);
		AS_N			: out std_logic;
		RNW			: out std_logic;
		UDS_N			: out std_logic;
		LDS_N			: out std_logic;
		DTACK_N		: in std_logic;
		IPL_N			: in std_logic_vector(2 downto 0);
		VPA_N			: in std_logic;
		FC				: out std_logic_vector(2 downto 0);
		HALT_I_N		: in std_logic;
		BGACK_N		: in std_logic;
		BG_N			: out std_logic;
		BR_N			: in std_logic;
		VMA_N			: out std_logic;
		E				: out std_logic;
		BERR_N		: in std_logic;
		RESET_O_N	: out std_logic;
		HALT_O_N		: out std_logic
	);
end M68K_WRAP;

architecture rtl of M68K_WRAP is

	signal extReset		: std_logic;
	signal pwrUp		: std_logic;
	
	COMPONENT fx68k
	PORT
	(
		clk  		: IN  STD_LOGIC;
		extReset : IN  STD_LOGIC;
		pwrUp 	: IN  STD_LOGIC;
		enPhi2 	: IN  STD_LOGIC;
		enPhi1 	: IN  STD_LOGIC;
		eab  		: OUT  STD_LOGIC_VECTOR (23 DOWNTO 1);
		iEdb 		: IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
		oEdb 		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		ASn  		: OUT STD_LOGIC;
		eRWn  	: OUT STD_LOGIC;
		UDSn  	: OUT STD_LOGIC;
		LDSn  	: OUT STD_LOGIC;
		DTACKn 	: IN  STD_LOGIC;
		HALTn 	: IN  STD_LOGIC;
		IPL0n 	: IN  STD_LOGIC;
		IPL1n 	: IN  STD_LOGIC;
		IPL2n 	: IN  STD_LOGIC;
		VPAn 		: IN  STD_LOGIC;
		FC0  		: OUT STD_LOGIC;
		FC1  		: OUT STD_LOGIC;
		FC2  		: OUT STD_LOGIC;
		BERRn 	: IN  STD_LOGIC;
		BRn 		: IN  STD_LOGIC;
		BGACKn 	: IN  STD_LOGIC;
		oRESETn  : OUT STD_LOGIC;
		oHALTEDn : OUT STD_LOGIC;
		E  		: OUT STD_LOGIC;
		VMAn  	: OUT STD_LOGIC;
		BGn  		: OUT STD_LOGIC
	);
	END COMPONENT;
	
begin

	pwrUp <= not RST_N;
	extReset <= not RESET_I_N or not RST_N;
	
	P68K :  fx68k
	port map(
		clk   		=> CLK,
		pwrUp      	=> pwrUp,
		extReset    => extReset,
		enPhi1   	=> CLKEN_P,
		enPhi2  	 	=> CLKEN_N,
		
		eab   		=> A,
		iEdb   		=> DI,
		oEdb   		=> DO,
		ASn   		=> AS_N,
		eRWn   		=> RNW,
		UDSn   		=> UDS_N,
		LDSn   		=> LDS_N,
		DTACKn		=> DTACK_N,
		HALTn			=> HALT_I_N,
		IPL0n   		=> IPL_N(0),
		IPL1n   		=> IPL_N(1),
		IPL2n   		=> IPL_N(2),
		VPAn   		=> VPA_N,
		VMAn   		=> VMA_N,
		E   			=> E,
		FC0   		=> FC(0),
		FC1   		=> FC(1),
		FC2   		=> FC(2),
		BERRn   		=> BERR_N,
		BRn   		=> BR_N,
		BGACKn   	=> BGACK_N,
		BGn   		=> BG_N,
		oRESETn   	=> RESET_O_N,
		oHALTEDn   	=> HALT_O_N
	);
	
end rtl;