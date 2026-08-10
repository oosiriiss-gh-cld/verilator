// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 PlanV GmbH
// SPDX-License-Identifier: CC0-1.0

// Test: packed-array analog of t_constraint_cls_arr_oob_idx.v. A foreach
// constraint's items[i-1] reference is structurally out-of-bounds on the
// i==0 iteration; the 'if (i != 0)' guard makes it unreachable in Verilog
// semantics, but constraint lowering still builds an SMT term for it every
// iteration. Packed-array selects lower to SMT-LIB's '(_ extract hi lo)',
// so an out-of-range lsb here isn't just a wrong value (as an out-of-range
// unpacked/class-array index can silently be) -- it's invalid SMT-LIB
// syntax, since extract bounds must fall within the selected value's width.

class container;
  rand bit [2:0][7:0] items;
  constraint c {
    foreach (items[i]) if (i != 0) items[i - 1] < 200;
  }
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
