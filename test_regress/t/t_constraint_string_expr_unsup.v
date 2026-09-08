// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// A string-typed expression that stays a string (operands are string
// variables, so V3Width cannot pack it) and depends on a rand variable.
// This cannot be encoded for the solver and must be reported, not silently
// mis-encoded.

class Cls;
  rand bit sel;
  string lo = "aa";
  string hi = "bb";
  constraint c {(sel ? lo : hi) == "bb";}
endclass

module t;
  initial begin
    automatic Cls c = new;
    void'(c.randomize());
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
