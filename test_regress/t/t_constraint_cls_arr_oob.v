// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

`define ITEMS_SIZE 7

class item_t;
  rand bit [7:0] value;
  rand bit flag1;
  rand bit flag2;
endclass

class container;
  rand int x;
  rand item_t items[`ITEMS_SIZE];
  bit non_rand_cond;
  constraint less_c {foreach (items[i]) if (i !== 0) items[i-1].value < 110;}
  constraint greater_c {foreach (items[i]) if (i < `ITEMS_SIZE - 1) items[i+1].value > 50;}
  constraint bit_expr_c {foreach (items[i]) if (i !== 0) items[i-1].flag1;}
  constraint arr_index_not_wide_c {items.xor() with (item.value) != 0;}
  constraint chained_condition {foreach (items[i]) non_rand_cond ? items[i].flag1 : items[i].flag2;}
  function new(bit cond);
    non_rand_cond = cond;
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new(1'b1);
    if (c.randomize() !== 1) $stop;
    foreach (c.items[i]) begin
      if (i !== 0) begin
        if (c.items[i-1].flag1 !== 1'b1) $stop;
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
