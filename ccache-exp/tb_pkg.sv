// DESCRIPTION: Verilator ccache experiment: example UVM-side testbench classes
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0
//
// Classes, unlike modules, are NOT included into V<prefix>__Syms.h
// (src/V3EmitCSyms.cpp:945 skips them). Edits here should therefore stay
// local, while edits in dut.sv should not. That contrast is the experiment.
//
// Deliberately conservative UVM usage -- uvm_component + `uvm_component_utils,
// matching what test_regress/t/t_uvm_hello.v already exercises.
//
// Lines tagged EXP:... are edit points used by run_experiment.sh. Do not
// renumber or reword them.

// verilator lint_off UNUSEDSIGNAL
// verilator lint_off WIDTHTRUNC
// verilator lint_off DECLFILENAME

package tb_pkg;

  import uvm_pkg::*;

  // EXP:COMMENT

  // A plain data class (no factory macros, to stay well inside what is
  // known to verilate cleanly).
  class txn;
    int unsigned addr;
    int unsigned data;
    // EXP:CLASS_MEMBER

    function new(int unsigned addr = 0, int unsigned data = 0);
      this.addr = addr;
      this.data = data;
    endfunction

    function int unsigned checksum();
      return addr ^ data;
    endfunction

    function string convert2string();
      return $sformatf("addr=%0h data=%0h", addr, data);
    endfunction
  endclass

  class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    int unsigned n_good;
    int unsigned n_bad;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void check(txn t);
      if (t.checksum() == (t.addr ^ t.data)) begin
        n_good++;
      end else begin
        n_bad++;
      end
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      $write("** scoreboard: %0d good, %0d bad\n", n_good, n_bad);
    endfunction
  endclass

  class driver extends uvm_component;
    `uvm_component_utils(driver)

    int unsigned sent;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function txn make_txn(int unsigned i);
      txn t = new(i, i * 3);
      sent++;
      // EXP:METHOD_BODY
      return t;
    endfunction
  endclass

  class monitor extends uvm_component;
    `uvm_component_utils(monitor)

    int unsigned observed;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void observe(txn t);
      observed++;
    endfunction
  endclass

  class env extends uvm_component;
    `uvm_component_utils(env)

    driver     drv;
    monitor    mon;
    scoreboard sb;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      drv = new("drv", this);
      mon = new("mon", this);
      sb  = new("sb", this);
    endfunction

    function void run_traffic(int unsigned count);
      for (int unsigned i = 0; i < count; i++) begin
        txn t = drv.make_txn(i);
        mon.observe(t);
        sb.check(t);
      end
    endfunction
  endclass

  class test extends uvm_test;
    `uvm_component_utils(test)

    env e;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      e = new("e", this);
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      e.run_traffic(16);
      $write("** UVM TEST PASSED **\n");
    endfunction
  endclass

endpackage
