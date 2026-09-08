// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// String-typed expressions inside constraints whose value depends on a
// randomized variable.  A 'rand string' is not legal (string is not integral,
// IEEE 1800-2023 18.4), but a string-typed *expression* may still be selected
// by a rand variable.  V3Width packs such expressions into bit vectors, so the
// solver sees ordinary bitvector equalities and the rand variable is solved
// for through the string comparison.

class Cls;
  rand bit sel;
  rand bit [1:0] pick;
  rand int x;

  // sel picks between two string literals; forces sel == 0
  constraint sel_c {(sel ? "aa" : "bb") == "bb";}

  // Condition is itself a rand expression; forces pick == 1
  constraint pick_c {(pick == 2'd1 ? "yy" : "nn") == "yy";}

  // String comparison feeding an integral constraint; sel == 0 => x == 20
  constraint x_c {x == ((sel ? "aa" : "bb") == "aa" ? 10 : 20);}
endclass

module t;
  initial begin
    automatic Cls c = new;
    for (int i = 0; i < 10; ++i) begin
      if (c.randomize() !== 1) $stop;
      if (c.sel !== 1'b0) $stop;
      if (c.pick !== 2'd1) $stop;
      if (c.x !== 20) $stop;
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
