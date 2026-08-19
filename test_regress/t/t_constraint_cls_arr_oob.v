// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

class item_t;
  rand bit [7:0] value;
  rand bit flag_a;
  rand bit flag_b;
endclass

class container;
  // If we generate class member with OOB index this
  // will cause solver error as it doesn't exist.
  rand item_t items [7];
  rand item_t items2[7];
  // Generates items[-1]
  constraint less_neg_c {foreach (items[i]) if (i !== 0) items[i-1].value < 200;}
  // Generates items[7]
  constraint less_pos_c {foreach (items2[i]) if (i !== 6) items2[i+1].value < 199;}
  // Chained condition
  constraint chain_c {foreach (items[i]) {items[i].flag_a; items[i].flag_b;} }
  function new();
    foreach (items[i]) items[i] = new;
    foreach (items2[i]) items2[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    foreach (c.items[i]) begin
      if (c.items[i].flag_a !== 1'b1) $stop;
      if (c.items[i].flag_b !== 1'b1) $stop;
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
