// DESCRIPTION: Verilator: Verilog Test module - parameter/localparam refs in
// covergroup transition bins
//
// This file ONLY is placed into the Public Domain, for any use, without warranty.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Test: Referencing a parameter/localparam identifier as a value inside a
// covergroup transition bin, e.g. 'bins t = (A => B);'. This previously
// triggered an internal error (V3Covergroup.cpp: buildTransitionItemCondition
// assumed transition values were already AstConst) because the value was
// still an unfolded AstVarRef to the parameter.
// Expected: compiles and the transitions behave exactly like numeric literals.

module t #(
    parameter int PLO = 0
) (
    input clk
);

  localparam int LHI = 3;
  localparam int LMID = 2;

  logic [2:0] state;

  covergroup cg;
    // Simple 2-value transition using localparams on both sides
    cp2: coverpoint state {
      bins t01 = (PLO => 1);  // parameter as first value
      bins t12 = (1 => LMID);  // localparam as second value
    }
    // 3-value sequence transition mixing localparams and literals
    cp3: coverpoint state {
      bins seq = (PLO => LMID => LHI);
    }
    // Multi-value (comma list) transition step containing a localparam
    cpm: coverpoint state {
      bins m = (PLO => 1, LMID);
    }
  endgroup

  cg cg_inst = new;

  int cyc = 0;

  always @(posedge clk) begin
    cyc <= cyc + 1;

    case (cyc)
      0: state <= 0;  // PLO
      1: state <= 1;  // hits t01 (PLO=>1), m (PLO=>1)
      2: state <= 2;  // LMID; hits t12 (1=>LMID)
      3: state <= 0;  // PLO again, to set up the seq sequence below
      4: state <= 2;  // LMID
      5: state <= 3;  // LHI; consecutive 0=>2=>3 hits seq (PLO=>LMID=>LHI)
      6: begin
        $write("*-* All Finished *-*\n");
        $finish;
      end
    endcase

    cg_inst.sample();
  end
endmodule
