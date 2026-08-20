// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

`define ITEMS_SIZE 7

class item_t;
  rand bit [7:0] value;
  rand bit flag;
endclass

class container;
  rand int x;
  // Generating OOB access causes solver unknown symbo/constant errors, even with guarding if clause.
  rand item_t items[`ITEMS_SIZE];
  // Generates items[-1]
  constraint less_c {foreach (items[i]) if (i !== 0) items[i-1].value < 110;}
  // Generates items[7]
  constraint greater_c {foreach (items[i]) if (i < `ITEMS_SIZE - 1) items[i+1].value > 50;}
  // One-bit expression, not implicitly coverted to "expr != 0"
  constraint bit_expr_c {foreach (items[i]) if (i !== 0) items[i-1].flag;}
  // 'with' reductions generate artifical for loop with index not truncated by V3Width.
  constraint arr_index_not_wide_c {items.xor() with (item.value) != 0;}
  function new();
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    foreach (c.items[i]) begin
      if (i !== 0) begin
        if (c.items[i-1].flag !== 1'b1) $stop;
        if (c.items[i-1].value >= 110) $stop;
      end
      if (i < `ITEMS_SIZE - 1) begin
        if (c.items[i+1].value <= 50) $stop;
      end
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
