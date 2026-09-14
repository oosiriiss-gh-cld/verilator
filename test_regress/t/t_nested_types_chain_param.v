// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

// More than one link of a '::' chain may be parameterized.  Each link can only be
// resolved once the link before it has been specialized, so they specialize one at a
// time (IEEE 1800-2023 8.25.1).
package pkg;
  class a #(
      int N = 8
  );
    class b #(
        int M = 4
    );
      class c #(
          int K = 2
      );
        typedef bit [N+M+K-1:0] t;
      endclass
      typedef bit [N+M-1:0] t;
      int v = N * 100 + M;
    endclass
    class mid;
      class inner #(
          int P = 5
      );
        typedef bit [N+P-1:0] t;
      endclass
    endclass
    class tp #(
        type T = byte
    );
      typedef T t;
    endclass
  endclass
endpackage

module t;
  // Three parameterized links
  pkg::a #(16)::b #(3)::c #(5)::t  three;
  // Named parameter on the second link
  pkg::a #(16)::b #(.M(3))::t      named;
  // Second link defaulted with '#()'
  pkg::a #(16)::b #()::t           inner_def;
  // Unparameterized link between two parameterized ones
  pkg::a #(16)::mid::inner #(7)::t gap;
  // Type parameter on the second link
  pkg::a #(16)::tp #(int)::t       typaram;
  // Specializations of one nested class must stay distinct per outer specialization
  pkg::a #(16)::b #(3)::t          s1;
  pkg::a #(16)::b #(9)::t          s2;
  pkg::a #(32)::b #(3)::t          s3;
  // Chain ending at a parameterized class used as the declared type
  pkg::a #(16)::b #(3)             o1;
  pkg::a #(32)::b #(3)             o2;
  initial begin
    o1 = new;
    o2 = new;
    `checkd($bits(three), 24);
    `checkd($bits(named), 19);
    `checkd($bits(inner_def), 20);
    `checkd($bits(gap), 23);
    `checkd($bits(typaram), 32);
    `checkd($bits(s1), 19);
    `checkd($bits(s2), 25);
    `checkd($bits(s3), 35);
    `checkd(o1.v, 1603);
    `checkd(o2.v, 3203);
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
