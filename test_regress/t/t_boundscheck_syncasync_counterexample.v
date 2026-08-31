// DESCRIPTION: Verilator: Verilog Test module
//
// Counter-example showing that gating SYNCASYNCNET on AstNodeIf::isBoundsCheck()
// also silently suppresses the warning for a genuine bounds-check If generated
// by V3Unknown (BOUNDLVALUE), not just for assertion-related Ifs from V3Assert.
// isBoundsCheck() is set true by both producers, so a Gate-stage check that
// only looks at that flag cannot tell "underneath an assertion" apart from
// "underneath a real array-bounds-check", and would wrongly drop this warning
// for real hardware. (-fno-split is used by the driver so V3Split does not
// incidentally clear the flag before V3Gate runs, for reasons unrelated to
// this test's point.)
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk,
    input rst_both_l,
    input [2:0] idx,
    input d
);

  // Non-power-of-2 sized array: a 3-bit index (0-7) can exceed the
  // declared range (0-4), so V3Unknown cannot statically prove the index
  // is always in bounds and must insert a runtime bounds-check If.
  reg [7:0] mem[0:4];
  reg q3;

  // rst_both_l used as ASYNC reset here
  always @(posedge clk or negedge rst_both_l) begin
    if (~rst_both_l) q3 <= 1'b0;
    else q3 <= d;
  end

  // rst_both_l also used SYNCHRONOUSLY here, as data feeding a
  // variable-index (out-of-range-possible) memory write. V3Unknown
  // wraps this whole statement in an AstIf with isBoundsCheck(true)
  // to guard the out-of-range index -- nothing to do with assertions.
  always @(posedge clk) begin
    mem[idx] <= rst_both_l ? d : 1'b0;
  end

endmodule
