// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

class item_t;
  rand bit [7:0] value;
endclass

class container;
  // Valid indices are 0..6
  // Array indices get truncated to log2(7) + 1 = 3 bits.
  // Truncation is not the problem, it just hides the problem for power-of-two arrays.
  // If we somehow generate class member with index 7 this will
  // cause a solver error as it doesn't exist.
  rand item_t items [7];
  rand item_t items2[7];
  // Power-of-two size: the truncated index width (3 bits) exactly spans the
  // whole array, so every element (including 4..7, whose truncated index
  // has its top bit set) is a genuinely valid, non-OOB access. This guards
  // against an OOB check that misreads a valid high-half index as negative
  // (a signed vs. unsigned bug) or that truncates the array size itself to
  // 0 when building the bound (since 8 does not fit in 3 bits either).
  rand item_t items3[8];
  // Generates items[-1] for i == 0. -1 is then wrapped to 7 because of truncation
  constraint less_neg_c {foreach (items[i]) if (i !== 0) items[i-1].value < 200;}
  // Generates items2[7] for i == 6.
  constraint less_pos_c {foreach (items2[i]) if (i !== 6) items2[i+1].value < 199;}
  // Tight per-element equality: a false-positive OOB defusal on any element
  // (not just the wraparound ones above) turns this into "0 == i", which is
  // either unsatisfiable (i != 0) or produces a wrong value (i == 0).
  constraint eq_c {foreach (items3[i]) items3[i].value == 8'(i);}
  function new();
    foreach (items[i]) items[i] = new;
    foreach (items2[i]) items2[i] = new;
    foreach (items3[i]) items3[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    for (int i = 1; i < 7; i++) begin
      if (c.items[i-1].value >= 200) begin
        $display("%%Error: items[%0d].value=%0d, expected <200", i - 1, c.items[i-1].value);
        $stop;
      end
    end
    for (int i = 0; i < 6; i++) begin
      if (c.items2[i+1].value >= 199) begin
        $display("%%Error: items2[%0d].value=%0d, expected <199", i + 1, c.items2[i+1].value);
        $stop;
      end
    end
    foreach (c.items3[i]) begin
      if (c.items3[i].value !== 8'(i)) begin
        $display("%%Error: items3[%0d].value=%0d, expected %0d", i, c.items3[i].value, i);
        $stop;
      end
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
