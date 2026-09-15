// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

package pkg;
  class nested1;
    int x1 = 1;
    class nested21;
      int x21 = 21;
      class nested3 #(
          int PARAM = 3
      );
        int x3 = PARAM;
        class nested4;
          int x4 = 4;
        endclass
      endclass
    endclass
  endclass
endpackage

class C;
endclass
class D;
  class E;
    typedef int T;
  endclass
endclass
module F;
  // should error as C has no D in it
  C::D::E::T x;
endmodule

module t;
  // Unknown top type
  bad::nested1::x::y n1;
  // Unknown middle type
  pkg::bad_type::nested3 n2;
  pkg::nested1::bad_type::nested3 n3;
  // Unknown final type
  pkg::nested1::bad_type n4;
  // Parametrized class without #()
  pkg::nested1::nested21::nested3::nested4 n5;
  F f ();
endmodule
