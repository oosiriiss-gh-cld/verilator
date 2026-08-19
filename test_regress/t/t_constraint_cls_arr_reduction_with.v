// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Test: array reduction methods ('with' clause) on a fixed-size array of
// class objects, referencing a rand member of each element. The reduction
// builds its own loop variable (unrelated to any user-visible foreach index)
// to select each element, exercising a distinct code path from a plain
// foreach/constant-index element access (see t_constraint_cls_arr_member.v).

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

class item_t;
  rand bit [7:0] value;
endclass

class container;
  rand item_t items[7];
  // 8-bit wrapping sum over each element's 'value' member.
  constraint sum_c { items.sum() with (item.value) == 8'd42; }
  function new();
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    bit [7:0] total;
    repeat (20) begin
      `checkd(c.randomize(), 1);
      total = 8'd0;
      foreach (c.items[i]) total += c.items[i].value;
      `checkd(total, 8'd42);
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
