//============================================================================
//  Audio compressor (signed samples)
// 
//  Copyright (C) 2018 Sorgelig
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

module compressor
(
   input             clk,
   input      [11:0] in1, in2,
   output reg [15:0] out1, out2
);

reg [10:0] a1;
reg [10:0] a2;
reg in1_11;
reg in2_11;
always @(posedge clk) begin
   in1_11 <= in1[11];
   in2_11 <= in2[11];
   a1 <= {11{in1[11]}} ^ in1[10:0];
   a2 <= {11{in2[11]}} ^ in2[10:0];
   out1 <= {in1_11, {15{in1_11}} ^ q1};
   out2 <= {in2_11, {15{in2_11}} ^ q2};
end

//sin(x)
wire [14:0] q1;
wire [14:0] q2;
dpram #(.DATAWIDTH(15), .ADDRWIDTH(11), .MEM_INIT_FILE("rtl/sound/compressor.mif")) tbl
(
   .clock     (clk),
   .address_a (a1),
   .q_a       (q1),
   .address_b (a2),
   .q_b       (q2)
);

endmodule
