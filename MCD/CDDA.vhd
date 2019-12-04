library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity CD_DAC is
	port(
		CLK			: in std_logic;
		RST_N			: in std_logic;
		ENABLE		: in std_logic;
		
		CD_DI			: in std_logic_vector(15 downto 0);
		CD_WR			: in std_logic;
		
		FD_DI			: in std_logic_vector(10 downto 0);
		FD_WR			: in std_logic;
		
		DM				: in std_logic;
		
		SL				: out signed(15 downto 0);
		SR				: out signed(15 downto 0)
	);
end CD_DAC;

architecture rtl of CD_DAC is

	signal EN : std_logic;
	
	signal CD_WR_OLD : std_logic;
	signal LR : std_logic;
	signal FULL : std_logic;
	signal EMPTY : std_logic;
	signal RD_REQ : std_logic;
	signal WR_REQ : std_logic;
	signal FIFO_DATA : std_logic_vector(31 downto 0);
	signal FIFO_Q : std_logic_vector(31 downto 0);
	signal SAMPLE_CE : std_logic;

	signal OUTL : signed(15 downto 0);
	signal OUTR : signed(15 downto 0);

begin

	EN <= ENABLE;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			LR <= '0';
			FIFO_DATA <= (others => '0');
			WR_REQ <= '0';
			CD_WR_OLD <= '0';
		elsif rising_edge(CLK) then
			WR_REQ <= '0';
			if EN = '1' then
				CD_WR_OLD <= CD_WR;
				if CD_WR = '1' and CD_WR_OLD = '0' then
					LR <= not LR;
					if LR = '0' then
						FIFO_DATA(15 downto 0) <= CD_DI;
					else
						FIFO_DATA(31 downto 16) <= CD_DI;
						if FULL = '0' and DM = '0' then
							WR_REQ <= '1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	FIFO : entity work.CDDA_FIFO 
	port map(
		clock		=> CLK,
		data		=> FIFO_DATA,
		wrreq		=> WR_REQ,
		full		=> FULL,
		
		rdreq		=> RD_REQ,
		empty		=> EMPTY,
		q			=> FIFO_Q
	);
	
	CEGen : entity work.CEGen
	port map(
		CLK   		=> CLK,
		RST_N       => RST_N,		
		IN_CLK   	=> 536900,
		OUT_CLK   	=> 441,
		CE   			=> SAMPLE_CE
	);
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			RD_REQ <= '0';
		elsif rising_edge(CLK) then
			RD_REQ <= '0';
			if EN = '1' and SAMPLE_CE = '1' then	-- ~44.1kHz
				if EMPTY = '0' then
					RD_REQ <= '1';
					OUTL <= signed(FIFO_Q(31 downto 16));
					OUTR <= signed(FIFO_Q(15 downto 0));
				else
					OUTL <= (others => '0');
					OUTR <= (others => '0');
				end if;
			end if;
		end if;
	end process;

	SL <= OUTL;
	SR <= OUTR;

end rtl;