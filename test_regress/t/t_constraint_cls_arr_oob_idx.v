// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 PlanV GmbH
// SPDX-License-Identifier: CC0-1.0

// Test: a foreach constraint's items[i-1] reference is structurally
// out-of-bounds on the i==0 iteration; the 'if (i != 0)' guard makes it
// unreachable in Verilog semantics, but constraint lowering still builds
// an SMT term for it every iteration (the guard becomes an implication,
// not a control-flow skip). A 3-element array (not a power of two) is
// required: on a power-of-two array the aliased index still happens to
// land on a valid element, masking the bug.

class item_t;
  rand bit [7:0] value;
endclass

class container;
  rand item_t items[3];
  constraint c {
    foreach (items[i]) if (i != 0) items[i - 1].value < 200;
  }
  function new();
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
