// DESCRIPTION: Verilator: Verilog Test module
//
// Regression test for multi-level '::' package/class scope resolution
// used as a data type, e.g. "pkg::cls::type_t" (two or more '::' before
// the final identifier). Verilator previously only resolved a single
// '::' in a type reference and errored with "Unsupported: Multiple '::'
// package/class reference" for anything deeper, even though the same
// depth of '::' chain already worked fine in expression contexts (e.g.
// "pkg::cls::CONST" or "pkg::cls::method()").
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

package my_pkg;
  class custom_type_defs #(
      int DataWidth   = 128,
      int HeaderWidth = 11
  );
    typedef struct packed {
      logic valid;
      logic [HeaderWidth-1:0] tag;
      logic [DataWidth-1:0] data;
    } packet_t;
  endclass
endpackage

module sub (
    input  my_pkg::custom_type_defs#()::packet_t ingress,
    output my_pkg::custom_type_defs#()::packet_t egress
);
  assign egress = ingress;
endmodule

module t;
  // Three-level '::' chain (package :: class :: static method), to make
  // sure the fix isn't limited to exactly two levels.
  localparam int unsigned MAGIC = my_pkg::custom_type_defs#()::HeaderWidth;

  my_pkg::custom_type_defs#()::packet_t din, dout;

  sub sub (
      .ingress(din),
      .egress (dout)
  );

  initial begin
    if ($bits(din) != 1 + 11 + 128) $stop;
    if (MAGIC != 11) $stop;
    din = '{valid: 1'b1, tag: 11'h3ab, data: 128'hdead_beef};
    #1;
    if (dout !== din) $stop;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
