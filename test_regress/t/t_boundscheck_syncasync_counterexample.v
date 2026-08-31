// DESCRIPTION: Verilator: Verilog Test module
//
// Counter-example showing that gating SYNCASYNCNET on AstNodeIf::isBoundsCheck()
// also silently suppresses the warning for a genuine bounds-check If generated
// by V3Unknown (BOUNDLVALUE), not just for assertion-related Ifs from V3Assert.
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk,
    input rst_both_l,
    input [31:0] idx,
    input d
);

  reg [7:0] mem[0:7];
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
