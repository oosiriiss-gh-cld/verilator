// DESCRIPTION: Verilator: Verilog Test module
//
// Assertion support logic must not be mistaken for RTL by the lint checks that
// inspect procedural structure: V3Gate's SYNCASYNCNET check and V3Active's
// LATCH detection.  Every module below must lint clean.  Each one fails
// (warning shown) if a specific piece of the assertion marking is removed, as
// noted per module.
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0

// Sequence logic lowered by V3AssertNfa becomes bare NBAs in a generated always
// block with no enclosing 'if', so only the AstAlways-level flag can cover the
// reset read.  Covers: V3AssertNfa's newAssertAlways, V3Gate's
// visit(AstNodeProcedure).  Removing either: SYNCASYNCNET on 'rst'.
module sub_nfa_sequence (
    input clk,
    input rst,
    input a,
    input b,
    output reg o
);
   always @(posedge clk or negedge rst) o <= ~rst;
   assert property (@(posedge clk) (rst !== 0) ##1 (a == b));
endmodule

// A longer sequence gives the NFA state register several independent NBAs, so
// V3Split rebuilds the generated always block with a fresh node before V3Gate
// sees it.  Covers: V3Split's isUnderAssertion propagation onto split AstAlways
// (in addition to the two above).  Removing it: SYNCASYNCNET on 'rst'.
module sub_nfa_split (
    input clk,
    input rst,
    input a,
    input b,
    output reg o
);
   always @(posedge clk or negedge rst) o <= ~rst;
   assert property (@(posedge clk) (rst !== 0) ##1 a ##1 b);
endmodule

// An immediate assertion in a clocked block that is the user's own RTL: the
// block must stay unflagged, so only the AstNodeIf-level flag covers the reset
// read.  Covers: V3Assert's newIfAssertOn marking, V3Gate's visit(AstNodeIf).
// Removing either: SYNCASYNCNET on 'rst'.
module sub_immediate_clocked (
    input clk,
    input rst,
    output reg o
);
   always @(posedge clk or negedge rst) o <= ~rst;
   always @(posedge clk) assert (rst !== 0);
endmodule

// Same, but the block has two independent outputs, so V3Split clones the
// assertion's 'if' into new blocks before V3Gate.  Covers: V3Split's
// isUnderAssertion propagation onto cloned AstIf.  Removing it: SYNCASYNCNET.
module sub_split_if (
    input clk,
    input rst,
    input a,
    input b,
    output reg o,
    output reg x,
    output reg y
);
   always @(posedge clk or negedge rst) o <= ~rst;
   always @(posedge clk) begin
      assert (rst !== 0);
      x <= a;
      y <= b;
   end
endmodule

// 'unique if' is wrapped by V3Assert in a violation check, and the latch
// detector must look through that wrapper (it did so via isBoundsCheck before
// the flag existed; behavior is unchanged).  V3Const inverts and merges that
// wrapper on the way, so the flag must survive the rebuilt 'if' too.  Covers:
// V3Active's ActiveLatchCheckVisitor and V3Const's flag copy.  Removing
// either: LATCH on 'o'.
module sub_latch_unique_if (
    input a,
    output logic o
);
   always_comb begin
      unique if (a) o = 1'b0;
   end
endmodule

module t (
    input clk,
    input rst,
    input a,
    input b,
    output o
);
   logic o1, o2, o3, o4, o5, o6, o7;
   assign o = o1 ^ o2 ^ o3 ^ o4 ^ o5 ^ o6 ^ o7;
   sub_nfa_sequence i_nfa_seq (.clk(clk), .rst(rst), .a(a), .b(b), .o(o1));
   sub_nfa_split i_nfa_split (.clk(clk), .rst(rst), .a(a), .b(b), .o(o2));
   sub_immediate_clocked i_imm (.clk(clk), .rst(rst), .o(o3));
   sub_split_if i_split_if (.clk(clk), .rst(rst), .a(a), .b(b), .o(o4), .x(o5), .y(o6));
   sub_latch_unique_if i_latch (.a(a), .o(o7));
endmodule
