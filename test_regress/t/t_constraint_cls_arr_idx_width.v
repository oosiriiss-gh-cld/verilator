// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
`define check_range(gotv,minv,maxv) do if ((gotv) < (minv) || (gotv) > (maxv)) begin $write("%%Error: %s:%0d:  got=%0d exp=[%0d:%0d]\n", `__FILE__,`__LINE__, (gotv), (minv), (maxv)); `stop; end while(0);
// verilog_format: on

class item_t;
  rand bit [7:0] value;
endclass

class container;
  rand item_t items[7];

  // Non-random index that is a sized 3-bit literal. Verilator's width
  // inference (V3Width) narrows every array-select index down to the
  // minimum number of bits needed to address the array (3 bits, for 7
  // elements) regardless of the index expression's declared type -- a
  // wider literal or a 32-bit "int" foreach variable is truncated down
  // to the same 3 bits. That is narrower than the guard's bounds-check
  // width, so the widen-before-compare path always runs for a non-rand
  // class-array index; there is no legal index expression that arrives
  // pre-widened.
  constraint narrow_idx_c { items[3'd0].value inside {[100 : 200]}; }

  // Regression case for the bug the guard fixes: without it, evaluating
  // items[i-1] for i==0 (or items[i+1] for the last i) walks off the end
  // of the array while building the SMT model, before the "if" below
  // ever gets a chance to exclude that index.
  constraint order_c {
    foreach (items[i]) if (i != 0) {items[i - 1].value < items[i].value;}
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
      `check_range(c.items[0].value, 100, 200);
      for (int i = 1; i < 7; i++) begin
        if (c.items[i - 1].value >= c.items[i].value) `stop;
      end
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
