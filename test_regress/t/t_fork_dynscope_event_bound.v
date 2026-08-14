// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Regression test for a null pointer dereference: a dynamically-indexed
// unpacked array (here an event array) in a sensitivity expression, where
// the index range can't be statically proven in-bounds (because the array
// size isn't a power of two), forces a runtime bounds check to be inserted.
// That check turns the sensitivity expression from a plain reference into
// a general expression, requiring value-change tracking that dereferences
// the index variable's fork-task dynamic scope. If the null-guard that
// protects that dereference fails to trigger (because the class-member
// access is nested inside the bounds-check logic, rather than being the
// expression root) this crashes before the fork task has even started.

module t;
  event e_tx[3];
  event e_rx[3];

  task automatic debug(string s);
    $display("%s", s);
  endtask

  task automatic run(int port_id);
    fork
      automatic int id = port_id;
      begin
        fork
          begin
            @(e_tx[id]);
            debug($sformatf("tx %0d", id));
          end
          begin
            @(e_rx[id]);
            debug($sformatf("rx %0d", id));
          end
        join
      end
    join_none
  endtask

  initial begin
    run(0);
    #1 ->e_tx[0];
    #1 ->e_rx[0];
    #1;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
