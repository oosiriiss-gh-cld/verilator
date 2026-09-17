// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d (%s !== %s)\n", `__FILE__,`__LINE__, (gotv), (expv), `"gotv`", `"expv`"); `stop; end while(0);
// verilog_format: on

// Tests multiple '::' segments in a type reference, where intermediate segments
// are parameterized classes that must be specialized before the next segment can
// be looked up inside them.

package P;
  class Leaf #(
      parameter int W = 1
  );
    typedef logic [W-1:0] data_t;
    localparam int WIDTH = W;
  endclass

  class Mid #(
      parameter int N = 2
  );
    typedef Leaf#(N) leaf_t;
    typedef Leaf#(N * 2) leaf2_t;
  endclass

  class Top #(
      parameter int M = 3
  );
    typedef Mid#(M) mid_t;
  endclass

  class Holder #(
      type T = logic
  );
    T val;
    function int width();
      return $bits(val);
    endfunction
  endclass
endpackage

// A chain as the target of a typedef
typedef P::Mid#(9)::leaf_t::data_t nine_t;

// A chain inside a parameterized module, depending on that module's own parameter
module sub #(
    parameter int PW = 4
) ();
  P::Mid#(PW)::leaf_t::data_t v;
  initial
    if ($bits(v) != PW) begin
      $write("%%Error: sub PW=%0d bits=%0d\n", PW, $bits(v));
      $stop;
    end
endmodule

module t;

  sub #(4) s4 ();
  sub #(11) s11 ();

  nine_t n;

  // A chain used as the type parameter of another parameterized class
  P::Holder #(P::Mid#(10)::leaf_t::data_t) h;

  // A chain in a function signature
  function automatic P::Mid#(13)::leaf_t::data_t widen(input P::Mid#(13)::leaf_t::data_t x);
    return x;
  endfunction

  // Two segments: package :: parameterized class :: type
  P::Leaf#(5)::data_t a;

  // Three segments, through a typedef of a parameterized class
  P::Mid#(6)::leaf_t::data_t b;

  // Four segments
  P::Top#(7)::mid_t::leaf_t::data_t c;

  // Distinct specializations reached through the same chain must not collide
  P::Mid#(6)::leaf2_t::data_t d;  // Leaf#(12)
  P::Mid#(3)::leaf_t::data_t e;  // Leaf#(3)

  // Default parameters through a chain
  P::Top#()::mid_t::leaf_t::data_t f;  // Top#(3) -> Mid#(3) -> Leaf#(3)

  // The same chains in expression context, which was already supported
  localparam int EB = P::Mid#(6)::leaf_t::WIDTH;
  localparam int EC = P::Top#(7)::mid_t::leaf_t::WIDTH;

  initial begin
    `checkd($bits(a), 5);
    `checkd($bits(b), 6);
    `checkd($bits(c), 7);
    `checkd($bits(d), 12);
    `checkd($bits(e), 3);
    `checkd($bits(f), 3);
    `checkd(EB, 6);
    `checkd(EC, 7);
    `checkd($bits(n), 9);

    h = new;
    `checkd(h.width(), 10);
    `checkd($bits(widen(13'h1FFF)), 13);

    // The types are usable, not just measurable
    a = 5'h1F;
    c = 7'h7F;
    `checkd(a, 5'h1F);
    `checkd(c, 7'h7F);

    $write("*-* All Finished *-*\n");
    $finish;
  end

endmodule
