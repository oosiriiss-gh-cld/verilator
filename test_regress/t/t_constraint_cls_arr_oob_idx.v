// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 PlanV GmbH
// SPDX-License-Identifier: CC0-1.0

// Test: a foreach constraint that references items[i-1] under an 'if (i != 0)'
// guard must not let the never-taken i==0 iteration's out-of-bounds index
// reach the solver. On an array whose element count isn't a power of two,
// the self-determined index width has spare encodings above the last valid
// index, so a naively-formatted out-of-range index aliases an index that
// was never declared to the solver, rather than a value that (by luck)
// still names a valid element. See also t_constraint_cls_arr_member.v,
// whose 4-element (power-of-two) arrays don't exercise this.

`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);

class item_t;
  rand bit [7:0] value;
endclass

class container;
  rand item_t items[3];
  constraint order_c {
    foreach (items[i]) {
      if (i != 0) {items[i].value > items[i-1].value;}
    }
  }
  function new();
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    automatic int ok;

    repeat (20) begin
      ok = c.randomize();
      `checkd(ok, 1);
      for (int i = 1; i < 3; i++) begin
        if (c.items[i].value <= c.items[i-1].value) begin
          $write("%%Error: %s:%0d: ordering violated: items[%0d]=%0d <= items[%0d]=%0d\n",
                 `__FILE__, `__LINE__, i, c.items[i].value, i - 1, c.items[i-1].value);
          `stop;
        end
      end
    end

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
