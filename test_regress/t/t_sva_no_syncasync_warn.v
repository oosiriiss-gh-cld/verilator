// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk,
    input rst,
    input a,
    input b,
    output reg o
);
  always_ff @(posedge clk or negedge rst) begin
    o <= ~rst;
  end
  // Assertions are not synthesized, so reading 'rst' in one of them is not a
  // second, synchronous reset path and must not report SYNCASYNCNET.

  // Simple boolean property: lowered to a plain always with an 'if'.
  assert property (@(posedge clk) disable iff ((rst) !== '0) ($c(1'b1)));

  // Sequence property: lowered through the NFA path, where 'disable iff'
  // becomes a bare assignment with no enclosing 'if'.
  assert property (@(posedge clk) disable iff ((rst) !== '0) (a |=> b));

  // $past() of the reset: lowered to a capture flop, also with no 'if'.
  assert property (@(posedge clk) ($past(rst) === a));
endmodule
