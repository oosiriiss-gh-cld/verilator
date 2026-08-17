// DESCRIPTION: Verilator: Verilog Test for generate "if" whose condition
// indexes an unpacked array (AstArraySel) rather than a packed bit vector
// (AstSel), as covered by t_gen_cond_bitrange.v.
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2026 by Antmicro.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk
);

  // MASK is an unpacked array (not a packed vector), so indexing it
  // produces an AstArraySel rather than an AstSel.
  localparam logic MASK[4] = '{1'b1, 1'b1, 1'b0, 1'b0};

  logic [3:0] out;

  generate
    genvar g;
    for (g = 0; g < 4; g = g + 1) begin
      if (MASK[g]) begin
        always @(posedge clk) begin
          out[g] <= MASK[g];
        end
      end
    end
  endgenerate

  initial begin
    $write("*-* All Finished *-*\n");
    $finish;
  end

endmodule
