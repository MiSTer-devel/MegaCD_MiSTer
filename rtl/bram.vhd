--------------------------------------------------------------
-- Single port Block RAM
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY spram IS
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := " ";
		mem_name      : string := "MEM" -- for InSystem Memory content editor.
	);
	PORT
	(
		clock   : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable  : in  STD_LOGIC := '1';
		wren    : in  STD_LOGIC := '0';
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END spram;


ARCHITECTURE SYN OF spram IS
BEGIN
	spram_sz : work.spram_sz
	generic map(addr_width, data_width, 2**addr_width, mem_init_file, mem_name)
	port map(clock,address,data,enable,wren,q,cs);
END SYN;


--------------------------------------------------------------
-- Single port Block RAM with specific size
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY spram_sz IS
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		numwords      : integer := 2**8;
		mem_init_file : string := " ";
		mem_name      : string := "MEM" -- for InSystem Memory content editor.
	);
	PORT
	(
		clock   : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable  : in  STD_LOGIC := '1';
		wren    : in  STD_LOGIC := '0';
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END ENTITY;

ARCHITECTURE SYN OF spram_sz IS
	signal q0 : std_logic_vector((data_width - 1) downto 0);
BEGIN
	q<= q0 when cs = '1' else (others => '1');

	altsyncram_component : altsyncram
	GENERIC MAP (
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME="&mem_name,
		lpm_type => "altsyncram",
		numwords_a => numwords,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		init_file => mem_init_file, 
		widthad_a => addr_width,
		width_a => data_width,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => address,
		clock0 => clock,
		data_a => data,
		wren_a => wren and cs,
		q_a => q0
	);

END SYN;

--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports (for VDP)
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity DualPortRAM is
	generic (
		addrbits    : integer := 8;
		databits    : integer := 8
	);
	PORT
	(
		clock			: in  STD_LOGIC;

		address_a	: in  STD_LOGIC_VECTOR (addrbits-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (databits-1 DOWNTO 0) := (others => '0');
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (databits-1 DOWNTO 0);

		address_b	: in  STD_LOGIC_VECTOR (addrbits-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (databits-1 DOWNTO 0) := (others => '0');
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (databits-1 DOWNTO 0)
	);
end entity;


ARCHITECTURE SYN OF DualPortRAM IS
BEGIN
	ram : work.dpram_dif generic map(addrbits,databits,addrbits,databits)
	port map(clock,address_a,data_a,'1',wren_a,q_a,'1',address_b,data_b,'1',wren_b,q_b,'1');
END SYN;

--------------------------------------------------------------
-- Dual port Block RAM with byte enable (for VDP)
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY obj_cache IS
	PORT
	(
		byteena_a	: IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END obj_cache;


ARCHITECTURE SYN OF obj_cache IS
BEGIN

	ram0: work.dpram_dif generic map(7,8,7,8)
	port map
	(
		clock, rdaddress, (others => '0'), '1', '0', q(7 downto 0), '1', wraddress, data(7 downto 0), '1', wren and byteena_a(0)
	);

	ram1: work.dpram_dif generic map(7,8,7,8)
	port map
	(
		clock, rdaddress, (others => '0'), '1', '0', q(15 downto 8), '1', wraddress, data(15 downto 8), '1', wren and byteena_a(1)
	);

	ram2: work.dpram_dif generic map(7,8,7,8)
	port map
	(
		clock, rdaddress, (others => '0'), '1', '0', q(23 downto 16), '1', wraddress, data(23 downto 16), '1', wren and byteena_a(2)
	);
	
	ram3: work.dpram_dif generic map(7,8,7,8)
	port map
	(
		clock, rdaddress, (others => '0'), '1', '0', q(31 downto 24), '1', wraddress, data(31 downto 24), '1', wren and byteena_a(3)
	);

END SYN;
 

--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity dpram is
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := " "
	);
	PORT
	(
		clock			: in  STD_LOGIC;

		address_a	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_a		: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_b		: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram IS
BEGIN
	ram : work.dpram_dif generic map(addr_width,data_width,addr_width,data_width,mem_init_file)
	port map(clock,address_a,data_a,enable_a,wren_a,q_a,cs_a,address_b,data_b,enable_b,wren_b,q_b,cs_b);
END SYN;

--------------------------------------------------------------
-- Dual port Block RAM different parameters on ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity dpram_dif is
	generic (
		addr_width_a  : integer := 8;
		data_width_a  : integer := 8;
		addr_width_b  : integer := 8;
		data_width_b  : integer := 8;
		mem_init_file : string := " "
	);
	PORT
	(
		clock			: in  STD_LOGIC;

		address_a	: in  STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
		enable_a		: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width_b-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0) := (others => '0');
		enable_b		: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram_dif IS

	signal q0 : std_logic_vector((data_width_a - 1) downto 0);
	signal q1 : std_logic_vector((data_width_b - 1) downto 0);

BEGIN
	q_a<= q0 when cs_a = '1' else (others => '1');
	q_b<= q1 when cs_b = '1' else (others => '1');

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_reg_b => "CLOCK1",
		clock_enable_input_a => "NORMAL",
		clock_enable_input_b => "NORMAL",
		clock_enable_output_a => "BYPASS",
		clock_enable_output_b => "BYPASS",
		indata_reg_b => "CLOCK1",
		intended_device_family => "Cyclone V",
		lpm_type => "altsyncram",
		numwords_a => 2**addr_width_a,
		numwords_b => 2**addr_width_b,
		operation_mode => "BIDIR_DUAL_PORT",
		outdata_aclr_a => "NONE",
		outdata_aclr_b => "NONE",
		outdata_reg_a => "UNREGISTERED",
		outdata_reg_b => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
		init_file => mem_init_file, 
		widthad_a => addr_width_a,
		widthad_b => addr_width_b,
		width_a => data_width_a,
		width_b => data_width_b,
		width_byteena_a => 1,
		width_byteena_b => 1,
		wrcontrol_wraddress_reg_b => "CLOCK1"
	)
	PORT MAP (
		address_a => address_a,
		address_b => address_b,
		clock0 => clock,
		clock1 => clock,
		clocken0 => enable_a,
		clocken1 => enable_b,
		data_a => data_a,
		data_b => data_b,
		wren_a => wren_a and cs_a,
		wren_b => wren_b and cs_b,
		q_a => q0,
		q_b => q1
	);

END SYN;

