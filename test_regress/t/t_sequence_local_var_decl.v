// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk
);

  int cyc = 0;
  int obs_imm = -1;
  int obs_conc = -1;
  logic valid = 1;

  // --- Scenario 1: local variable captured by a match item ---
  // Sequence instance with a port in an immediate assertion, inlined by V3AssertPre.
  sequence s_imm(int sig);
    int x;
    (valid, x = sig, obs_imm = x + 1);
  endsequence

  // --- Scenario 2: local variable captured by a match item ---
  // Sequence instance with a port in a concurrent assertion, inlined by V3AssertNfa.
  sequence s_conc(int sig);
    int y;
    (valid, y = sig, obs_conc = y + 2);
  endsequence
  assert property (@(posedge clk) s_conc(cyc) |-> 1);

  // --- Scenario 3: local variable read in a multi-cycle sequence ---
  // Never assigned, so it keeps its default value of zero.
  sequence s_multi;
    int z;
    (cyc >= z) ##1 valid;
  endsequence
  assert property (@(posedge clk) s_multi);

  always @(posedge clk) begin
    assert (s_imm(cyc));
    if (obs_imm != cyc + 1) $stop;
    if (obs_conc != cyc + 2) $stop;
    cyc <= cyc + 1;
    if (cyc == 10) begin
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end

endmodule
