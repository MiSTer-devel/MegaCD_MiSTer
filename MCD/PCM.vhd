library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity PCM is
	port(
		CLK			: in std_logic;
		RST_N			: in std_logic;
		ENABLE		: in std_logic;
		CLKEN 		: in std_logic;
		
		A				: in std_logic_vector(12 downto 0);
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		CS_N			: in std_logic;
		RD_N			: in std_logic;
		WR_N			: in std_logic;
		
		RAM_ADDR_A 	: out std_logic_vector(15 downto 0);
		RAM_DI_A		: in std_logic_vector(7 downto 0);
		RAM_DO_A		: out std_logic_vector(7 downto 0);
		RAM_WE_A		: out std_logic;
		RAM_ADDR_B  : out std_logic_vector(15 downto 0);
		RAM_DI_B		: in std_logic_vector(7 downto 0);
		
		SL				: out signed(15 downto 0);
		SR				: out signed(15 downto 0)
	);
end PCM;

architecture rtl of PCM is
	
	type reg8x8_t is array(0 to 7) of std_logic_vector(7 downto 0);
	type reg8x16_t is array(0 to 7) of std_logic_vector(15 downto 0);
	type reg8x27_t is array(0 to 7) of std_logic_vector(26 downto 0);
	
	--IO
	signal OLD_WR_N	: std_logic;
	signal OLD_RD_N 	: std_logic;
	signal WR_F 		: std_logic;
	signal RD_F 		: std_logic;
	signal IO_WR 		: std_logic;
	signal IO_RD 		: std_logic;
	signal RAM_WR 		: std_logic;
	signal RAM_RD 		: std_logic;
	signal RAM_DI 		: std_logic_vector(7 downto 0);
	
	--Registers
	signal WB 			: std_logic_vector(3 downto 0);
	signal CB 			: std_logic_vector(2 downto 0);
	signal ONOFF 		: std_logic;
	signal ENV 			: reg8x8_t;
	signal PAN 			: reg8x8_t;
	signal FD 			: reg8x16_t;
	signal LS 			: reg8x16_t;
	signal ST 			: reg8x8_t;
	signal CHOFF 		: std_logic_vector(7 downto 0);
	
	signal EN 			: std_logic;
--	signal RUN 			: std_logic;
	signal CLK_CNT		: unsigned(5 downto 0);
	signal SAMPLE_CE 	: std_logic;
	signal WRA 			: reg8x27_t;
	signal CH 			: unsigned(2 downto 0);
--	signal LP 			: std_logic_vector(7 downto 0);
	signal LSUM, RSUM : unsigned(16 downto 0);
	signal LOUT, ROUT : signed(15 downto 0);
	
	impure function CLAMP16(a: unsigned(16 downto 0)) return unsigned is
		variable res: unsigned(15 downto 0); 
	begin
		if a(16 downto 15) = "01" then
			res := x"7FFF";
		elsif a(16 downto 15) = "10" then
			res := x"8000";
		else
			res := a(16) & a(14 downto 0);
		end if;
		return res;
	end function;


begin

	EN <= ENABLE and CLKEN;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			OLD_WR_N <= '1';
			OLD_RD_N <= '1';
		elsif rising_edge(CLK) then
			if EN = '1' then
				OLD_WR_N <= WR_N;
				OLD_RD_N <= RD_N;
			end if;
		end if;
	end process;
	
	WR_F <= not WR_N and OLD_WR_N;
	RD_F <= not RD_N and OLD_RD_N;
	
	IO_WR <= '1' when CS_N = '0' and WR_F = '1' and A(12 downto 4) = "000000000" else '0';
	IO_RD <= '1' when CS_N = '0' and RD_F = '1' and A(12 downto 4) = "000000001" else '0';
	RAM_WR <= '1' when CS_N = '0' and WR_F = '1' and A(12) = '1' else '0';
	RAM_RD <= '1' when CS_N = '0' and RD_F = '1' and A(12) = '1' else '0';
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			WB <= (others => '0');
			CB <= (others => '0');
			ONOFF <= '0';
			ENV <= (others => (others => '0'));
			PAN <= (others => (others => '1'));
			FD <= (others => (others => '0'));
			LS <= (others => (others => '0'));
			ST <= (others => (others => '0'));
			CHOFF <= (others => '0');
			DO <= (others => '0');
		elsif rising_edge(CLK) then
			if EN = '1' then
				if IO_WR = '1' then
					case A(3 downto 0) is
						when x"0" =>			--ENV
							ENV(to_integer(unsigned(CB))) <= DI;
						when x"1" =>			--PAN
							PAN(to_integer(unsigned(CB))) <= DI;
						when x"2" =>			--FDL
							FD(to_integer(unsigned(CB)))(7 downto 0) <= DI;
						when x"3" =>			--FDH
							FD(to_integer(unsigned(CB)))(15 downto 8) <= DI;
						when x"4" =>			--LSL
							LS(to_integer(unsigned(CB)))(7 downto 0) <= DI;
						when x"5" =>			--LSH
							LS(to_integer(unsigned(CB)))(15 downto 8) <= DI;
						when x"6" =>			--ST
							ST(to_integer(unsigned(CB))) <= DI;
						when x"7" =>			--Control register
							if DI(6) = '0' then
								WB <= DI(3 downto 0);
							else 
								CB <= DI(2 downto 0);
							end if;
							ONOFF <= DI(7);
						when x"8" =>			--Channel ON/OFF
							CHOFF <= DI;
						when others => null;
					end case;
				elsif IO_RD = '1' then
					case A(3 downto 0) is
						when x"0" =>			--
							DO <= WRA(0)(18 downto 11);
						when x"1" =>			--
							DO <= WRA(0)(26 downto 19);
						when x"2" =>			--
							DO <= WRA(1)(18 downto 11);
						when x"3" =>			--
							DO <= WRA(1)(26 downto 19);
						when x"4" =>			--
							DO <= WRA(2)(18 downto 11);
						when x"5" =>			--
							DO <= WRA(2)(26 downto 19);
						when x"6" =>			--
							DO <= WRA(3)(18 downto 11);
						when x"7" =>			--
							DO <= WRA(3)(26 downto 19);
						when x"8" =>			--
							DO <= WRA(4)(18 downto 11);
						when x"9" =>			--
							DO <= WRA(4)(26 downto 19);
						when x"A" =>			--
							DO <= WRA(5)(18 downto 11);
						when x"B" =>			--
							DO <= WRA(5)(26 downto 19);
						when x"C" =>			--
							DO <= WRA(6)(18 downto 11);
						when x"D" =>			--
							DO <= WRA(6)(26 downto 19);
						when x"E" =>			--
							DO <= WRA(7)(18 downto 11);
						when x"F" =>			--
							DO <= WRA(7)(26 downto 19);
						when others => null;
					end case;
				elsif RAM_RD = '1' then
					DO <= RAM_DI_A;
				end if;
			end if;
		end if;
	end process;
	
	RAM_ADDR_A <= WB & A(11 downto 0);
	RAM_DO_A <= DI;
	RAM_WE_A <= RAM_WR;
	
	CEGen : entity work.CEGen
	port map(
		CLK   		=> CLK,
		RST_N       => RST_N,		
		IN_CLK   	=> 53690000,
		OUT_CLK   	=> 260416,				--12500000/384=32552*8=260416
		CE   			=> SAMPLE_CE
	);
	
	process( RST_N, CLK )
	variable WD : unsigned(7 downto 0);
	variable MUL16 : unsigned(15 downto 0);
	variable MUL19L, MUL19R : unsigned(18 downto 0);
	variable SUM17L, SUM17R : unsigned(16 downto 0);
	begin
		if RST_N = '0' then
			CH <= (others => '0');
			WRA <= (others => (others => '0'));
--			LP <= (others => '0');
			LOUT <= (others => '0');
			ROUT <= (others => '0');
			LSUM <= (others => '0');
			RSUM <= (others => '0');
--			RUN <= '0';
		elsif rising_edge(CLK) then
			RAM_DI <= RAM_DI_B;
			if ENABLE = '1' and SAMPLE_CE = '1' then
				CH <= CH + 1;
--				if CH = 7 then
--					RUN <= ONOFF;
--				end if;
				
				if CHOFF(to_integer(CH)) = '0' and ONOFF = '1' and RAM_DI /= x"FF" then
					WD := unsigned(RAM_DI);
				else
					WD := (others => '0');
				end if;
				
				MUL16 := resize( WD(6 downto 0) * unsigned(ENV(to_integer(CH))), MUL16'length );
				MUL19L := resize( MUL16 * unsigned(PAN(to_integer(CH))(3 downto 0)), MUL19L'length );
				MUL19R := resize( MUL16 * unsigned(PAN(to_integer(CH))(7 downto 4)), MUL19R'length );
				
				if WD(7) = '1' then
					SUM17L := resize( LSUM + MUL19L(18 downto 5), SUM17L'length );
					SUM17R := resize( RSUM + MUL19R(18 downto 5), SUM17R'length );
				else
					SUM17L := resize( LSUM - MUL19L(18 downto 5), SUM17L'length );
					SUM17R := resize( RSUM - MUL19R(18 downto 5), SUM17R'length );
				end if;
				
				if CH = 7 then
					LOUT <= signed( CLAMP16(SUM17L) );
					ROUT <= signed( CLAMP16(SUM17R) );
					LSUM <= (others => '0');
					RSUM <= (others => '0');
				else
					LSUM <= SUM17L;
					RSUM <= SUM17R;
				end if;
				
				if CHOFF(to_integer(CH)) = '1' or ONOFF = '0' then
					WRA(to_integer(CH)) <= ST(to_integer(CH)) & "0000000000000000000";
--					LP(to_integer(CH)) <= '0';
				elsif RAM_DI = x"FF" then
					WRA(to_integer(CH)) <= LS(to_integer(CH)) & "00000000000";
--					LP(to_integer(CH)) <= '1';
				else
					WRA(to_integer(CH)) <= std_logic_vector( unsigned(WRA(to_integer(CH))) + unsigned(FD(to_integer(CH))) );
				end if;
			end if;
		end if;
	end process;
	
	RAM_ADDR_B <= WRA(to_integer(CH))(26 downto 11);

	
	SL <= LOUT;
	SR <= ROUT;

end rtl;