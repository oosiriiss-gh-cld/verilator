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
    output reg o,
    output reg q
);
  // 'rst' is the design's only reset, and it is asynchronous.
  always_ff @(posedge clk or negedge rst) begin
    o <= ~rst;
  end

  // Assertions are not synthesized, so reading 'rst' in one of them is not a second,
  // synchronous reset path and must not report SYNCASYNCNET.  Each check below lowers
  // to a different shape, so between them they cover every node kind the marking has
  // to reach.

  // Boolean property: a generated always holding a generated 'if'.
  assert property (@(posedge clk) disable iff ((rst) !== '0) (a));

  // Sequence property: lowered through the NFA, where 'disable iff' becomes a bare
  // assignment with no enclosing 'if'.
  assert property (@(posedge clk) disable iff ((rst) !== '0) (a |=> b));

  // $past() of the reset: lowered to a capture flop, also with no enclosing 'if'.
  assert property (@(posedge clk) ($past(rst) === a));

  // Immediate assertion inside the user's own synchronous procedure.  Here the
  // procedure is real RTL and only the generated 'if' is verification logic.
  always_ff @(posedge clk) begin
    assert (rst !== 1'b0 || a === 1'b0);
    q <= a;
  end
endmodule
