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

// Parametrized class nested in a $unit-scope class: the '::' chain's leftmost
// element is a class rather than a package
class unit_cls;
  class uparamed #(
      int N = 8
  );
    typedef bit [N:0] some_type;
    int x = N;
    class nested;
      typedef bit [N-1:0] some_type;
      int y = 4;
    endclass
  endclass
endclass

module mtyped #(
    type P
);
  typedef P::nested21::nested3 tp;
  tp nested;
endmodule

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
  unit_cls::uparamed #(16)::some_type u_value;
  unit_cls::uparamed #()::some_type u_value_def;
  unit_cls::uparamed #(16) u_obj;
  unit_cls::uparamed #(16)::nested u_nested;
  // Parametrized class in the middle of the chain, under a class rather than a package,
  // with more than one element following it
  unit_cls::uparamed #(16)::nested::some_type u_nested_value;
  unit_cls::uparamed #()::nested::some_type u_nested_value_def;
  // A '$unit::' prefix parses as a right-nested 'Dot($unit, Dot(...))' chain
  $unit::pkg::nested1::nested21 d_n21;
  $unit::pkg::nested1::nested21::nested3 #(15) d_n21_3_param;
  $unit::unit_cls::uparamed #(16)::some_type d_value;
  $unit::unit_cls::uparamed #(16)::nested d_nested;
  $unit::unit_cls::uparamed #(16)::nested::some_type d_nested_value;
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
    u_obj = new;
    u_nested = new;
    d_n21 = new;
    d_n21_3_param = new;
    d_nested = new;
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
    `checkd(u.nested.x, 3);
    `checkd($bits(u_value), 17);
    `checkd($bits(u_value_def), 9);
    `checkd(u_obj.x, 16);
    `checkd(u_nested.y, 4);
    `checkd(d_n21.x, 21);
    `checkd(d_n21_3_param.x, 15);
    `checkd($bits(d_value), 17);
    `checkd(d_nested.y, 4);
    `checkd($bits(u_nested_value), 16);
    `checkd($bits(u_nested_value_def), 8);
    `checkd($bits(d_nested_value), 16);
    $finish;
  end
endmodule
