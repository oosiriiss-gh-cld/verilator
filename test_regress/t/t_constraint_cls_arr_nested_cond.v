// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// Targets the m_conditionp consumer branch in
// ConstraintExprVisitor::visit(AstConstraintExpr*) (src/V3Randomize.cpp).
//
// Reaching that branch needs two things at once:
//  1) A producer: a struct/class-ref array element select with a non-rand
//     index, which stashes an index-vs-size bounds check into m_conditionp
//     (see visit(AstArraySel*), guarded by m_structSel).
//  2) A path for that condition to survive up to the constraint clause: the
//     clause's top-level node must not be a plain Biop/Triop (==, <, >, the
//     AstLogIf an "if" guard lowers to, etc.), since those route through
//     editSMT(), which isolates and locally absorbs whatever m_conditionp
//     an operand sets before it can bubble further up.
//
// nested_bare_bool_c below satisfies both: items[i].values[0] is a second
// level of class-ref array indexing reached through a MemberSel chain
// (items[i] is itself a class-ref array element), which today is rejected
// by the "Unsupported: Nested array element access in global constraint"
// check in visit(AstMemberSel*) -- so this test requires that nested
// class-ref array element access to be implemented first. Once it is, both
// items[i] and values[0] each contribute a bounds check merged via
// AstLogAnd, and because the clause is a bare boolean member reference (no
// wrapping "if"/comparison), the merged condition reaches
// visit(AstConstraintExpr*) undisturbed.
//
// Indices are kept always in-range (i ranges over items' own valid foreach
// range, 0 is a valid values[] index) so the test only exercises the code
// path, without depending on how an out-of-range case is meant to resolve.

`define ITEMS_SIZE 5
`define VALUES_SIZE 3

class item2_t;
  rand bit flag;
endclass

class item_t;
  rand bit [7:0] value;
  rand item2_t values[`VALUES_SIZE];
  function new();
    foreach (values[j]) values[j] = new;
  endfunction
endclass

class container;
  rand item_t items[`ITEMS_SIZE];

  // Bare boolean, two levels of nested class-ref array access, no
  // enclosing if/comparison to absorb the bounds checks before they reach
  // visit(AstConstraintExpr*).
  constraint nested_bare_bool_c {foreach (items[i]) items[i].values[0].flag;}

  function new();
    foreach (items[i]) items[i] = new;
  endfunction
endclass

module t;
  initial begin
    automatic container c = new;
    if (c.randomize() !== 1) $stop;
    foreach (c.items[i]) begin
      if (c.items[i].values[0].flag !== 1'b1) $stop;
    end
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
