// DESCRIPTION: Check that a select reaching below the LSB of a 2-state vector
// reads as zero and drops the out of range bits on writes.
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv, expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d: $time=%0t got='h%x exp='h%x\n", `__FILE__,`__LINE__, $time, (gotv), (expv)); `stop; end while(0)
// verilog_format: on

class Index;
  // Not inlined, so the index stays a runtime value
  function int get(int v);
    return v;
  endfunction
endclass

module t;

  initial begin
    Index ng;
    bit [5:0] x;
    bit [95:0] y;
    bit [7:2] q;  // Non-zero declared lsb
    // verilator lint_off ASCRANGE
    bit [0:5] a;  // Ascending
    // verilator lint_on ASCRANGE

    // verilator lint_off SELRANGE
    x = 'h0;
    x[2:-2] = 5'b01001;
    `checkh(x, 6'b000010);  // Partially OOB low

    x = 'h0;
    x[-2:-7] = 6'b111111;
    `checkh(x, '0);  // Fully OOB low

    x = 'h0;
    x[7:-2] = 10'b1010101010;
    `checkh(x, 6'b101010);  // OOB at both ends

    x = 6'b111111;
    `checkh(x[3:-2], 6'b111100);  // Partially OOB low
    `checkh(x[-1:-6], 6'b000000);  // Fully OOB low
    `checkh(x[7:-2], 10'b0011111100);  // OOB at both ends

    q = 'h0;
    q[3:1] = 3'b111;
    `checkh(q, 6'b000011);  // Partially below the declared lsb

    q = 6'b111111;
    `checkh(q[3:1], 3'b110);  // Partially below the declared lsb

    a = 'h0;
    a[-2:1] = 4'b1111;
    `checkh(a, 6'b110000);  // Ascending, partially OOB low

    a = 6'b111111;
    `checkh(a[-2:1], 4'b0011);  // Ascending, partially OOB low

    // Wide
    y = 'h0;
    y[2:-2] = 5'b01001;
    `checkh(y, 96'h2);  // Partially OOB low

    y = 'h0;
    y[-2:-7] = 6'b111111;
    `checkh(y, '0);  // Fully OOB low

    y = 'h0;
    y[97:-2] = 100'h5555555555555555555555555;
    `checkh(y, 96'h555555555555555555555555);  // OOB at both ends

    y = ~'0;
    `checkh(y[3:-2], 6'b111100);  // Partially OOB low
    `checkh(y[-1:-6], 6'b000000);  // Fully OOB low
    `checkh(y[97:-2], 100'h3fffffffffffffffffffffffc);  // OOB at both ends

    // Runtime index.  The width of a select can't depend on a runtime value,
    // so a write that reaches below the object is dropped whole rather than
    // dropping only the bits that are out of range
    ng = new;

    x = 6'b010101;
    x[ng.get(-2)+:5] = 5'b01001;
    `checkh(x, 6'b010101);  // Partially OOB low, write dropped

    x = 6'b010101;
    x[ng.get(-7)+:6] = 6'b111111;
    `checkh(x, 6'b010101);  // Fully OOB low, write dropped

    x = 6'b010101;
    x[ng.get(1)-:4] = 4'b1011;
    `checkh(x, 6'b010101);  // Partially OOB low, -: form, write dropped

    x = 'h0;
    x[ng.get(2)+:3] = 3'b111;
    `checkh(x, 6'b011100);  // In range

    q = 6'b010101;
    q[ng.get(1)+:3] = 3'b111;
    `checkh(q, 6'b010101);  // Below the declared lsb, write dropped

    y = ~'0;
    y[ng.get(-2)+:5] = 5'b01001;
    `checkh(y, ~96'h0);  // Partially OOB low, wide, write dropped

    x = 6'b111111;
    `checkh(x[ng.get(-2)+:5], 5'b11100);  // Partially OOB low
    `checkh(x[ng.get(-6)+:5], 5'b00000);  // Fully OOB low
    `checkh(x[ng.get(-2)+:10], 10'b0011111100);  // OOB at both ends
    `checkh(x[ng.get(1)-:4], 4'b1100);  // Partially OOB low, -: form
    `checkh(x[ng.get(2)+:3], 3'b111);  // In range

    q = 6'b111111;
    `checkh(q[ng.get(1)+:3], 3'b110);  // Partially below the declared lsb

    y = ~'0;
    `checkh(y[ng.get(-2)+:6], 6'b111100);  // Partially OOB low, wide
    `checkh(y[ng.get(-6)+:5], 5'b00000);  // Fully OOB low, wide

    // verilator lint_on SELRANGE

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
