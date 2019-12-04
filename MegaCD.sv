//============================================================================
//  FPGAGen port to MiSTer
//  Copyright (c) 2017-2019 Sorgelig
//
//  YM2612 implementation by Jose Tejada Gomez. Twitter: @topapate
//  Original Genesis code: Copyright (c) 2010-2013 Gregory Estrade (greg@torlus.com) 
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,
	
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..5 - USR1..USR4
	// Set USER_OUT to 1 to read from USER_IN.
	input   [5:0] USER_IN,
	output  [5:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign BUTTONS   = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

always_comb begin
	if (status[10]) begin
		VIDEO_ARX = 8'd16;
		VIDEO_ARY = 8'd9;
	end else begin
		case(res) // {V30, H40}
			2'b00: begin // 256 x 224
				VIDEO_ARX = 8'd64;
				VIDEO_ARY = 8'd49;
			end

			2'b01: begin // 320 x 224
				VIDEO_ARX = status[30] ? 8'd10: 8'd64;
				VIDEO_ARY = status[30] ? 8'd7 : 8'd49;
			end

			2'b10: begin // 256 x 240
				VIDEO_ARX = 8'd128;
				VIDEO_ARY = 8'd105;
			end

			2'b11: begin // 320 x 240
				VIDEO_ARX = status[30] ? 8'd4 : 8'd128;
				VIDEO_ARY = status[30] ? 8'd3 : 8'd105;
			end
		endcase
	end
end

//assign VIDEO_ARX = status[10] ? 8'd16 : ((status[30] && wide_ar) ? 8'd10 : 8'd64);
//assign VIDEO_ARY = status[10] ? 8'd9  : ((status[30] && wide_ar) ? 8'd7  : 8'd49);

assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

assign LED_POWER = {1'b1,MCD_LED_GREEN};
assign LED_DISK  = {1'b1,MCD_LED_RED};
assign LED_USER  = cart_download | sav_pending;


///////////////////////////////////////////////////
wire clk_sys, clk_ram, locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_ram),
	.outclk_1(clk_sys),
	.locked(locked)
);


`include "build_id.v"
localparam CONF_STR = {
	"MegaCD;;",
	"S0,CUE,Insert Disk;",
	"O2,Reset on insertion,Yes,No;",
	"-;",
	"F1,BINGENMD ,Load BIOS;",
	"O67,Region,JP,US,EU;",
	"-;",
//	"C,Cheats;",
//	"H1OO,Cheats Enabled,Yes,No;",
//	"-;",
//	"D0RG,Load Backup RAM;",
//	"D0RH,Save Backup RAM;",
//	"D0OD,Autosave,No,Yes;",
//	"-;",
	"OA,Aspect Ratio,4:3,16:9;",
	"OU,320x224 Aspect,Original,Corrected;",
	"o13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"OT,Border,No,Yes;",
	"O9,Composite Blending,Off,On;",
	"OV,Sprite Limit,Normal,High;",
	"-;",
	"OEF,Audio Filter,Model 1,Model 2,Minimal,No Filter;",
	"O8,FM Chip,YM2612,YM3438;",
	"ON,HiFi PCM,No,Yes;",
	"-;",
	"O4,Swap Joysticks,No,Yes;",
	"O5,6 Buttons Mode,No,Yes;",
	"OLM,Multitap,Disabled,4-Way,TeamPlayer,J-Cart;",
	"OIJ,Mouse,None,Port1,Port2;",
	"OK,Mouse Flip Y,No,Yes;",
	"-;",
	"H2OB,Enable FM,Yes,No;",//11
	"H2OC,Enable PSG,Yes,No;",//12
	"H2OP,Enable PCM,Yes,No;",//25
	"H2OQ,Enable CDDA,Yes,No;",//26
	"H2-;",
	//"R1,Reset;"
	"R0,Reset & Eject CD;",
	"J1,A,B,C,Start,Mode,X,Y,Z;",
	"jn,A,B,R,Start,Select,X,Y,L;", // name map to SNES layout.
	"jp,Y,B,A,Start,Select,L,X,R;", // positional map to SNES layout (3 button friendly)  
	"V,v",`BUILD_DATE
};


wire [15:0] status_menumask = {1'b1,~dbg_menu,1'b0,~bk_ena};
wire [63:0] status;
wire  [1:0] buttons;
wire [11:0] joystick_0,joystick_1,joystick_2,joystick_3;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_data;
wire  [7:0] ioctl_index;
//reg         ioctl_wait;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(new_vmode),

	.status(status),
	.status_in({status[63:8],region_req,status[5:0]}),
	.status_set(region_set),
	.status_menumask(status_menumask),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	//.ioctl_wait(ioctl_wait),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	
	.gamma_bus(gamma_bus),
	
	.cd_in(cd_in),
	.cd_out(cd_out),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse)
);

reg dbg_menu = 0;
always @(posedge clk_sys) begin
	reg old_stb;
	reg enter = 0;
	reg esc = 0;
	
	old_stb <= ps2_key[10];
	if(old_stb ^ ps2_key[10]) begin
		if(ps2_key[7:0] == 'h5A) enter <= ps2_key[9];
		if(ps2_key[7:0] == 'h76) esc   <= ps2_key[9];
	end
	
	if(enter & esc) begin
		dbg_menu <= ~dbg_menu;
		enter <= 0;
		esc <= 0;
	end
end

wire cart_download = ioctl_download & (ioctl_index[5:0] <= 6'h01);
wire cdc_dat_download = ioctl_download & (ioctl_index[5:0] == 6'h02);
wire cdc_sub_download = ioctl_download & (ioctl_index[5:0] == 6'h03);


wire reset = RESET | status[0] | buttons[1] | region_set | bk_loading;

//Genesis
wire [23:1] GEN_VA;
wire [15:0] GEN_VDI, GEN_VDO;
wire        GEN_RNW, GEN_LDS_N, GEN_UDS_N;
wire        GEN_AS_N, GEN_DTACK_N, GEN_ASEL_N;
wire        GEN_RAS2_N;
wire        EXT_ROM_N;
wire        EXT_FDC_N;
wire        GEN_VCLK_CE;
wire        GEN_WRL_N, GEN_WRH_N, GEN_OE_N;
wire        GEN_ROM_CE_N;
wire        GEN_RAM_CE_N;

wire [15:0] GEN_MEM_DO;
wire        GEN_MEM_BUSY;

wire [7:0] color_lut[16] = '{
	8'd0,   8'd27,  8'd49,  8'd71,
	8'd87,  8'd103, 8'd119, 8'd130,
	8'd146, 8'd157, 8'd174, 8'd190,
	8'd206, 8'd228, 8'd255, 8'd255
};

wire [3:0] r, g, b;
wire vs,hs;
wire ce_pix;
wire hblank, vblank;
wire interlace;
wire [1:0] resolution;

wire EN_GEN_FM   = ~status[11] | ~dbg_menu;
wire EN_GEN_PSG  = ~status[12] | ~dbg_menu;
wire EN_MCD_PCM  = ~status[25] | ~dbg_menu;
wire EN_MCD_CDDA = ~status[26] | ~dbg_menu;

gen gen
(
	.RESET_N(~reset),
	.MCLK(clk_sys),
	
	.VA(GEN_VA),
	.VDI(GEN_VDI),
	.VDO(GEN_VDO),
	.RNW(GEN_RNW),
	.LDS_N(GEN_LDS_N),
	.UDS_N(GEN_UDS_N),
	.AS_N(GEN_AS_N),
	.DTACK_N(GEN_DTACK_N),
	.ASEL_N(GEN_ASEL_N),
	.VCLK_CE(GEN_VCLK_CE),
	.RAS2_N(GEN_RAS2_N),
	.ROM_N(EXT_ROM_N),
	.FDC_N(EXT_FDC_N),
	.DISK_N(0),
	.WRL_N(GEN_WRL_N),
	.WRH_N(GEN_WRH_N),
	.OE_N(GEN_OE_N),
	
	.EXT_SL(MCD_SL),
	.EXT_SR(MCD_SR),

	.LOADING(cart_download),
	.EXPORT(|status[7:6]),
	.PAL(PAL),

	.DAC_LDATA(AUDIO_L),
	.DAC_RDATA(AUDIO_R),

	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.VS(vs),
	.HS(hs),
	.HBL(hblank),
	.VBL(vblank),
	.BORDER(status[29]),
	.CE_PIX(ce_pix),
	.FIELD(VGA_F1),
	.INTERLACE(interlace),
	.RESOLUTION(resolution),

	.J3BUT(~status[5]),
	.JOY_1(status[4] ? joystick_1 : joystick_0),
	.JOY_2(status[4] ? joystick_0 : joystick_1),
	.JOY_3(joystick_2),
	.JOY_4(joystick_3),
	.MULTITAP(status[22:21]),

	.MOUSE(ps2_mouse),
	.MOUSE_OPT(status[20:18]),

	.ENABLE_FM(EN_GEN_FM),
	.ENABLE_PSG(EN_GEN_PSG),
	.EN_HIFI_PCM(status[23]), // Option "N"
	.LADDER(~status[8]),
	.LPF_MODE(status[15:14]),

	.OBJ_LIMIT_HIGH(status[31]),

	.RAM_CE_N(GEN_RAM_CE_N),
	.RAM_RDY(~GEN_MEM_BUSY)
	
);

assign GEN_VDI = !GEN_RAM_CE_N ? GEN_MEM_DO_R :
					  MCD_DO;

reg [15:0] GEN_MEM_DO_R;
always @(posedge clk_sys) begin
	reg old_bsy;
	
	old_bsy <= GEN_MEM_BUSY;
	if(old_bsy & ~GEN_MEM_BUSY) GEN_MEM_DO_R <= GEN_MEM_DO;
end

// MCD
wire [15:0] MCD_DO;

wire [15:0] MCD_PCM_SL;
wire [15:0] MCD_PCM_SR;
wire [15:0] MCD_CDDA_SL;
wire [15:0] MCD_CDDA_SR;

wire [17:0] MCD_PRG_ADDR;
wire [15:0] MCD_PRG_DO;
wire [15:0] MCD_PRG_DI;
wire        MCD_PRG_OE_N;
wire        MCD_PRG_WRL_N;
wire        MCD_PRG_WRH_N;
wire        MCD_PRG_RFS;
wire        MCD_PRG_BUSY;

wire [13:1] MCD_BRAM_ADDR;
wire  [7:0] MCD_BRAM_DO;
wire  [7:0] MCD_BRAM_DI;
wire        MCD_BRAM_WE;

wire        MCD_LED_RED;
wire        MCD_LED_GREEN;

MCD MCD
(
	.RST_N(~reset),
	.CLK(clk_sys),
	.ENABLE(1),

	.EXT_VA(GEN_VA[17:1]),
	.EXT_VDI(GEN_VDO),
	.EXT_VDO(MCD_DO),
	.EXT_AS_N(GEN_AS_N),
	.EXT_RNW(GEN_RNW),
	.EXT_LDS_N(GEN_LDS_N),
	.EXT_UDS_N(GEN_UDS_N),
	.EXT_DTACK_N(GEN_DTACK_N),
	.EXT_ASEL_N(GEN_ASEL_N),
	.EXT_VCLK_CE(GEN_VCLK_CE),
	.EXT_RAS2_N(GEN_RAS2_N),
	.EXT_ROM_N(EXT_ROM_N),
	.EXT_FDC_N(EXT_FDC_N),

	.PRG_A(MCD_PRG_ADDR),
	.PRG_DI(MCD_PRG_DI),
	.PRG_DO(MCD_PRG_DO),
	.PRG_WRL_N(MCD_PRG_WRL_N),
	.PRG_WRH_N(MCD_PRG_WRH_N),
	.PRG_OE_N(MCD_PRG_OE_N),
	.PRG_RFS(MCD_PRG_RFS),
	.PRG_RDY(~MCD_PRG_BUSY),
	
	.ROM_DI(GEN_MEM_DO),
	.ROM_CE_N(GEN_ROM_CE_N),
	.ROM_RDY(~GEN_MEM_BUSY),
	
	.BRAM_A(MCD_BRAM_ADDR),
	.BRAM_DI(MCD_BRAM_DI),
	.BRAM_DO(MCD_BRAM_DO),
	.BRAM_WE(MCD_BRAM_WE),
	
	.CDD_STAT(scd_cdd_stat),
	.CDD_COMM(scd_cdd_comm),
	.CDD_SEND(scd_cdd_send),
	.CDD_REC(scd_cdd_rec),
	.CDD_DM(scd_cdd_dm),
	
	.CDC_DATA(cdc_d),
	.CDC_DAT_WR(cdc_wr & cdc_dat_download),
	.CDC_SC_WR(cdc_wr & cdc_sub_download),

	.PCM_SL(MCD_PCM_SL),
	.PCM_SR(MCD_PCM_SR),
	.CDDA_SL(MCD_CDDA_SL),
	.CDDA_SR(MCD_CDDA_SR),
	
	.LED_RED(MCD_LED_RED),
	.LED_GREEN(MCD_LED_GREEN)
);

wire [15:0] MCD_SL;
wire [15:0] MCD_SR;

SND_MIX mcd_mix
(
	.CH0_R(MCD_PCM_SR),
	.CH0_L(MCD_PCM_SL),
	.CH0_EN(EN_MCD_PCM),
	
	.CH1_R(MCD_CDDA_SR),
	.CH1_L(MCD_CDDA_SL),
	.CH1_EN(EN_MCD_CDDA),
	
	.OUT_R(MCD_SR),
	.OUT_L(MCD_SL)
);

//MCD PRGRAM, GEN ROM/RAM
sdram sdram
(
	.*,
	.init(~locked),
	.clk(clk_ram),
	
	.addr0({2'b00,MCD_PRG_ADDR}),
	.din0(MCD_PRG_DO),
	.dout0(MCD_PRG_DI),
	.rd0(~MCD_PRG_OE_N),
	.wrl0(~MCD_PRG_WRL_N),
	.wrh0(~MCD_PRG_WRH_N),
	.rfs0(MCD_PRG_RFS),
	.busy0(MCD_PRG_BUSY),
	
	.addr1(cart_download ? {4'b0000,ioctl_addr[16:1]} : (!GEN_RAM_CE_N ? {5'b10000,GEN_VA[15:1]} : {4'b0000,GEN_VA[16:1]}) ),
	.din1(cart_download ? {ioctl_data[7:0],ioctl_data[15:8]} : GEN_VDO),
	.dout1(GEN_MEM_DO),
	.rd1(cart_download ? 1'b0 : (~GEN_RAM_CE_N | ~GEN_ROM_CE_N) & ~GEN_OE_N),
	.wrl1(cart_download ? ioctl_wr : ~GEN_RAM_CE_N & ~GEN_WRL_N),
	.wrh1(cart_download ? ioctl_wr : ~GEN_RAM_CE_N & ~GEN_WRH_N),
	.rfs1(0),
	.busy1(GEN_MEM_BUSY),
	
	.addr2(0),
	.din2(0),
	.dout2(),
	.rd2(0),
	.wrl2(0),
	.wrh2(0),
	.rfs2(0),
	.busy2()
);

dpram #(13,8,"bram.mif") bram
(
	.clock(clk_sys),
	.address_a(MCD_BRAM_ADDR),
	.data_a(MCD_BRAM_DO),
	.wren_a(MCD_BRAM_WE),
	.q_a(MCD_BRAM_DI),

	.address_b(0),
	.wren_b(0),
	.q_b()
);

//DDR3
//wire [24:1] rom_addr;
//wire [15:0] rom_data;
//wire rom_rd, rom_rdack, rom_wrack; 
//reg  rom_wr;
//
//ddram ddram
//(
//	.*,
//	
//	.wraddr(cart_download ? ioctl_addr : rom_sz),
//	.din({ioctl_data[7:0],ioctl_data[15:8]}),
//	.we_req(rom_wr),
//	.we_ack(rom_wrack),
//	
//	.rdaddr(rom_addr),
//	.dout(rom_data),
//	.rd_req(rom_rd),
//	.rd_ack(rom_rdack),
//	
//	.rdaddr2(0),
//	.dout2(),
//	.rd_req2(0),
//	.rd_ack2() 
//);
//assign DDRAM_CLK = clk_ram;

//reg [24:0] rom_sz;
//always @(posedge clk_sys) begin
//	reg old_download, old_reset;
//	old_download <= cart_download;
//	old_reset <= reset;
//
//	if(~old_reset && reset) ioctl_wait <= 0;
//	if (old_download & ~cart_download) begin
//		rom_sz <= ioctl_addr[24:0];
//		ioctl_wait <= 0;
//	end
//
//	if(~old_download && cart_download)
//		rom_wr <= 0;
//	else if (cart_download) begin
//		if(ioctl_wr) begin
//			ioctl_wait <= 1;
//			rom_wr <= ~rom_wr;
//		end else if(ioctl_wait && (rom_wr == rom_wrack)) begin
//			ioctl_wait <= 0;
//		end
//	end
//end

//CD communication
reg [48:0] cd_in;
wire [48:0] cd_out;

reg [39:0] scd_cdd_stat;
reg scd_cdd_dm;
wire [39:0] scd_cdd_comm;
wire scd_cdd_send;
reg scd_cdd_rec;

always @(posedge clk_sys) begin
	reg cd_out48_last = 1;
	reg scd_cdd_send_old = 0;
	reg [2:0] cnt = 0;
	
	if (cd_out[48] != cd_out48_last)  begin
		cd_out48_last <= cd_out[48];
		scd_cdd_stat <= cd_out[39:0];
		scd_cdd_dm <= cd_out[40];
		scd_cdd_rec <= 1;
		cnt <= 7;
	end
	else if (cnt) begin
		cnt <= cnt - 1'd1;
	end
	else begin
		scd_cdd_rec <= 0;
	end
	
	scd_cdd_send_old <= scd_cdd_send;
	if (scd_cdd_send && !scd_cdd_send_old) begin
		cd_in[47:0] <= {8'h00,scd_cdd_comm};
		cd_in[48] <= ~cd_in[48];
	end
end


//extend cdc_wr for 8 cycles
reg  cdc_wr;
reg [15:0] cdc_d;
always @(posedge clk_sys) begin
	reg [2:0] cnt = 0;

	if (ioctl_wr) begin
		cnt <= 7;
		cdc_wr <= 1;
		cdc_d <= ioctl_data;
	end
	else if (cnt) begin
		cnt <= cnt - 1'd1;
	end
	else begin
		cdc_wr <= 0;
	end
end


/////////////////////////////////////////////////////////////
wire PAL = status[7];

reg new_vmode;
always @(posedge clk_sys) begin
	reg old_pal;
	int to;
	
	if(~(reset | cart_download)) begin
		old_pal <= PAL;
		if(old_pal != PAL) to <= 5000000;
	end
	else to <= 5000000;
	
	if(to) begin
		to <= to - 1;
		if(to == 1) new_vmode <= ~new_vmode;
	end
end

//lock resolution for the whole frame.
reg [1:0] res;
always @(posedge clk_sys) begin
	reg old_vbl;
	
	old_vbl <= vblank;
	if(old_vbl & ~vblank) res <= resolution;
end

wire [2:0] scale = status[35:33];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign CLK_VIDEO = clk_ram;
assign VGA_SL = {~interlace,~interlace}&sl[1:0];

reg old_ce_pix;
always @(posedge CLK_VIDEO) old_ce_pix <= ce_pix;

wire [7:0] red, green, blue;

cofi coffee (
	.clk(clk_sys),
	.pix_ce(ce_pix),
	.enable(status[9]),

	.hblank(hblank),
	.vblank(vblank),
	.hs(hs),
	.vs(vs),
	.red(color_lut[r]),
	.green(color_lut[g]),
	.blue(color_lut[b]),

	.hblank_out(hblank_c),
	.vblank_out(vblank_c),
	.hs_out(hs_c),
	.vs_out(vs_c),
	.red_out(red),
	.green_out(green),
	.blue_out(blue)
);

wire hs_c,vs_c,hblank_c,vblank_c;

video_mixer #(.LINE_LENGTH(320), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,

	.clk_vid(CLK_VIDEO),
	.ce_pix(~old_ce_pix & ce_pix),
	.ce_pix_out(CE_PIXEL),

	.scanlines(0),
	.scandoubler(~interlace && (scale || forced_scandoubler)),
	.hq2x(scale==1),

	.mono(0),

	.R(red),
	.G(green),
	.B(blue),

	// Positive pulses.
	.HSync(hs_c),
	.VSync(vs_c),
	.HBlank(hblank_c),
	.VBlank(vblank_c)
);


reg  [1:0] region_req;
reg        region_set = 0;

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state, old_ready = 0;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		casex(code)
			'h005: begin region_req <= 0; region_set <= pressed; end // F1
			'h006: begin region_req <= 1; region_set <= pressed; end // F2
			'h004: begin region_req <= 2; region_set <= pressed; end // F3
		endcase
	end

	old_ready <= cart_hdr_ready;
	if(~old_ready & cart_hdr_ready) begin
		region_set <= 1;
		if(hdr_u) region_req <= 1;
		else if(hdr_j) region_req <= 0;
		else region_req <= 2;
	end

	if(old_ready & ~cart_hdr_ready) region_set <= 0;
end

reg cart_hdr_ready = 0;
reg hdr_j=0,hdr_u=0;
always @(posedge clk_sys) begin
	reg old_download;
	old_download <= cart_download;

	if(~old_download && cart_download) {hdr_j,hdr_u,cart_hdr_ready} <= 0;
	if(old_download && ~cart_download) cart_hdr_ready <= 0;

	if(ioctl_wr & cart_download) begin
		if(ioctl_addr == 'h1F0) begin
			if(ioctl_data[7:0] == "J") hdr_j <= 1;
			else if(ioctl_data[7:0] == "U") hdr_u <= 1;
			cart_hdr_ready <= 1;
		end
	end
end


/////////////////////////  BRAM SAVE/LOAD  /////////////////////////////

wire downloading = cart_download;

reg bk_ena = 0;
reg sav_pending = 0;
wire bk_change = 0;

always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_change = 0;

	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;

	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly) bk_ena <= 1;

	old_change <= bk_change;
	if (~old_change & bk_change & ~OSD_STATUS) sav_pending <= status[13];
	else if (bk_state) sav_pending <= 0;
end

wire bk_load    = status[16];
wire bk_save    = status[17] | (sav_pending & OSD_STATUS);
reg  bk_loading = 0;
reg  bk_state   = 0;

always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_load = 0, old_save = 0, old_ack;

	old_downloading <= downloading;

	old_load <= bk_load;
	old_save <= bk_save;
	old_ack  <= sd_ack;

	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

	if(!bk_state) begin
		if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			sd_lba <= 0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~cart_download & |img_size & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_lba <= 0;
			sd_rd <= 1;
			sd_wr <= 0;
		end
	end else begin
		if(old_ack & ~sd_ack) begin
			if(&sd_lba[6:0]) begin
				bk_loading <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_loading;
				sd_wr  <= ~bk_loading;
			end
		end
	end
end


endmodule
