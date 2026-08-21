// DESCRIPTION: Check that a blocking partial write with select outside of LSB
// of a 2-state vector with a non-zero declared LSB doesn't corrupt lvalue
// write refs.
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv, expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d: $time=%0t got='h%x exp='h%x\n", `__FILE__,`__LINE__, $time, (gotv), (expv)); `stop; end while(0)
// verilog_format: on

module t;

  initial begin
    bit [63:62] vec;
    bit [66:64] narrow;

    // verilator lint_off SELRANGE
    vec = 2'b00;
    vec[67:60] = 8'b11111111;
    `checkh(vec, 2'b11);  // Const, select straddling LSB, OOB low+high

    vec = 2'b00;
    vec[60+:8] = 8'b11111111;
    `checkh(vec, 2'b11);  // Const, +: select straddling LSB, OOB low+high

`ifdef VERILATOR
    vec = 2'b00;
    vec[$c(-2)] = 1'b1;
    `checkh(vec, 2'b01);  // Var, single-bit select fully OOB low

    vec = 2'b00;
    vec[$c(60)+:8] = 8'b11111111;
    `checkh(vec, 2'b11);  // Var, +: select straddling LSB, OOB low+high
`endif

    narrow = 3'b000;
    narrow[65-:8] = 8'b11111111;
    `checkh(narrow, 3'b100);  // Const, -: select straddling LSB, non-power-of-2 width

    // verilator lint_on SELRANGE

    $write("*-* All finished *-*\n");
    $finish;
  end
endmodule
