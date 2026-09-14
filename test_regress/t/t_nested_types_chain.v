// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

typedef int some_type;
package pkg;
  class nested1;
    int x = 1;
    class nested21;
      int x = 21;
      class nested3 #(
          int PARAM = 3
      );
        int x = PARAM;
        typedef bit [PARAM:0] some_type;
        class nested4;
          int x = 4;
        endclass
      endclass
      // Typedefed parametrized class defaults to '#()' specialization (IEEE 1800-2023 8.25.1)
      typedef nested3 nested3_def;
    endclass
    class nested22;
      int x = 22;
    endclass
  endclass
  class paramed #(
      int N = 8
  );
    typedef bit [N:0] some_type;
    class nested;
      typedef bit [N-1:0] some_type;
    endclass
  endclass
endpackage
module mtyped #(
    type P
);
  typedef P::nested21::nested3 tp;
  tp nested;
endmodule

// Nested parametrized class of a non-package class
class outer;
  class inner #(
      int N = 4
  );
    typedef bit [N-1:0] some_type;
  endclass
endclass

module t;
  pkg::nested1 n1;
  pkg::nested1::nested21 n21;
  pkg::nested1::nested22 n22;
  pkg::nested1::nested21::nested3 #() n21_3;
  pkg::nested1::nested21::nested3 #(15) n21_3_param;
  pkg::nested1::nested21::nested3 #()::nested4 n21_3_4;
  pkg::nested1::nested21::nested3_def::nested4 n21_3def_4;
  pkg::paramed #(16)::nested::some_type value;
  pkg::paramed #()::nested::some_type value_def;
  pkg::paramed #(16)::some_type value2;
  pkg::paramed #()::some_type value2_def;
  // Typedef of a parametrized class at the end of a nested chain
  pkg::nested1::nested21::nested3 #()::some_type value3_def;
  pkg::nested1::nested21::nested3 #(15)::some_type value3;
  outer::inner #()::some_type value4_def;
  outer::inner #(12)::some_type value4;
  mtyped #(pkg::nested1) u ();
  initial begin
    n1 = new;
    n21 = new;
    n22 = new;
    n21_3 = new;
    n21_3_param = new;
    n21_3_4 = new;
    n21_3def_4 = new;
    u.nested = new;
    `checkd(n1.x, 1);
    `checkd(n21.x, 21);
    `checkd(n22.x, 22);
    `checkd(n21_3.x, 3);
    `checkd(n21_3_param.x, 15);
    `checkd(n21_3_4.x, 4);
    `checkd(n21_3def_4.x, 4);
    `checkd($bits(value), 16);
    `checkd($bits(value_def), 8);
    `checkd($bits(value2), 17);
    `checkd($bits(value2_def), 9);
    `checkd($bits(value3_def), 4);
    `checkd($bits(value3), 16);
    `checkd($bits(value4_def), 4);
    `checkd($bits(value4), 12);
    `checkd(u.nested.x, 3);
    $finish;
  end
endmodule
