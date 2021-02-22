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
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

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

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
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
`endif

`ifdef USE_SDRAM
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
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign BUTTONS   = {bk_reload, 1'b0};
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign LED_DISK  = {1'b1,MCD_LED_RED};
assign LED_POWER = {1'b1,MCD_LED_GREEN};
assign LED_USER  = rom_download | sav_pending;

assign VGA_SCALER= 0;

assign AUDIO_S   = 1;
assign AUDIO_MIX = 0;
wire [1:0] ar = status[50:49];
wire [7:0] arx,ary;

always_comb begin
	case(res) // {V30, H40}
		2'b00: begin // 256 x 224
			arx = 8'd64;
			ary = 8'd49;
		end

		2'b01: begin // 320 x 224
			arx = status[30] ? 8'd10: 8'd64;
			ary = status[30] ? 8'd7 : 8'd49;
		end

		2'b10: begin // 256 x 240
			arx = 8'd128;
			ary = 8'd105;
		end

		2'b11: begin // 320 x 240
			arx = status[30] ? 8'd4 : 8'd128;
			ary = status[30] ? 8'd3 : 8'd105;
		end
	endcase
end

wire       vcrop_en = status[32];
wire [3:0] vcopt    = status[54:51];
reg        en216p;
reg  [4:0] voff;
always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
	voff <= (vcopt < 6) ? {vcopt,1'b0} : ({vcopt,1'b0} - 5'd24);
end

wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? arx : (ar - 1'd1)),
	.ARY((!ar) ? ary : 12'd0),
	.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
	.CROP_OFF(voff),
	.SCALE(status[56:55])
);

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

// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXXXXX  XXXXXXXXXXXXXXXXX XXX XXXXXXXXXXXXXXXXXXXXXXXXX

`include "build_id.v"
localparam CONF_STR = {
	"MegaCD;;",
	"S0,CUE,Insert Disk;",
	"-;",
	"h6O67,Region,Auto(JP),JP,US,EU;",
	"h7O67,Region,Auto(US),JP,US,EU;",
	"h8O67,Region,Auto(EU),JP,US,EU;",
	"-;",
	"C,Cheats;",
	"H5OO,Cheats Enabled,Yes,No;",
	"-;",
	"O3,Backup RAM,Internal,Internal+Cart;",
	"D0RG,Reload Backup RAM;",
	"D0RH,Save Backup RAM;",
	"D0OD,Autosave,No,Yes;",
	"-;",

	"P1,Audio & Video;",
	"P1-;",
	"P1oHI,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1OU,320x224 Aspect,Original,Corrected;",
	"P1o13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1-;",
	"d9P1o0,Vertical Crop,Disabled,216p(5x);",
	"d9P1oJM,Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
	"P1oNO,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1- ;",
	"P1OT,Border,No,Yes;",
	"P1oFG,Composite Blend,Off,On,Adaptive;",
	"P1OV,Sprite Limit,Normal,High;",
	"P1-;",
	"P1OEF,Audio Filter,Model 1,Model 2,Minimal,No Filter;",
	"P1OR,CD Audio,Unfiltered,Filtered;",
	"P1O8,FM Chip,YM2612,YM3438;",
	"P1ON,HiFi PCM,No,Yes;",

	"P2,Input;",
	"P2-;",
	"P2O4,Swap Joysticks,No,Yes;",
	"P2O5,6 Buttons Mode,No,Yes;",
	"P2OLM,Multitap,Disabled,4-Way,TeamPlayer: Port1,TeamPlayer: Port2;",
	"P2-;",
	"P2OIJ,Mouse,None,Port1,Port2;",
	"P2OK,Mouse Flip Y,No,Yes;",
	"P2-;",
	"P2o89,Gun Control,Disabled,Joy1,Joy2,Mouse;",
	"D4P2oA,Gun Fire,Joy,Mouse;",
	"D4P2oBC,Cross,Small,Medium,Big,None;",
	"D4P2oD,Gun Type,Justifier,Menacer;",
	"P2-;",
	"P2oE,Serial,OFF,SNAC;",

	"-;",
	"H2OB,Enable FM,Yes,No;",//11
	"H2OC,Enable PSG,Yes,No;",//12
	"H2OP,Enable PCM,Yes,No;",//25
	"H2OQ,Enable CDDA,Yes,No;",//26
	"H2o4,Enable BGA,Yes,No;",//36
	"H2o5,Enable BGB,Yes,No;",//37
	"H2o6,Enable SPR,Yes,No;",//38
	"H2o7,MCD RAM,Banks 2&3,Banks 0&1;",//39
	"H2-;",
	//"R1,Reset;"
	"R0,Reset & Eject CD;",
	"J1,A,B,C,Start,Mode,X,Y,Z;",
	"jn,A,B,R,Start,Select,X,Y,L;", // name map to SNES layout.
	"jp,Y,B,A,Start,Select,L,X,R;", // positional map to SNES layout (3 button friendly)  
	"V,v",`BUILD_DATE
};


wire [15:0] status_menumask = {en216p,region,!region,~gg_available,!gun_mode,1'b1,~dbg_menu,1'b0,~bk_ena};
wire [63:0] status;
wire  [1:0] buttons;
wire [11:0] joystick_0,joystick_1,joystick_2,joystick_3,joystick_4;
wire  [7:0] joy0_x,joy0_y,joy1_x,joy1_y;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_data;
wire  [7:0] ioctl_index;
reg         ioctl_wait;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din = sd_lba[10:4] ? tmpram_sd_buff_data : bram_sd_buff_data;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire [21:0] gamma_bus;

wire [1:0] gun_mode = status[41:40];
wire       gun_btn_mode = status[42];
wire       gun_type = ~status[45];

hps_io #(.STRLEN($size(CONF_STR)>>3), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	.joystick_4(joystick_4),
	.joystick_analog_0({joy0_y, joy0_x}),
	.joystick_analog_1({joy1_y, joy1_x}),
	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(new_vmode),

	.status(status),
	.status_in({status[63:8],2'b00,status[5:0]}),
	.status_set(region_reset),
	.status_menumask(status_menumask),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	.ioctl_wait(ioctl_wait),

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
	
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.EXT_BUS(EXT_BUS)
);

wire [35:0] EXT_BUS;
hps_ext hps_ext
(
	.clk_sys(clk_sys),
	.EXT_BUS(EXT_BUS),
	.cd_in(cd_in),
	.cd_out(cd_out)
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

wire rom_download = ioctl_download & (ioctl_index[5:0] <= 6'h01);
wire cdc_dat_download = ioctl_download & (ioctl_index[5:0] == 6'h02);
wire cdc_sub_download = ioctl_download & (ioctl_index[5:0] == 6'h03);
wire save_download = ioctl_download & (ioctl_index[5:0] == 6'h05);
wire code_download = ioctl_download & &ioctl_index;

wire reset = RESET | status[0] | buttons[1] | region_set;

///////////////////////////////////////////////////
// Code loading for WIDE IO (16 bit)
reg [128:0] gg_code;
wire        gg_available = gg_available1 | gg_available2;

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

always_ff @(posedge clk_sys) begin
	gg_code[128] <= 0;

	if (code_download & ioctl_wr) begin
		case (ioctl_addr[3:0])
			0:  gg_code[111:96]  <= ioctl_data; // Flags Bottom Word
			2:  gg_code[127:112] <= ioctl_data; // Flags Top Word
			4:  gg_code[79:64]   <= ioctl_data; // Address Bottom Word
			6:  gg_code[95:80]   <= ioctl_data; // Address Top Word
			8:  gg_code[47:32]   <= ioctl_data; // Compare Bottom Word
			10: gg_code[63:48]   <= ioctl_data; // Compare top Word
			12: gg_code[15:0]    <= ioctl_data; // Replace Bottom Word
			14: begin
				 gg_code[31:16]   <= ioctl_data; // Replace Top Word
				 gg_code[128]     <= 1;      // Clock it in
			end
		endcase
	end
end


//Genesis
wire [23:1] GEN_VA;
wire [15:0] GEN_VDI, GEN_VDO;
wire        GEN_RNW, GEN_LDS_N, GEN_UDS_N;
wire        GEN_AS_N, GEN_DTACK_N, GEN_ASEL_N;
wire        GEN_RAS2_N;
wire        EXT_ROM_N;
wire        EXT_FDC_N;
wire        GEN_VCLK_CE;
wire        GEN_CE0_N;
wire        GEN_WRL_N, GEN_WRH_N, GEN_OE_N;
wire        GEN_ROM_CE_N;
wire        GEN_RAM_CE_N;
wire        GEN_PAGE_CE_N;

wire [15:0] GEN_MEM_DO;
wire        GEN_MEM_BUSY;

wire [15:0] GEN_AUDL;
wire [15:0] GEN_AUDR;

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
wire EN_VDP_BGA  = ~status[36] | ~dbg_menu;
wire EN_VDP_BGB  = ~status[37] | ~dbg_menu;
wire EN_VDP_SPR  = ~status[38] | ~dbg_menu;
wire MCD_BANK23  = ~status[39] | ~dbg_menu;

wire gg_available1;

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
	.CE0_N(GEN_CE0_N),
	.RAS2_N(GEN_RAS2_N),
	.ROM_N(EXT_ROM_N),
	.FDC_N(EXT_FDC_N),
	.CART_N(CART_CART_N),
	.DISK_N(0),
	.WRL_N(GEN_WRL_N),
	.WRH_N(GEN_WRH_N),
	.OE_N(GEN_OE_N),
	
	.TIME_N(GEN_PAGE_CE_N),
	.TIME_DI(GEN_PAGE_DI),

	.LOADING(rom_download),
	.EXPORT(|region),
	.PAL(PAL),

	.EXT_SL(mcd_l),
	.EXT_SR(mcd_r),
	.EXT_EN(status[27]),

	.DAC_LDATA(GEN_AUDL),
	.DAC_RDATA(GEN_AUDR),

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
	.EN_BGA(EN_VDP_BGA),
	.EN_BGB(EN_VDP_BGB),
	.EN_SPR(EN_VDP_SPR),

	.J3BUT(~status[5]),
	.JOY_1(status[4] ^ status[46] ? joystick_1 : joystick_0),
	.JOY_2(status[4] ^ status[46] ? joystick_0 : joystick_1),
	.JOY_3(joystick_2),
	.JOY_4(joystick_3),
	.JOY_5(joystick_4),
	.MULTITAP(status[22:21]),

	.MOUSE(ps2_mouse),
	.MOUSE_OPT(status[20:18]),

	.GUN_OPT(|gun_mode),
	.GUN_TYPE(gun_type),
	.GUN_SENSOR(lg_sensor),
	.GUN_A(lg_a),
	.GUN_B(lg_b),
	.GUN_C(lg_c),
	.GUN_START(lg_start),

	.SERJOYSTICK_IN(SERJOYSTICK_IN),
	.SERJOYSTICK_OUT(SERJOYSTICK_OUT),
	.SER_OPT(SER_OPT),

	.ENABLE_FM(EN_GEN_FM),
	.ENABLE_PSG(EN_GEN_PSG),
	.EN_HIFI_PCM(status[23]), // Option "N"
	.LADDER(~status[8]),
	.LPF_MODE(status[15:14]),

	.OBJ_LIMIT_HIGH(status[31]),

	.RAM_CE_N(GEN_RAM_CE_N),
	.RAM_RDY(~GEN_MEM_BUSY),

	.TRANSP_DETECT(TRANSP_DETECT),

	.GG_RESET(code_download && ioctl_wr && !ioctl_addr),
	.GG_EN(status[24]),
	.GG_CODE({~gg_code[95] & gg_code[128], gg_code[127:0]}),
	.GG_AVAILABLE(gg_available1)
);

wire TRANSP_DETECT;
wire cofi_enable = status[47] || (status[48] && TRANSP_DETECT);

assign GEN_VDI = !GEN_RAM_CE_N ? GEN_MEM_DO_R :
					  !CART_DTACK_N ? CART_DO :
					  MCD_DO;
assign GEN_DTACK_N = MCD_DTACK_N & CART_DTACK_N;

reg [15:0] GEN_MEM_DO_R;
always @(posedge clk_sys) begin
	reg old_bsy;
	
	old_bsy <= GEN_MEM_BUSY;
	if(old_bsy & ~GEN_MEM_BUSY) GEN_MEM_DO_R <= GEN_MEM_DO;
end

// MCD
wire [15:0] MCD_DO;
wire        MCD_DTACK_N;

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
wire        MCD_PRG_BUSY;

wire [13:1] MCD_BRAM_ADDR;
wire  [7:0] MCD_BRAM_DO;
wire  [7:0] MCD_BRAM_DI;
wire        MCD_BRAM_WE;

wire        MCD_LED_RED;
wire        MCD_LED_GREEN;

wire        MCD_RST_N;

wire        gg_available2;

MCD MCD
(
	.RST_N(~(reset|rom_download)),
	.CLK(clk_sys),
	.ENABLE(1),
	.MCD_RST_N(MCD_RST_N),

	.EXT_VA(GEN_VA[17:1]),
	.EXT_VDI(GEN_VDO),
	.EXT_VDO(MCD_DO),
	.EXT_AS_N(GEN_AS_N),
	.EXT_RNW(GEN_RNW),
	.EXT_LDS_N(GEN_LDS_N),
	.EXT_UDS_N(GEN_UDS_N),
	.EXT_DTACK_N(MCD_DTACK_N),
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
	.LED_GREEN(MCD_LED_GREEN),

	.GG_RESET(code_download && ioctl_wr && !ioctl_addr),
	.GG_EN(status[24]),
	.GG_CODE({gg_code[95] & gg_code[128], gg_code[127:0]}),
	.GG_AVAILABLE(gg_available2)
);

reg [15:0] aud_l, aud_r;
reg [15:0] mcd_l, mcd_r;
always @(posedge clk_sys) begin
	mcd_l <= ({16{EN_MCD_PCM}} & {MCD_PCM_SL[15],MCD_PCM_SL[15:1]}) + ({16{EN_MCD_CDDA}} & {MCD_CDDA_SL[15],MCD_CDDA_SL[15:1]});
	mcd_r <= ({16{EN_MCD_PCM}} & {MCD_PCM_SR[15],MCD_PCM_SR[15:1]}) + ({16{EN_MCD_CDDA}} & {MCD_CDDA_SR[15],MCD_CDDA_SR[15:1]});

	if(~status[27]) begin
		aud_l <= {GEN_AUDL[15],GEN_AUDL[15:1]} + {mcd_l[15],mcd_l[15:1]};
		aud_r <= {GEN_AUDR[15],GEN_AUDR[15:1]} + {mcd_r[15],mcd_r[15:1]};
	end
	else begin
		aud_l <= GEN_AUDL;
		aud_r <= GEN_AUDR;
	end
end

assign AUDIO_L = aud_l;
assign AUDIO_R = aud_r;


//ROM/RAM Cart
wire [15:0] CART_DO;
wire        CART_DTACK_N;
wire        CART_CART_N;

wire        CART_ROM_CE_N;
wire        CART_RAM_CE_N;

wire [15:0] CART_ROM_DO;
wire        CART_ROM_BUSY;

wire        CART_EN = status[3];

CART CART
(
	.RST_N(~reset),
	.CLK(clk_sys),
	.ENABLE(1),
	
	.ROM_MODE(rom_cart_mode),
	.RAM_ID(CART_EN ? 8'd6 : 8'd255),	//backup ram size = (1<<n)*8192, n=0..6, when n=255 ram is not present

	.VA(GEN_VA),
	.VDI(GEN_VDO),
	.VDO(CART_DO),
	.AS_N(GEN_AS_N),
	.RNW(GEN_RNW),
	.LDS_N(GEN_LDS_N),
	.UDS_N(GEN_UDS_N),
	.DTACK_N(CART_DTACK_N),
	.ASEL_N(GEN_ASEL_N),
	.VCLK_CE(GEN_VCLK_CE),
	.CE0_N(GEN_CE0_N),
	.CART_N(CART_CART_N),
	
	.ROM_CE_N(CART_ROM_CE_N),
	.ROM_DI(PIER_HOOK ? PIER_DATA : GEN_MEM_DO),
	.ROM_RDY(~GEN_MEM_BUSY),
	
	.RAM_CE_N(CART_RAM_CE_N),
	.RAM_DI(GEN_MEM_DO),
	.RAM_RDY(~GEN_MEM_BUSY)
);

always @(posedge clk_sys) begin
	reg old_busy;
	
	old_busy <= tmpram_busy;
	if(rom_download & ioctl_wr) ioctl_wait <= 1;
	if(old_busy & ~tmpram_busy) ioctl_wait <= 0;
end

wire use_sdr = 1;

assign MCD_PRG_BUSY = use_sdr ? sdr_busy : ddr_busy;
assign MCD_PRG_DI   = use_sdr ? sdr_do   : ddr_do;

wire ddr_busy;
wire [15:0] ddr_do;
assign DDRAM_CLK = clk_ram & ~use_sdr;
ddram ddram
(
	.*,

	.cache_rst(reset),

	.mem_addr(MCD_PRG_ADDR),
	.mem_dout(ddr_do),
	.mem_din(MCD_PRG_DO),
	.mem_rd(~use_sdr & ~MCD_PRG_OE_N),
	.mem_wrl(~use_sdr & ~MCD_PRG_WRL_N),
	.mem_wrh(~use_sdr & ~MCD_PRG_WRH_N),
	.mem_busy(ddr_busy)
);


//MCD PRGRAM, GEN ROM/RAM/CART RAM
wire sdr_busy;
wire [15:0] sdr_do;
sdram sdram
(
	.*,
	.init(~locked),
	.clk(clk_ram),

	//MCD: banks 2,3
	.addr0({(MCD_BANK23 ? 6'b100000 : 6'b011111),MCD_PRG_ADDR}), // 1000000-107FFFF / 0F80000-0FFFFFF
	.din0(MCD_PRG_DO),
	.dout0(sdr_do),
	.rd0(use_sdr & ~MCD_PRG_OE_N),
	.wrl0(use_sdr & ~MCD_PRG_WRL_N),
	.wrh0(use_sdr & ~MCD_PRG_WRH_N),
	.busy0(sdr_busy),

	//Genesis: banks 0,1
	.addr1(!GEN_RAM_CE_N  ? {9'b010000000,GEN_VA[15:1]} : //WORK RAM 800000-80FFFF
			 !CART_RAM_CE_N ? {5'b01110,GEN_VA[19:1]}     : //CART RAM E00000-EFFFFF
			 !CART_ROM_CE_N ? {2'b00,ROM_VA[22:1]}        : //CART ROM 000000-7FFFFF
			                  {8'b01111000,GEN_VA[16:1]} ),	//BIOS ROM F00000-F1FFFF
	.din1(GEN_VDO),
	.dout1(GEN_MEM_DO),
	.rd1((~GEN_RAM_CE_N | ~GEN_ROM_CE_N | ~CART_RAM_CE_N | ~CART_ROM_CE_N) & ~GEN_OE_N),
	.wrl1((~GEN_RAM_CE_N | ~CART_RAM_CE_N) & ~GEN_WRL_N),
	.wrh1((~GEN_RAM_CE_N | ~CART_RAM_CE_N) & ~GEN_WRH_N),
	.busy1(GEN_MEM_BUSY),

	//Load/Save: banks 0,1
	.addr2( rom_download ? (rom_cart_mode ? {2'b00,ioctl_addr[22:1]} : {6'b011110,ioctl_addr[18:1]}) : //ROM  000000-7FFFFF/F00000-F7FFFF
								  {5'b01110,tmpram_lba[9:0],tmpram_addr}),    //CART RAM E00000-EFFFFF for sd_*
	.din2(rom_download ? {ioctl_data[7:0],ioctl_data[15:8]} : {tmpram_dout,tmpram_dout}),
	.dout2(tmpram_din),
	.rd2(~rom_download & tmpram_req & ~bk_loading),
	.wrl2(rom_download ? ioctl_wait : (tmpram_req & bk_loading)),
	.wrh2(rom_download ? ioctl_wait : (tmpram_req & bk_loading)),
	.busy2(tmpram_busy)
);


wire [15:0] bram_sd_buff_data;
dpram_dif #(13,8,12,16) bram
(
	.clock(clk_sys),
	.address_a(PIER_QUIRK ? m95_addr : MCD_BRAM_ADDR),
	.data_a(PIER_QUIRK ? m95_di : MCD_BRAM_DO),
	.wren_a(PIER_QUIRK ? m95_we : MCD_BRAM_WE),
	.q_a(MCD_BRAM_DI),

	.address_b({sd_lba[3:0],sd_buff_addr}),
	.data_b(sd_buff_dout),
	.wren_b(sd_buff_wr & sd_ack & !sd_lba[10:4]),
	.q_b(bram_sd_buff_data)
);

wire [7:0] tmpram_dout;
wire [7:0] tmpram_din;
wire       tmpram_busy;

wire [15:0] tmpram_sd_buff_data;
dpram_dif #(9,8,8,16) tmpram
(
	.clock(clk_sys),

	.address_a(tmpram_addr),
	.wren_a(~bk_loading & tmpram_busy_d & ~tmpram_busy),
	.data_a(tmpram_din),
	.q_a(tmpram_dout),

	.address_b(sd_buff_addr),
	.wren_b(sd_buff_wr & sd_ack & |sd_lba[10:4]),
	.data_b(sd_buff_dout),
	.q_b(tmpram_sd_buff_data)
);

reg [10:0] tmpram_lba;
reg  [8:0] tmpram_addr;
reg tmpram_tx_start;
reg tmpram_tx_finish;
reg tmpram_req;
reg tmpram_busy_d;
always @(posedge clk_sys) begin
	reg state;

	tmpram_lba <= sd_lba[10:0]-11'h10;
	
	tmpram_busy_d <= tmpram_busy;
	if(~tmpram_busy_d & tmpram_busy) tmpram_req <= 0;

	if(~tmpram_tx_start) {tmpram_addr, state, tmpram_tx_finish} <= 0;
	else if(~tmpram_tx_finish) begin
		if(!state) begin
			tmpram_req <= 1;
			state <= 1;
		end
		else if(tmpram_busy_d & ~tmpram_busy) begin
			state <= 0;
			if(~&tmpram_addr) tmpram_addr <= tmpram_addr + 1'd1;
			else tmpram_tx_finish <= 1;
		end
	end
end


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
	reg rst_old = 0;
	
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
	else begin
		rst_old <= MCD_RST_N;
		if (rst_old & ~MCD_RST_N) begin
			cd_in[47:0] <= 8'hFF;
			cd_in[48] <= ~cd_in[48];
		end
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
wire PAL = region[1];

reg new_vmode;
always @(posedge clk_sys) begin
	reg old_pal;
	int to;
	
	if(~(reset | rom_download)) begin
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
	.enable(cofi_enable),

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

	.VGA_DE(vga_de),
	.R((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[0]}} : red),
	.G((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[1]}} : green),
	.B((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[2]}} : blue),

	// Positive pulses.
	.HSync(hs_c),
	.VSync(vs_c),
	.HBlank(hblank_c),
	.VBlank(vblank_c)
);

wire [2:0] lg_target;
wire       lg_sensor;
wire       lg_a;
wire       lg_b;
wire       lg_c;
wire       lg_start;

lightgun lightgun
(
	.CLK(clk_sys),
	.RESET(reset),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(&gun_mode),

	.JOY_X(gun_mode[0] ? joy0_x : joy1_x),
	.JOY_Y(gun_mode[0] ? joy0_y : joy1_y),
	.JOY(gun_mode[0] ? joystick_0 : joystick_1),

	.RELOAD(gun_type),

	.HDE(~hblank_c),
	.VDE(~vblank_c),
	.CE_PIX(ce_pix),
	.H40(res[0]),

	.BTN_MODE(gun_btn_mode),
	.SIZE(status[44:43]),
	.SENSOR_DELAY(gun_type ? 8'd32 : 8'd64),

	.TARGET(lg_target),
	.SENSOR(lg_sensor),
	.BTN_A(lg_a),
	.BTN_B(lg_b),
	.BTN_C(lg_c),
	.BTN_START(lg_start)
);

reg  [1:0] region_req;
reg        region_reset;
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state = 0;

	if(reset) region_reset <= 0;

	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		casex(code)
			'h005: begin region_req <= 0; region_reset <= pressed; end // F1
			'h006: begin region_req <= 1; region_reset <= pressed; end // F2
			'h004: begin region_req <= 2; region_reset <= pressed; end // F3
		endcase
	end

	if(ioctl_wr & rom_download) begin
		if(ioctl_addr == 'h1F0) begin
			if(ioctl_data[7:0] == "J") region_req <= 0;
			else if(ioctl_data[7:0] == "U") region_req <= 1;
			else region_req <= 2;
		end
	end
end

wire [1:0] region_new = status[7:6] ? (status[7:6] - 1'd1) : region_req;

reg  [1:0] region;
reg        region_set = 0;
always @(posedge clk_sys) begin
	reg [15:0] to = 0;
	
	region <= region_new;
	if(region != region_new) to <= 0;
	
	region_set <= 0;
	if(~&to) begin
		to <= to + 1'd1;
		region_set <= 1;
	end
end


/////////////////////////  BRAM SAVE/LOAD  /////////////////////////////

wire downloading = save_download;
wire bk_change  = MCD_BRAM_WE | m95_we | (CART_EN & ~CART_RAM_CE_N & (~GEN_WRL_N | ~GEN_WRH_N));
wire autosave   = status[13];
wire bk_load    = status[16];
wire bk_save    = status[17];

reg bk_ena = 0;
reg sav_pending = 0;
always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_change = 0;

	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;

	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly) bk_ena <= 1;

	old_change <= bk_change;
	if (~old_change & bk_change) sav_pending <= 1;
	else if (bk_state) sav_pending <= 0;
end

wire bk_save_a  = autosave & OSD_STATUS;
reg  bk_loading = 0;
reg  bk_state   = 0;
reg  bk_reload  = 0;

always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_load = 0, old_save = 0, old_save_a = 0, old_ack;
	reg [1:0] state;

	old_downloading <= downloading;

	old_load   <= bk_load;
	old_save   <= bk_save;
	old_save_a <= bk_save_a;
	old_ack    <= sd_ack;

	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

	if(!bk_state) begin
		tmpram_tx_start <= 0;
		state <= 0;
		sd_lba <= 0;
		bk_reload <= 0;
		bk_loading <= 0;
		if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save) | (~old_save_a & bk_save_a & sav_pending))) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			bk_reload <= bk_load;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~rom_download & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_rd <= 1;
			sd_wr <= 0;
		end
	end
	else if(!sd_lba[10:4]) begin
		if(old_ack & ~sd_ack) begin
			sd_lba <= sd_lba + 1'd1;
			if(&sd_lba[3:0]) begin
				if(~CART_EN) bk_state <= 0;
			end else begin
				sd_rd <=  bk_loading;
				sd_wr <= ~bk_loading;
			end
		end
	end
	else if(bk_loading) begin
		case(state)
			0: begin
					sd_rd <= 1;
					state <= 1;
				end
			1: if(old_ack & ~sd_ack) begin
					tmpram_tx_start <= 1;
					state <= 2;
				end
			2: if(tmpram_tx_finish) begin
					tmpram_tx_start <= 0;
					state <= 0;
					sd_lba <= sd_lba + 1'd1;
					if(sd_lba[10:0] == 11'h40F) bk_state <= 0;
				end
		endcase
	end
	else begin
		case(state)
			0: begin
					tmpram_tx_start <= 1;
					state <= 1;
				end
			1: if(tmpram_tx_finish) begin
					tmpram_tx_start <= 0;
					sd_wr <= 1;
					state <= 2;
				end
			2: if(old_ack & ~sd_ack) begin
					state <= 0;
					sd_lba <= sd_lba + 1'd1;
					if(sd_lba[10:0] == 11'h40F) bk_state <= 0;
				end
		endcase
	end
end

wire [7:0] SERJOYSTICK_IN;
wire [7:0] SERJOYSTICK_OUT;
wire [1:0] SER_OPT;

always @(posedge clk_sys) begin
	if (status[46]) begin
		SERJOYSTICK_IN[0] <= USER_IN[1];//up
		SERJOYSTICK_IN[1] <= USER_IN[0];//down	
		SERJOYSTICK_IN[2] <= USER_IN[5];//left	
		SERJOYSTICK_IN[3] <= USER_IN[3];//right
		SERJOYSTICK_IN[4] <= USER_IN[2];//b TL		
		SERJOYSTICK_IN[5] <= USER_IN[6];//c TR GPIO7			
		SERJOYSTICK_IN[6] <= USER_IN[4];//  TH
		SERJOYSTICK_IN[7] <= 0;
		SER_OPT[0] <= ~status[4];
		SER_OPT[1] <= status[4];
		USER_OUT[1] <= SERJOYSTICK_OUT[0];
		USER_OUT[0] <= SERJOYSTICK_OUT[1];
		USER_OUT[5] <= SERJOYSTICK_OUT[2];
		USER_OUT[3] <= SERJOYSTICK_OUT[3];
		USER_OUT[2] <= SERJOYSTICK_OUT[4];
		USER_OUT[6] <= SERJOYSTICK_OUT[5];
		USER_OUT[4] <= SERJOYSTICK_OUT[6];
	end else begin
		SER_OPT  <= 0;
		USER_OUT <= '1;
	end
end


///////////////////////////////////////////////

reg         ep_si, m95_so, ep_sck, ep_hold, ep_cs;
wire  [7:0] m95_di, m95_q;
wire [11:0] m95_addr;
wire        m95_we;

STM95XXX pier_eeprom
(
	.clk(clk_sys),
	.enable(PIER_QUIRK),
	.so(m95_so),
	.si(ep_si),
	.sck(ep_sck),
	.hold_n(ep_hold),
	.cs_n(ep_cs),
	.wp_n(1'b1),
	.ram_addr(m95_addr),
	.ram_q(MCD_BRAM_DI),
	.ram_di(m95_di),
	.ram_we(m95_we)
);

reg  [15:0] GEN_PAGE_DI;
reg   [4:0] BANK_REG[8];
wire [23:1] ROM_VA = {BANK_REG[GEN_VA[21:19]], GEN_VA[18:1]} & {rom_mask,12'hFFF};

// MAPPERS
always @(posedge clk_sys) begin
	reg old_ce;

	old_ce <= GEN_PAGE_CE_N;

	if (reset | rom_download) begin
		BANK_REG <= '{0,1,2,3,4,5,6,7};
	end
	else if(old_ce && ~GEN_PAGE_CE_N) begin
		GEN_PAGE_DI <= '1;
		if(PIER_QUIRK) begin
			if (GEN_RNW) begin
				if (GEN_VA[3:1] == 'h5) begin
					GEN_PAGE_DI[0] <= m95_so;
				end
			end
			else if (GEN_VA[3:1]) begin
				if (GEN_VA[3:1] == 4) begin // Pier EEPROM
					{ep_cs, ep_hold, ep_sck, ep_si} <= GEN_VDO[3:0];
				end
				else if (~GEN_VA[3]) begin // Pier Banks
					BANK_REG[{1'b1, GEN_VA[2:1]}] <= GEN_VDO[3:0];
				end
			end
		end
		else if (rom_mask[23:22]) begin // >4MB
			if (~GEN_RNW && GEN_VA[3:1]) begin
				BANK_REG[GEN_VA[3:1]] <= GEN_VDO[4:0];
			end
		end
	end
end

reg [15:0] PIER_DATA;
reg        PIER_HOOK;

always @(posedge clk_sys) begin
	reg       old_sel;
	reg [3:0] pier_count;

	old_sel <= GEN_ASEL_N;
	if (reset | rom_download) begin
		pier_count <= 0;
		PIER_HOOK <= 0;
	end
	else if(PIER_QUIRK & old_sel & ~GEN_ASEL_N) begin
		PIER_HOOK <= 0;
		if ({GEN_VA,1'b0} == 'h0015E6 || {GEN_VA,1'b0} == 'h0015E8) begin
			if (pier_count < 'h6) begin
				pier_count <= pier_count + 1'h1;
				PIER_DATA <= GEN_VA[1] ? 16'h0000 : 16'h0010;
			end
			else begin
				PIER_DATA <= GEN_VA[1] ? 16'h0001 : 16'h8010;
			end
			PIER_HOOK <= 1;
		end
	end
end

reg PIER_QUIRK = 0;
always @(posedge clk_sys) begin
	reg [63:0] cart_id;
	reg old_download;

	old_download <= rom_download;
	if(~old_download && rom_download) {PIER_QUIRK} <= 0;

	if(ioctl_wr & rom_download & ioctl_index[6]) begin
		if(ioctl_addr == 'h182) cart_id[63:56] <= ioctl_data[15:8];
		if(ioctl_addr == 'h184) cart_id[55:40] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h186) cart_id[39:24] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h188) cart_id[23:08] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h18A) cart_id[07:00] <= ioctl_data[7:0];
		if(ioctl_addr == 'h18C) begin
			     if(cart_id == "T-574023") PIER_QUIRK <= 1; // Pier Solar Reprint
			else if(cart_id == "T-574013") PIER_QUIRK <= 1; // Pier Solar 1st Edition
		end
	end
end

reg [23:13] rom_mask;
reg         rom_cart_mode;
always @(posedge clk_sys) begin
	if (rom_download & ioctl_wr) begin
		rom_cart_mode <= ioctl_index[6];
		if (ioctl_index[6]) begin
			rom_mask <= rom_mask | ioctl_addr[23:13];
			if(!ioctl_addr) rom_mask <= 0;
		end
	end
end

endmodule
