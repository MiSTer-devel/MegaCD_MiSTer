//
// sdram.v
//
// sdram controller implementation
// Copyright (c) 2018 Sorgelig
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module sdram
(

	// interface to the MT48LC16M16 chip
	inout  reg [15:0] SDRAM_DQ,   // 16 bit bidirectional data bus
	output reg [12:0] SDRAM_A,    // 13 bit multiplexed address bus
	output reg        SDRAM_DQML, // byte mask
	output reg        SDRAM_DQMH, // byte mask
	output reg  [1:0] SDRAM_BA,   // two banks
	output            SDRAM_nCS,  // a single chip select
	output reg        SDRAM_nWE,  // write enable
	output reg        SDRAM_nRAS, // row address select
	output reg        SDRAM_nCAS, // columns address select
	output            SDRAM_CLK,
	output            SDRAM_CKE,

	// cpu/chipset interface
	input             init,			// init signal after FPGA config to initialize RAM
	input             clk,			// sdram is accessed at up to 128MHz

	input      [24:1] addr0,
	input             rd0,
	input             wrl0,
	input             wrh0,
	input      [15:0] din0,
	output     [15:0] dout0,
	output            busy0,
	
	input      [24:1] addr1,
	input             rd1,
	input             wrl1,
	input             wrh1,
	input      [15:0] din1,
	output     [15:0] dout1,
	output            busy1,
	
	input      [24:1] addr2,
	input             rd2,
	input             wrl2,
	input             wrh2,
	input      [15:0] din2,
	output     [15:0] dout2,
	output            busy2
);

assign SDRAM_nCS = 0;
assign SDRAM_CKE = 1;
assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11];

localparam RASCAS_DELAY   = 3'd2; // tRCD=20ns -> 2 cycles@85MHz
localparam BURST_LENGTH   = 3'd0; // 0=1, 1=2, 2=4, 3=8, 7=full page
localparam ACCESS_TYPE    = 1'd0; // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2; // 2/3 allowed
localparam OP_MODE        = 2'd0; // only 0 (standard operation) allowed
localparam NO_WRITE_BURST = 1'd1; // 0=write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

localparam STATE_LATCH0  = 3'd0;
localparam STATE_RAS0    = STATE_LATCH0+1'd1;
localparam STATE_CAS0    = STATE_RAS0+RASCAS_DELAY;
localparam STATE_READ0   = STATE_CAS0+CAS_LATENCY+1'd1;

localparam STATE_LATCH1  = 3'd4;
localparam STATE_RAS1    = STATE_LATCH1+1'd1;
localparam STATE_CAS1    = STATE_RAS1+RASCAS_DELAY;
localparam STATE_READ1   = STATE_CAS1+CAS_LATENCY+1'd1;


reg  [2:0] state;
reg [24:1] addr[2];
reg [15:0] data[2];
reg        we[2];
reg  [1:0] dqm[2];
reg        active[2] = '{0,0};

reg        refresh = 0;
reg  [2:0] ram_req = 0;
wire [2:0] wr = {wrl2|wrh2,wrl1|wrh1,wrl0|wrh0};
wire [2:0] rd = {rd2,rd1,rd0};

reg [15:0] dout;

assign dout0 = dout;
assign dout1 = dout;
assign dout2 = dout;

localparam [9:0] RFS_CNT = 766;

/*
 0 LATCH0
 1         RAS0
 2               READ1
 3         CAS0
 4 LATCH1
 5         RAS1
 6               READ0
 7         CAS1
*/

reg  [2:0] old_rd, old_wr;
wire [2:0] req = (~old_rd & rd) | (~old_wr & wr);
wire       bnk = (state == STATE_LATCH1);

// access manager
always @(posedge clk) begin
	reg [9:0] rfs_timer = 0;
	reg [1:0] bnk2ch[2] = '{0,0};

	state <= state + 1'd1;

	if(rfs_timer) rfs_timer <= rfs_timer - 1'd1;

	old_rd <= old_rd & rd;
	old_wr <= old_wr & wr;
	if(mode == MODE_NORMAL && !refresh) begin
		if(state == STATE_LATCH0 || state == STATE_LATCH1) begin
			if (!rfs_timer && !bnk) begin
				rfs_timer   <= RFS_CNT;
				refresh     <= 1;
			end
			else if (req[0] && addr0[24] == bnk && !ram_req[0]) begin
				old_rd[0]   <= rd[0];
				old_wr[0]   <= wr[0];
				ram_req[0]  <= 1;
				addr[bnk]   <= addr0;
				data[bnk]   <= din0;
				we[bnk]     <= wr[0];
				dqm[bnk]    <= wr[0] ? ~{wrh0,wrl0} : 2'b00;
				active[bnk] <= 1;
				bnk2ch[bnk] <= 0;
			end
			else if (req[1] && addr1[24] == bnk && !ram_req[1]) begin
				old_rd[1]   <= rd[1];
				old_wr[1]   <= wr[1];
				ram_req[1]  <= 1;
				addr[bnk]   <= addr1;
				data[bnk]   <= din1;
				we[bnk]     <= wr[1];
				dqm[bnk]    <= wr[1] ? ~{wrh1,wrl1} : 2'b00;
				active[bnk] <= 1;
				bnk2ch[bnk] <= 1;
			end
			else if (req[2] && addr2[24] == bnk && !ram_req[2]) begin
				old_rd[2]   <= rd[2];
				old_wr[2]   <= wr[2];
				ram_req[2]  <= 1;
				addr[bnk]   <= addr2;
				data[bnk]   <= din2;
				we[bnk]     <= wr[2];
				dqm[bnk]    <= wr[2] ? ~{wrh2,wrl2} : 2'b00;
				active[bnk] <= 1;
				bnk2ch[bnk] <= 2;
			end
		end
	end

	if(state == STATE_READ0) begin
		dout <= SDRAM_DQ;
		if(active[0]) ram_req[bnk2ch[0]] <= 0;
		active[0] <= 0;
		refresh <= 0;
	end

	if(state == STATE_READ1) begin
		dout <= SDRAM_DQ;
		if(active[1]) ram_req[bnk2ch[1]] <= 0;
		active[1] <= 0;
	end
end

assign busy0 = ram_req[0];
assign busy1 = ram_req[1];
assign busy2 = ram_req[2];

localparam MODE_NORMAL = 2'b00;
localparam MODE_RESET  = 2'b01;
localparam MODE_LDM    = 2'b10;
localparam MODE_PRE    = 2'b11;

// initialization 
reg [1:0] mode;
reg [4:0] reset=5'h1f;
always @(posedge clk) begin
	reg init_old=0;
	init_old <= init;

	if(init_old & ~init) reset <= 5'h1f;
	else if(&state) begin
		if(reset != 0) begin
			reset <= reset - 5'd1;
			if(reset == 14)     mode <= MODE_PRE;
			else if(reset == 3) mode <= MODE_LDM;
			else                mode <= MODE_RESET;
		end
		else mode <= MODE_NORMAL;
	end
end

localparam CMD_NOP             = 3'b111;
localparam CMD_ACTIVE          = 3'b011;
localparam CMD_READ            = 3'b101;
localparam CMD_WRITE           = 3'b100;
localparam CMD_BURST_TERMINATE = 3'b110;
localparam CMD_PRECHARGE       = 3'b010;
localparam CMD_AUTO_REFRESH    = 3'b001;
localparam CMD_LOAD_MODE       = 3'b000;

reg [2:0] cmd;
assign {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd;

always @(posedge clk) begin

	SDRAM_DQ <= 'Z;
	cmd <= CMD_NOP;

	case(state)
		STATE_RAS0: begin
			SDRAM_A <= 0;
			SDRAM_BA <= 0;

			case(mode)
				MODE_LDM: begin
					cmd <= CMD_LOAD_MODE;
					SDRAM_A <= MODE;
					SDRAM_BA <= 0;
				end

				MODE_PRE: begin
					cmd <= CMD_PRECHARGE;
					SDRAM_A <= 13'b0010000000000;
					SDRAM_BA <= 0;
				end

				MODE_NORMAL: begin
					if(active[0]) cmd <= CMD_ACTIVE;
					if(refresh) cmd <= CMD_AUTO_REFRESH;
					SDRAM_A <= addr[0][13:1];
					SDRAM_BA <= addr[0][24:23];
				end
			endcase
		end

		STATE_CAS0: begin
			if(mode == MODE_NORMAL && active[0]) begin
				cmd <= we[0] ? CMD_WRITE : CMD_READ;
				if(we[0]) SDRAM_DQ <= data[0];
				SDRAM_A <= {dqm[0], 2'b10, addr[0][22:14]};
				SDRAM_BA <= addr[0][24:23];
			end
		end

		STATE_RAS1: begin
			if(mode == MODE_NORMAL && active[1]) begin
				cmd <= CMD_ACTIVE;
				SDRAM_A <= addr[1][13:1];
				SDRAM_BA <= addr[1][24:23];
			end
		end
		
		STATE_CAS1: begin
			if(mode == MODE_NORMAL && active[1]) begin
				cmd <= we[1] ? CMD_WRITE : CMD_READ;
				if(we[1]) SDRAM_DQ <= data[1];
				SDRAM_A <= {dqm[1], 2'b10, addr[1][22:14]};
				SDRAM_BA <= addr[1][24:23];
			end
		end
	endcase
end

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk),
	.dataout(SDRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

endmodule
