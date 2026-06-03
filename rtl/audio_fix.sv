//
// audio_fix
//
// Copyright (c) 2026 Alexey Melnikov
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
///////////////////////////////////////////////////////////////////////

module audio_fix #(parameter CE_OFFSET)
(
	input             CLK_AUDIO,
	output reg [15:0] AUDIO_L,
	output reg [15:0] AUDIO_R,

	input        reset,
	input        clk,
	input        ce,
	input [15:0] l,
	input [15:0] r
);

localparam CNT_W = $clog2(CE_OFFSET);

reg src_toggle;
always_ff @(posedge clk) begin
	reg ce_r;
	reg [CNT_W:0] cnt;
	reg rst1, rst2;

	//in case if reset is async or comes from different clock
	rst1 <= reset;
	rst2 <= rst1;
	
	if(~&cnt) cnt <= cnt + 1'd1;
	ce_r <= ce;
	if((~ce_r & ce) || rst2) cnt <= 0;

	if(cnt == CE_OFFSET) src_toggle <= ~src_toggle;
end

always @(posedge CLK_AUDIO) begin
	reg tgl1, tgl2, tgl3;
	reg rst1, rst2;

	rst1 <= reset;
	rst2 <= rst1;
	
	tgl1 <= src_toggle;
	tgl2 <= tgl1;
	if(tgl2 == tgl1) tgl3 <= tgl2;
	
	if((tgl3 != tgl2) || rst2) begin
		AUDIO_L <= l;
		AUDIO_R <= r;
	end
end

endmodule
