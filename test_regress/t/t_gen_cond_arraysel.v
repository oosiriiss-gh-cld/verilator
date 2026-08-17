// DESCRIPTION: Verilator: Verilog Test for short-circuiting in generate "if"
// when the condition indexes an unpacked array (AstArraySel) rather than a
// packed bit vector (AstSel), as covered by t_gen_cond_bitrange.v.
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2026 by Antmicro.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

`define MAX_SIZE 4

module t (
    input clk
);

  test_gen #(
      .SIZE(2)
  ) i_test_gen (
      .clk(clk)
  );

  initial begin
    $write("*-* All Finished *-*\n");
    $finish;
  end

endmodule  // t

module test_gen #(
    parameter SIZE = `MAX_SIZE
) (
    input clk
);

  // MASK is an unpacked array (not a packed vector), so indexing it
  // produces an AstArraySel rather than an AstSel.
  localparam logic MASK[`MAX_SIZE] = '{1'b1, 1'b1, 1'b0, 1'b0};

  generate
    genvar g;
    for (g = 0; g < `MAX_SIZE; g = g + 1) begin
      // Without short-circuiting, MASK[g] would be evaluated even for
      // g >= SIZE, but MASK only has valid data up to `MAX_SIZE, so this
      // just needs to not crash/warn since it never selects out of range.
      if ((g < SIZE) && MASK[g]) begin
        always @(posedge clk) begin
`ifdef TEST_VERBOSE
          $write("MASK[%1d] = %d\n", g, MASK[g]);
`endif
        end
      end
    end
  endgenerate

endmodule
