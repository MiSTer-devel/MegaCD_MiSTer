//
// ddram.v
// Copyright (c) 2020 Sorgelig
//
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
// ------------------------------------------
//


module ddram
(
	input         DDRAM_CLK,

	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	input         cache_rst,

	input  [27:1] mem_addr,
	output [15:0] mem_dout,
	input  [15:0] mem_din,
	input         mem_rd,
	input         mem_wrl,
	input         mem_wrh,
	output reg    mem_busy
);

assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = DDRAM_RD ? 8'hFF : ({6'd0,ram_bs} << {mem_addr[2:1],1'b0});
assign DDRAM_ADDR     = {4'b0011, mem_addr[27:3]}; // RAM at 0x30000000
assign DDRAM_DIN      = {4{mem_din}};
assign DDRAM_WE       = ram_write;

assign mem_dout = data;

reg  [7:0] ram_burst;
reg  [1:0] ram_bs;
reg [15:0] data;
reg        ram_write = 0;
reg  [1:0] state = 0;

wire wr = mem_wrl | mem_wrh;
wire rd = mem_rd;

always @(posedge DDRAM_CLK) begin
	reg old_rd, old_wr;

	old_rd <= old_rd & rd;
	old_wr <= old_wr & wr;
	
	ram_burst <= 1;

	if(!DDRAM_BUSY) begin
		ram_write <= 0;
		case(state)
			0: begin
					mem_busy <= 0;
					cache_cs <= 0;
					if ((~old_rd && rd) || (~old_wr && wr)) begin
						old_rd <= rd;
						old_wr <= wr;
						ram_bs <= {mem_wrh,mem_wrl};
						ram_write <= wr;
						cache_we <= wr;
						mem_busy <= 1;
						cache_cs <= 1;
						state <= wr ? 2'd1 : 2'd2;
					end
				end

			1: if(cache_wrack) begin
					cache_cs <= 0;
					state <= 3;
				end

			2: if(cache_rdack) begin
					cache_cs <= 0;
					data <= cache_do;
					state <= 3;
				end

			3: state <= 0;

		endcase
	end
end

wire [15:0] cache_do;
wire        cache_rdack;
wire        cache_wrack;
reg         cache_cs;
reg         cache_we;

cache_2way cache
(
	.clk(DDRAM_CLK),
	.rst(cache_rst),

	.cache_enable(1),

	.cpu_cs(cache_cs),
	.cpu_adr(mem_addr[27:1]),
	.cpu_bs(ram_bs),
	.cpu_we(cache_we),
	.cpu_rd(~cache_we),
	.cpu_dat_w(mem_din),
	.cpu_dat_r(cache_do),
	.cpu_ack(cache_rdack),
	.wb_en(cache_wrack),

	.mem_dat_r(DDRAM_DOUT),
	.mem_read_req(DDRAM_RD),
	.mem_read_ack(DDRAM_DOUT_READY)
);

endmodule
