// DESCRIPTION: Verilator: Verilog Test module
//
// Check reads and writes of a part select that reaches below bit 0
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv, expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got='h%x exp='h%x\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

class num_gen;
  function int unsigned getUnsigned(int unsigned num);
    return num;
  endfunction
endclass

module t;
  initial begin
    bit [5:0] x;
    bit [95:0] y;  // Wide
    num_gen i;
    i = new;

    // verilator lint_off SELRANGE
    // Writes
    x = 'h0;
    x[2:-2] = 5'b001001;
    `checkh(x, 6'b000010);  // Partially below bit 0
    x = 'h0;
    x[-2:-7] = 6'b111111;
    `checkh(x, '0);  // Wholly below bit 0
    x = 'h0;
    x[i.getUnsigned(1)+:2] = 2'b11;
    `checkh(x, 6'b000110);  // Variable index, in bounds

    // Reads
    x = 6'b111111;
    `checkh(x[3:-2], 6'b111100);  // Partially below bit 0
    `checkh(x[-1:-6], 6'b000000);  // Wholly below bit 0
    `checkh(x[i.getUnsigned(1)+:6], 6'b011111);  // Variable index, in bounds

    // Wide
    // Writes
    y = 'h0;
    y[2:-2] = 5'b001001;
    `checkh(y, 96'b000010);  // Partially below bit 0
    y = 'h0;
    y[-2:-7] = 6'b111111;
    `checkh(y, '0);  // Wholly below bit 0
    y = 'h0;
    y[i.getUnsigned(1)+:2] = 2'b11;
    `checkh(y, 96'b000110);  // Variable index, in bounds

    // Reads
    y = ~'0;
    `checkh(y[3:-2], 6'b111100);  // Partially below bit 0
    `checkh(y[-1:-6], 6'b000000);  // Wholly below bit 0
    `checkh(y[i.getUnsigned(1)+:6], 6'b111111);  // Variable index, in bounds
    // verilator lint_on SELRANGE

    // A run-time index that goes negative is not handled here; the index is
    // truncated to the width needed to address the source, so the select reads
    // as out of range instead.

    $write("*-* All finished *-*\n");
    $finish;
  end
endmodule
