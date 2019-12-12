// Copyright (c) 2010 Gregory Estrade (greg@torlus.com)
// Copyright (c) 2018 Sorgelig
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.

module gen
(
	input         RESET_N,
	input         MCLK,
	
	output [23:1] VA,
	input  [15:0] VDI,
	output [15:0] VDO,
	output        RNW,
	output        LDS_N,
	output        UDS_N,
	output        AS_N,
	input         DTACK_N,
	output        ASEL_N,
	output        VCLK_CE,
	output        CE0_N,
	output        WRL_N,
	output        WRH_N,
	output        OE_N,
	output        RAS2_N,
	output        ROM_N,
	output        FDC_N,
	input         CART_N,
	input         DISK_N,
	
	input  [15:0] EXT_SL,
	input  [15:0] EXT_SR,

	input   [1:0] LPF_MODE,
	input         ENABLE_FM,
	input         ENABLE_PSG,
	output [15:0] DAC_LDATA,
	output [15:0] DAC_RDATA,

	input         LOADING,
	input         PAL,
	input         EXPORT,
	
	input         EN_HIFI_PCM,
	input         LADDER,
	input         OBJ_LIMIT_HIGH,

	output  [3:0] RED,
	output  [3:0] GREEN,
	output  [3:0] BLUE,
	output        VS,
	output        HS,
	output        HBL,
	output        VBL,
	output        CE_PIX,
	input         BORDER,

	output        INTERLACE,
	output        FIELD,
	output  [1:0] RESOLUTION,
	
	input         EN_BGA,
	input         EN_BGB,
	input         EN_SPR,

	input         J3BUT,
	input  [11:0] JOY_1,
	input  [11:0] JOY_2,
	input  [11:0] JOY_3,
	input  [11:0] JOY_4,
	input   [1:0] MULTITAP,

	input  [24:0] MOUSE,
	input   [2:0] MOUSE_OPT,
	
	output        RAM_CE_N,
	input         RAM_RDY,
	
	output        RFS,
	input         RFS_RDY,
	
	output [23:0] DBG_M68K_A,
	output [23:0] DBG_MBUS_A
);

reg reset;
always @(posedge MCLK) if(M68K_CLKENn) reset <= ~RESET_N | LOADING;

//--------------------------------------------------------------
// CLOCK ENABLERS
//--------------------------------------------------------------
wire M68K_CLKEN = M68K_CLKENp;
reg  M68K_CLKENp, M68K_CLKENn;
reg  Z80_CLKEN;

always @(negedge MCLK) begin
	reg [3:0] VCLKCNT = 0;
	reg [3:0] ZCLKCNT = 0;

	if(~RESET_N | LOADING) begin
		VCLKCNT <= 0;
		ZCLKCNT = 0;
		Z80_CLKEN <= 1;
		M68K_CLKENp <= 1;
		M68K_CLKENn <= 1;
	end
	else begin
		M68K_CLKENp <= 0;
		VCLKCNT <= VCLKCNT + 1'b1;
		if (VCLKCNT == 4'd6) begin
			VCLKCNT <= 0;
			M68K_CLKENp <= 1;
		end

		M68K_CLKENn <= 0;
		if (VCLKCNT == 4'd3) begin
			M68K_CLKENn <= 1;
		end
		
		Z80_CLKEN <= 0;
		ZCLKCNT <= ZCLKCNT + 1'b1;
		if (ZCLKCNT == 14) begin
			ZCLKCNT <= 0;
			Z80_CLKEN <= 1;
		end
	end
end

reg [15:1] ram_rst_a;
always @(posedge MCLK) ram_rst_a <= ram_rst_a + LOADING;

//--------------------------------------------------------------
// CPU 68000
//--------------------------------------------------------------
wire [23:1] M68K_A;
wire [15:0] M68K_DO;
wire        M68K_AS_N;
wire        M68K_UDS_N;
wire        M68K_LDS_N;
wire        M68K_RNW;
wire  [2:0] M68K_FC;
wire        M68K_BG_N;
wire        M68K_BR_N;
wire        M68K_BGACK_N;
reg			M68K_VPA_N;


reg   [2:0] M68K_IPL_N;
always @(posedge MCLK) begin
	reg       old_as;
	reg [1:0] scnt;
	
	if(reset) begin
		M68K_IPL_N <= 3'b111;
	end
	else begin
	if (M68K_CLKEN) begin
		old_as <= M68K_AS_N;
		scnt <= scnt + 1'd1;
		if(~M68K_AS_N) scnt <= 0;
		if((~old_as & M68K_AS_N) || &scnt) begin
			if (M68K_VINT) M68K_IPL_N <= 3'b001;
			else if (M68K_HINT) M68K_IPL_N <= 3'b011;
			else M68K_IPL_N <= 3'b111;
		end
	end
	end
end

wire M68K_INTACK = &M68K_FC;

fx68k M68K
(
	.clk(MCLK),
	.extReset(reset),
	.pwrUp(reset),
	.enPhi1(M68K_CLKENp),
	.enPhi2(M68K_CLKENn),

	.eRWn(M68K_RNW),
	.ASn(M68K_AS_N),
	.UDSn(M68K_UDS_N),
	.LDSn(M68K_LDS_N),

	.FC0(M68K_FC[0]),
	.FC1(M68K_FC[1]),
	.FC2(M68K_FC[2]),

	.BGn(M68K_BG_N),
	.BRn(M68K_BR_N),
	.BGACKn(M68K_BGACK_N),
	.HALTn(1),

	.DTACKn(M68K_MBUS_DTACK_N),
	.VPAn(~M68K_INTACK),
	.BERRn(1),
	.IPL0n(M68K_IPL_N[0]),
	.IPL1n(M68K_IPL_N[1]),
	.IPL2n(M68K_IPL_N[2]),
	.iEdb(MBUS_DI),
	.oEdb(M68K_DO),
	.eab(M68K_A)
);

//--------------------------------------------------------------
// CPU Z80
//--------------------------------------------------------------
reg         Z80_RESET_N;
reg         Z80_BUSRQ_N;
wire        Z80_BUSAK_N;
wire        Z80_MREQ_N;
wire        Z80_RD_N;
wire        Z80_WR_N;
wire [15:0] Z80_A;
wire  [7:0] Z80_DO;
wire        Z80_IO = ~Z80_MREQ_N & (~Z80_RD_N | ~Z80_WR_N);

T80s #(.T2Write(1)) Z80
(
	.RESET_n(Z80_RESET_N),
	.CLK(MCLK),
	.CEN(Z80_CLKEN),
	.BUSRQ_n(Z80_BUSRQ_N),
	.BUSAK_n(Z80_BUSAK_N),
	.WAIT_n(~Z80_MBUS_DTACK_N | ~Z80_ZBUS_DTACK_N | ~Z80_IO),
	.INT_n(~Z80_VINT),
	.MREQ_n(Z80_MREQ_N),
	.RD_n(Z80_RD_N),
	.WR_n(Z80_WR_N),
	.A(Z80_A),
	.DI((~Z80_ZBUS_DTACK_N) ? Z80_ZBUS_D : (Z80_A[0] ? MBUS_DI[7:0] : MBUS_DI[15:8])),
	.DO(Z80_DO)
);

wire        CTRL_F  = (MBUS_A[11:8] == 1) ? Z80_BUSAK_N | ~Z80_RESET_N : (MBUS_A[11:8] == 2) ? Z80_RESET_N : NO_DATA[8];
wire [15:0] CTRL_DO = {NO_DATA[15:9], CTRL_F, NO_DATA[7:0]};
reg         CTRL_SEL;
always @(posedge MCLK) begin
	if (reset) begin
		Z80_BUSRQ_N <= 1;
		Z80_RESET_N <= 0;
	end
	else if(CTRL_SEL & ~MBUS_RNW & ~MBUS_UDS_N) begin
		if (MBUS_A[11:8] == 1) Z80_BUSRQ_N <= ~MBUS_DO[8];
		if (MBUS_A[11:8] == 2) Z80_RESET_N <=  MBUS_DO[8];
	end
end


//--------------------------------------------------------------
// VDP + PSG
//--------------------------------------------------------------
reg         VDP_SEL;
wire [15:0] VDP_DO;
wire        VDP_DTACK_N;

wire [23:1] VBUS_A;
wire        VBUS_SEL;

wire        M68K_HINT;
wire        M68K_VINT;
wire        Z80_VINT;

wire        vram_req;
wire        vram_we_u = vram_we & ~vram_u_n;
wire        vram_we_l = vram_we & ~vram_l_n;
wire        vram_we;
wire        vram_u_n;
wire        vram_l_n;
wire [15:1] vram_a;
wire [15:0] vram_d;
wire [15:0] vram_q1, vram_q2;

wire        vram32_req;
wire [15:1] vram32_a;
wire [31:0] vram32_q;

dpram #(14) vram_l1
(
	.clock(MCLK),
	.address_a(vram_a[15:2]),
	.data_a(vram_d[7:0]),
	.wren_a(vram_we_l & (vram_ack ^ vram_req) & ~vram_a[1]),
	.q_a(vram_q1[7:0]),

	.address_b(LOADING ? ram_rst_a[14:1] : vram32_a[15:2]),
	.wren_b(LOADING),
	.q_b(vram32_q[7:0])
);

dpram #(14) vram_u1
(
	.clock(MCLK),
	.address_a(vram_a[15:2]),
	.data_a(vram_d[15:8]),
	.wren_a(vram_we_u & (vram_ack ^ vram_req) & ~vram_a[1]),
	.q_a(vram_q1[15:8]),

	.address_b(LOADING ? ram_rst_a[14:1] : vram32_a[15:2]),
	.wren_b(LOADING),
	.q_b(vram32_q[15:8])
);

dpram #(14) vram_l2
(
	.clock(MCLK),
	.address_a(vram_a[15:2]),
	.data_a(vram_d[7:0]),
	.wren_a(vram_we_l & (vram_ack ^ vram_req) & vram_a[1]),
	.q_a(vram_q2[7:0]),

	.address_b(LOADING ? ram_rst_a[14:1] : vram32_a[15:2]),
	.wren_b(LOADING),
	.q_b(vram32_q[23:16])
);

dpram #(14) vram_u2
(
	.clock(MCLK),
	.address_a(vram_a[15:2]),
	.data_a(vram_d[15:8]),
	.wren_a(vram_we_u & (vram_ack ^ vram_req) & vram_a[1]),
	.q_a(vram_q2[15:8]),

	.address_b(LOADING ? ram_rst_a[14:1] : vram32_a[15:2]),
	.wren_b(LOADING),
	.q_b(vram32_q[31:24])
);

reg vram_ack;
always @(posedge MCLK) vram_ack <= vram_req;

reg vram32_ack;
always @(posedge MCLK) vram32_ack <= vram32_req;

wire VDP_hs, VDP_vs;
assign HS = ~VDP_hs;
assign VS = ~VDP_vs;

vdp vdp
(
	.RST_n(~reset),
	.CLK(MCLK),

	.SEL(VDP_SEL),
	.A({MBUS_A[4:1], 1'b0}),
	.RNW(MBUS_RNW),
	.DI(MBUS_DO),
	.DO(VDP_DO),
	.DTACK_n(VDP_DTACK_N),

	.VRAM_req(vram_req),
	.VRAM_ack(vram_ack),
	.VRAM_we(vram_we),
	.VRAM_u_n(vram_u_n),
	.VRAM_l_n(vram_l_n),
	.VRAM_a(vram_a),
	.VRAM_d(vram_d),
	.VRAM_q(vram_a[1] ? vram_q2 : vram_q1),

	.VRAM32_req(vram32_req),
	.VRAM32_ack(vram32_ack),
	.VRAM32_a(vram32_a),
	.VRAM32_q(vram32_q),
	
	.HINT(M68K_HINT),
	.VINT_TG68(M68K_VINT),
	.INTACK(M68K_INTACK),

	.VINT_T80(Z80_VINT),

	.VBUS_addr(VBUS_A),
	.VBUS_data(MBUS_DI),
	.VBUS_sel(VBUS_SEL),
	.VBUS_dtack_n(VDP_MBUS_DTACK_N),

	.BG_N(M68K_BG_N),
	.BR_N(M68K_BR_N),
	.BGACK_N(M68K_BGACK_N),

//	.VRAM_SPEED(1),
//	.VSCROLL_BUG(0),
	.BORDER_EN(BORDER),
	.OBJ_LIMIT_HIGH_EN(OBJ_LIMIT_HIGH),

	.FIELD_OUT(FIELD),
	.INTERLACE(INTERLACE),
	.RESOLUTION(RESOLUTION),
	
	.EN_BGA(EN_BGA),
	.EN_BGB(EN_BGB),
	.EN_SPR(EN_SPR),

	.PAL(PAL),
	.R(RED),
	.G(GREEN),
	.B(BLUE),
	.HS(VDP_hs),
	.VS(VDP_vs),
	.CE_PIX(CE_PIX),
	.HBL(HBL),
	.VBL(VBL)
);

// PSG 0x10-0x17 in VDP space
wire signed [10:0] PSG_SND;
jt89 psg
(
	.rst(reset),
	.clk(MCLK),
	.clk_en(Z80_CLKEN),

	.wr_n(MBUS_RNW | ~VDP_SEL | ~MBUS_A[4] | MBUS_A[3]),
	.din(MBUS_DO[15:8]),

	.sound(PSG_SND)
);


//--------------------------------------------------------------
// Gamepads
//--------------------------------------------------------------
reg         IO_SEL;
wire  [7:0] IO_DO;
wire        IO_DTACK_N;

reg         JCART_SEL;
wire [15:0] JCART_DO;
wire        JCART_DTACK_N;

multitap multitap
(
	.RESET(reset),
	.CLK(MCLK),
	.CE(M68K_CLKEN),

	.J3BUT(J3BUT),

	.P1_UP(~JOY_1[3]),
	.P1_DOWN(~JOY_1[2]),
	.P1_LEFT(~JOY_1[1]),
	.P1_RIGHT(~JOY_1[0]),
	.P1_A(~JOY_1[4]),
	.P1_B(~JOY_1[5]),
	.P1_C(~JOY_1[6]),
	.P1_START(~JOY_1[7]),
	.P1_MODE(~JOY_1[8]),
	.P1_X(~JOY_1[9]),
	.P1_Y(~JOY_1[10]),
	.P1_Z(~JOY_1[11]),

	.P2_UP(~JOY_2[3]),
	.P2_DOWN(~JOY_2[2]),
	.P2_LEFT(~JOY_2[1]),
	.P2_RIGHT(~JOY_2[0]),
	.P2_A(~JOY_2[4]),
	.P2_B(~JOY_2[5]),
	.P2_C(~JOY_2[6]),
	.P2_START(~JOY_2[7]),
	.P2_MODE(~JOY_2[8]),
	.P2_X(~JOY_2[9]),
	.P2_Y(~JOY_2[10]),
	.P2_Z(~JOY_2[11]),

	.P3_UP(~JOY_3[3]),
	.P3_DOWN(~JOY_3[2]),
	.P3_LEFT(~JOY_3[1]),
	.P3_RIGHT(~JOY_3[0]),
	.P3_A(~JOY_3[4]),
	.P3_B(~JOY_3[5]),
	.P3_C(~JOY_3[6]),
	.P3_START(~JOY_3[7]),
	.P3_MODE(~JOY_3[8]),
	.P3_X(~JOY_3[9]),
	.P3_Y(~JOY_3[10]),
	.P3_Z(~JOY_3[11]),

	.P4_UP(~JOY_4[3]),
	.P4_DOWN(~JOY_4[2]),
	.P4_LEFT(~JOY_4[1]),
	.P4_RIGHT(~JOY_4[0]),
	.P4_A(~JOY_4[4]),
	.P4_B(~JOY_4[5]),
	.P4_C(~JOY_4[6]),
	.P4_START(~JOY_4[7]),
	.P4_MODE(~JOY_4[8]),
	.P4_X(~JOY_4[9]),
	.P4_Y(~JOY_4[10]),
	.P4_Z(~JOY_4[11]),
	
	.DISK_N(DISK_N),
	
	.FOURWAY_EN(MULTITAP == 1),
	.TEAMPLAYER_EN(MULTITAP == 2),

	.MOUSE(MOUSE),
	.MOUSE_OPT(MOUSE_OPT),

	.PAL(PAL),
	.EXPORT(EXPORT),

	.SEL(IO_SEL),
	.A(MBUS_A[4:1]),
	.RNW(MBUS_RNW),
	.DI(MBUS_DO[7:0]),
	.DO(IO_DO),
	.DTACK_N(IO_DTACK_N),

	.JCART_SEL(JCART_SEL),
	.JCART_DO(JCART_DO),
	.JCART_DTACK_N(JCART_DTACK_N)
);

//-----------------------------------------------------------------------
// MBUS Handling
//-----------------------------------------------------------------------
reg         M68K_MBUS_DTACK_N;
reg         Z80_MBUS_DTACK_N;
reg         VDP_MBUS_DTACK_N;

reg  [15:0] M68K_MBUS_D;
reg   [7:0] Z80_MBUS_D;
reg  [15:0] VDP_MBUS_D;

reg  [23:1] MBUS_A;
reg  [15:0] MBUS_DO;

reg        MBUS_RNW;
reg        MBUS_UDS_N;
reg        MBUS_LDS_N;
wire [15:0] MBUS_DI;
reg        MBUS_ASEL_N;

reg  [15:0] NO_DATA;

reg         ROM_SEL;
reg         RAM_SEL;
reg         FDC_SEL;

reg   [3:0] mstate;
reg   [1:0] msrc;
	
localparam	MSRC_NONE = 0,
				MSRC_M68K = 1,
				MSRC_Z80  = 2,
				MSRC_VDP  = 3;

localparam 	MBUS_IDLE         = 0,
				MBUS_SELECT       = 1,
				MBUS_RAM_WAIT 		= 2,
				MBUS_RAM_READ     = 3,
				MBUS_RAM_WRITE    = 4,
				MBUS_ROM_READ     = 5,
				MBUS_VDP_READ     = 6,
				MBUS_IO_READ      = 7,
				MBUS_JCRT_READ    = 8,
				MBUS_ZBUS_READ    = 9,
				MBUS_FDC_READ     = 10,
				MBUS_NOT_USED		= 11,
				MBUS_REFRESH		= 12,
				MBUS_FINISH       = 13; 

always @(posedge MCLK) begin
	reg [8:0] refresh_timer;
	reg rfs_pend;
	
	if (reset) begin
		M68K_MBUS_DTACK_N <= 1;
		Z80_MBUS_DTACK_N  <= 1;
		VDP_MBUS_DTACK_N  <= 1;
		MBUS_UDS_N <= 1;
		MBUS_LDS_N <= 1;
		MBUS_RNW <= 1;
		ROM_SEL <= 0;
		RAM_SEL <= 0;
		VDP_SEL <= 0;
		IO_SEL <= 0;
		CTRL_SEL <= 0;
		ZBUS_SEL <= 0;
		FDC_SEL <= 0;
		mstate <= MBUS_IDLE;
		NO_DATA <= 'h4E71;
		RFS <= 0;
		rfs_pend <= 0;
	end
	else begin
		refresh_timer <= refresh_timer + 1'd1;
		if (refresh_timer == 'h17F) begin
			refresh_timer <= 0;
			rfs_pend <= 1;
		end
		
		case(mstate)
		MBUS_IDLE:
			begin
				msrc <= MSRC_NONE;
				if (rfs_pend) begin
					rfs_pend <= 0;
					RFS <= 1;
					mstate <= MBUS_REFRESH;
				end
				else if (!M68K_AS_N && (!M68K_LDS_N || !M68K_UDS_N) && M68K_MBUS_DTACK_N) begin
					msrc <= MSRC_M68K;
					MBUS_A <= M68K_A[23:1];
					MBUS_DO <= M68K_DO;
					MBUS_UDS_N <= M68K_UDS_N;
					MBUS_LDS_N <= M68K_LDS_N;
					MBUS_RNW <= M68K_RNW;
					MBUS_ASEL_N <= M68K_A[23];
					mstate <= MBUS_SELECT;
				end
				else if (Z80_IO && !Z80_ZBUS && Z80_MBUS_DTACK_N && M68K_BR_N && M68K_BGACK_N) begin
					msrc <= MSRC_Z80;
					MBUS_A <= Z80_A[15] ? {BAR[23:15],Z80_A[14:1]} : {16'hC000, Z80_A[7:1]};
					MBUS_DO <= {Z80_DO,Z80_DO};
					MBUS_UDS_N <= Z80_A[0];
					MBUS_LDS_N <= ~Z80_A[0];
					MBUS_RNW <= Z80_WR_N;
					MBUS_ASEL_N <= Z80_A[15] ? BAR[23] : 1'b1;
					mstate <= MBUS_SELECT;
				end
				else if (VBUS_SEL && VDP_MBUS_DTACK_N) begin
					msrc <= MSRC_VDP;
					MBUS_A <= VBUS_A;
					MBUS_DO <= 0;
					MBUS_UDS_N <= 0;
					MBUS_LDS_N <= 0;
					MBUS_RNW <= 1;
					MBUS_ASEL_N <= VBUS_A[23];
					mstate <= MBUS_SELECT;
				end
			end
			
		MBUS_SELECT:
			begin
				//NO DEVICE (usually lockup on real HW)
				mstate <= MBUS_NOT_USED;
				
				//ROM: 000000-7FFFFF
				if (!MBUS_A[23]) begin
					ROM_SEL <= 1;
					mstate <= MBUS_ROM_READ;
				end
					
				//ZBUS: A00000-A07FFF (A08000-A0FFFF)
				else if (MBUS_A[23:16] == 'hA0) begin
					ZBUS_SEL <= 1;
					mstate <= MBUS_ZBUS_READ;
				end

				//I/O: A10000-A1001F (+mirrors)
				else if (MBUS_A[23:5] == {16'hA100, 3'b000}) begin
					IO_SEL <= 1;
					mstate <= MBUS_IO_READ;
				end

				//CTRL: A11100, A11200
				else if (MBUS_A[23:12] == 12'hA11 && !MBUS_A[7:1]) begin
					CTRL_SEL <= 1;
					M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
					mstate <= MBUS_FINISH;
				end

				//FDC A120XX
				else if (MBUS_A[23:8] == 'hA120) begin
					FDC_SEL <= 1;
					mstate <= MBUS_FDC_READ;
				end

				//VDP: C00000-C0001F (+mirrors)
				else if (MBUS_A[23:21] == 3'b110 && !MBUS_A[18:16] && !MBUS_A[7:5]) begin
					VDP_SEL <= 1;
					mstate <= MBUS_VDP_READ;
				end

				//RAM: E00000-FFFFFF
				else if (&MBUS_A[23:21]) begin
					RAM_SEL <= 1;
					mstate <= MBUS_RAM_WAIT;
				end
			end

		MBUS_ZBUS_READ:
			if (!MBUS_ZBUS_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				mstate <= MBUS_FINISH;
			end

		MBUS_RAM_WAIT:
			begin
				if (!RAM_RDY) begin
					mstate <= MBUS_RNW ? MBUS_RAM_READ : MBUS_RAM_WRITE;
				end
			end
			
		MBUS_RAM_READ:
			begin
				if (RAM_RDY) begin
					M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
					VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
					Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
					mstate <= MBUS_FINISH;
				end
			end

		MBUS_RAM_WRITE:
			begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_ROM_READ:
			if (!DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_VDP_READ:
			if (!VDP_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end

		MBUS_IO_READ:
			if (!IO_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_FDC_READ:
			if (!DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_NOT_USED:
			begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_REFRESH:
			begin
				if (!RFS_RDY) begin
					RFS <= 0;
					mstate <= MBUS_IDLE;
				end
			end
			
		MBUS_FINISH:
			begin
				if ((M68K_AS_N && !M68K_MBUS_DTACK_N && msrc == MSRC_M68K) ||
					 (!Z80_IO && !Z80_MBUS_DTACK_N && msrc == MSRC_Z80) ||
					 (!VBUS_SEL && !VDP_MBUS_DTACK_N && msrc == MSRC_VDP)) begin
					M68K_MBUS_DTACK_N <= 1;
					VDP_MBUS_DTACK_N <= 1;
					Z80_MBUS_DTACK_N <= 1;
					MBUS_UDS_N <= 1;
					MBUS_LDS_N <= 1;
					MBUS_RNW <= 1;
					MBUS_ASEL_N <= 1;
					ROM_SEL <= 0;
					RAM_SEL <= 0;
					VDP_SEL <= 0;
					ZBUS_SEL <= 0;
					CTRL_SEL <= 0;
					IO_SEL <= 0;
					FDC_SEL <= 0;
					mstate <= MBUS_IDLE;
					if (msrc == MSRC_M68K) begin
						NO_DATA <= MBUS_DI;
					end
				end
			end
		endcase;
	end
end

assign MBUS_DI = ROM_SEL ? VDI :
					  RAM_SEL ? VDI :
					  VDP_SEL ? (MBUS_A[4:2] == 1 ? {NO_DATA[15:10],VDP_DO[9:0]} : VDP_DO) :
					  ZBUS_SEL ? {MBUS_ZBUS_D, MBUS_ZBUS_D} :
					  CTRL_SEL ? CTRL_DO :
					  IO_SEL ? {IO_DO, IO_DO} :
					  FDC_SEL ? VDI :
					  NO_DATA;

assign VA = MBUS_A;
assign VDO = MBUS_DO;
assign RNW = MBUS_RNW;
assign LDS_N = MBUS_LDS_N;
assign UDS_N = MBUS_UDS_N;
assign AS_N = M68K_AS_N;
assign ASEL_N = MBUS_ASEL_N;										//000000-7FFFFF 68K/VDP/Z80
assign VCLK_CE = M68K_CLKENn;

assign CE0_N =  ~(MBUS_A[23:22] == {1'b0, CART_N});		//000000-3FFFFF /CART=0 or 400000-7FFFFF /CART=1
assign ROM_N =  ~(MBUS_A[23:21] == {1'b0,~CART_N,1'b0});	//400000-5FFFFF /CART=0 or 000000-1FFFFF /CART=1
assign RAS2_N = ~(MBUS_A[23:21] == {1'b0,~CART_N,1'b1});	//600000-7FFFFF /CART=0 or 200000-3FFFFF /CART=1 (pulse in real)
assign FDC_N =  ~(MBUS_A[23:8] == 16'hA120);					//A12000-A120FF 

assign RAM_CE_N = ~RAM_SEL;

assign WRL_N = MBUS_RNW | MBUS_LDS_N;
assign WRH_N = MBUS_RNW | MBUS_UDS_N;
assign OE_N = ~MBUS_RNW;

assign DBG_MBUS_A = {MBUS_A,1'b0};
assign DBG_M68K_A = {M68K_A,1'b0};

//-----------------------------------------------------------------------
// ZBUS Handling
//-----------------------------------------------------------------------
// Z80:   0000-7EFF
// 68000: A00000-A07FFF (A08000-A0FFFF)

wire       Z80_ZBUS  = ~Z80_A[15] && ~&Z80_A[14:8];

reg        ZBUS_SEL;
reg [14:0] ZBUS_A;
reg        ZBUS_WE;
reg  [7:0] ZBUS_DO;
wire [7:0] ZBUS_DI = ZRAM_SEL ? ZRAM_DO : (FM_SEL ? FM_DO : 8'hFF);

reg  [7:0] MBUS_ZBUS_D;
reg  [7:0] Z80_ZBUS_D;

reg        MBUS_ZBUS_DTACK_N;
reg        Z80_ZBUS_DTACK_N;

wire       Z80_ZBUS_SEL = Z80_ZBUS & Z80_IO;
wire       ZBUS_FREE = ~Z80_BUSRQ_N & Z80_RESET_N;

// RAM 0000-1FFF (2000-3FFF)
wire ZRAM_SEL = ~ZBUS_A[14];

wire  [7:0] ZRAM_DO;
dpram #(13) ramZ80
(
	.clock(MCLK),
	.address_a(ZBUS_A[12:0]),
	.data_a(ZBUS_DO),
	.wren_a(ZBUS_WE & ZRAM_SEL),
	.q_a(ZRAM_DO)
);

always @(posedge MCLK) begin
	reg [1:0] zstate;
	reg [1:0] zsrc;

	localparam 	ZSRC_MBUS = 0,
					ZSRC_Z80  = 1;

	localparam	ZBUS_IDLE   = 0,
					ZBUS_READ   = 1,
					ZBUS_FINISH = 2;

	ZBUS_WE <= 0;
	
	if (reset) begin
		MBUS_ZBUS_DTACK_N <= 1;
		Z80_ZBUS_DTACK_N  <= 1;
		zstate <= ZBUS_IDLE;
	end
	else begin
		if (~ZBUS_SEL)     MBUS_ZBUS_DTACK_N <= 1;
		if (~Z80_ZBUS_SEL) Z80_ZBUS_DTACK_N  <= 1;

		case (zstate)
		ZBUS_IDLE:
			if (ZBUS_SEL & MBUS_ZBUS_DTACK_N) begin
				ZBUS_A <= {MBUS_A[14:1], MBUS_UDS_N};
				ZBUS_DO <= (~MBUS_UDS_N) ? MBUS_DO[15:8] : MBUS_DO[7:0];
				ZBUS_WE <= ~MBUS_RNW & ZBUS_FREE;
				zsrc <= ZSRC_MBUS;
				zstate <= ZBUS_READ;
			end
			else if (Z80_ZBUS_SEL & Z80_ZBUS_DTACK_N) begin
				ZBUS_A <= Z80_A[14:0];
				ZBUS_DO <= Z80_DO;
				ZBUS_WE <= ~Z80_WR_N;
				zsrc <= ZSRC_Z80;
				zstate <= ZBUS_READ;
			end

		ZBUS_READ:
			zstate <= ZBUS_FINISH;

		ZBUS_FINISH:
			begin
				case(zsrc)
				ZSRC_MBUS:
					begin
						MBUS_ZBUS_D <= ZBUS_FREE ? ZBUS_DI : 8'hFF;
						MBUS_ZBUS_DTACK_N <= 0;
					end

				ZSRC_Z80:
					begin
						Z80_ZBUS_D <= ZBUS_DI;
						Z80_ZBUS_DTACK_N <= 0;
					end
				endcase
				zstate <= ZBUS_IDLE;
			end
		endcase
	end
end


//-----------------------------------------------------------------------
// Z80 BANK REGISTER
//-----------------------------------------------------------------------
// 6000-60FF

wire BANK_SEL = ZBUS_A[14:8] == 7'h60;
reg [23:15] BAR;

always @(posedge MCLK) begin
	if (reset) BAR <= 0;
	else if (BANK_SEL & ZBUS_WE) BAR <= {ZBUS_DO[0], BAR[23:16]};
end


//--------------------------------------------------------------
// YM2612
//--------------------------------------------------------------
// 4000-4003 (4000-5FFF)

wire        FM_SEL = ZBUS_A[14:13] == 2'b10;
wire  [7:0] FM_DO;
wire signed [15:0] FM_right;
wire signed [15:0] FM_left;
wire signed [15:0] FM_LPF_right;
wire signed [15:0] FM_LPF_left;
wire [15:0] SL;
wire [15:0] SR;
wire signed [15:0] PRE_LPF_L;
wire signed [15:0] PRE_LPF_R;

jt12 fm
(
	.rst(~Z80_RESET_N),
	.clk(MCLK),
	.cen(M68K_CLKENp),

	.cs_n(0),
	.addr(ZBUS_A[1:0]),
	.wr_n(~(FM_SEL & ZBUS_WE)),
	.din(ZBUS_DO),
	.dout(FM_DO),
	.en_hifi_pcm( EN_HIFI_PCM ),
	.ladder(LADDER),
	.snd_left(FM_left),
	.snd_right(FM_right)
);

wire signed [15:0] fm_adjust_l = (FM_left << 4) + (FM_left << 2) + (FM_left << 1) + (FM_left >>> 2);
wire signed [15:0] fm_adjust_r = (FM_right << 4) + (FM_right << 2) + (FM_right << 1) + (FM_right >>> 2);

genesis_fm_lpf fm_lpf_l
(
	.clk(MCLK),
	.reset(reset),
	.in(fm_adjust_l),
	.out(FM_LPF_left)
);

genesis_fm_lpf fm_lpf_r
(
	.clk(MCLK),
	.reset(reset),
	.in(fm_adjust_r),
	.out(FM_LPF_right)
);

wire signed [15:0] fm_select_l = ((LPF_MODE == 2'b01) ? FM_LPF_left : fm_adjust_l);
wire signed [15:0] fm_select_r = ((LPF_MODE == 2'b01) ? FM_LPF_right : fm_adjust_r);

wire signed [10:0] psg_adjust = PSG_SND - (PSG_SND >>> 5);

jt12_genmix genmix
(
	.rst(reset),
	.clk(MCLK),
	.fm_left(fm_select_l),
	.fm_right(fm_select_r),
	.psg_snd(psg_adjust),
	.fm_en(ENABLE_FM),
	.psg_en(ENABLE_PSG),
	.snd_left(SL),
	.snd_right(SR)
);

SND_MIX mix
(
	.CH0_R(SR),
	.CH0_L(SL),
	.CH0_EN(1),
	
	.CH1_R(EXT_SR),
	.CH1_L(EXT_SL),
	.CH1_EN(1),
	
	.OUT_R(PRE_LPF_R),
	.OUT_L(PRE_LPF_L)
);

genesis_lpf lpf_right
(
	.clk(MCLK),
	.reset(reset),
	.lpf_mode(LPF_MODE[1:0]),
	.in(PRE_LPF_R),
	.out(DAC_RDATA)
);

genesis_lpf lpf_left
(
	.clk(MCLK),
	.reset(reset),
	.lpf_mode(LPF_MODE[1:0]),
	.in(PRE_LPF_L),
	.out(DAC_LDATA)
);

endmodule
