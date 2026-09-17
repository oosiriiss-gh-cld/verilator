// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Bad member names within a multi-segment '::' type reference.

class Leaf #(
    parameter int W = 1
);
  typedef logic [W-1:0] data_t;
endclass

class Mid #(
    parameter int N = 2
);
  typedef Leaf#(N) leaf_t;
endclass

module t;
  Mid#(6)::nosuch_t::data_t a;  // Bad intermediate segment
  Mid#(6)::leaf_t::nosuch_t b;  // Bad final type name
  initial begin
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
