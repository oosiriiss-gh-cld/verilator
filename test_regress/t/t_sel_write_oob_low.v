// DESCRIPTION: Check that a part-select whose LSB is below the vector's bit
// 0 (negative, or otherwise out of range on the low side) reads/writes only
// the in-range bits, for both narrow and wide vectors, whether the LSB is a
// constant or a runtime (signed or unsigned) expression.
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv, expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got='h%x exp='h%x\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

class num_gen;
  function int getSigned(int num);
    return num;
  endfunction
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

    // Writes
    x = 'h0;
    x[2:-2] = 5'b001001;
    `checkh(x, 6'b000010);  // Const, partially OOB low
    x = 'h0;
    x[-2:-7] = 6'b111111;
    `checkh(x, '0);  // Const, fully OOB low
    x = 'h0;
    x[i.getSigned(-2)+:5] = 5'b001001;
    `checkh(x, 6'b000010);  // Signed var, partially OOB low
    x = 'h0;
    x[i.getSigned(-7)+:6] = 6'b111111;
    `checkh(x, '0);  // Signed var, fully OOB low
    x = 'h0;
    x[i.getUnsigned(1)+:2] = 2'b11;
    `checkh(x, 6'b000110);  // Unsigned var, in bounds

    // Reads
    x = 6'b111111;
    `checkh(x[3:-2], 6'b111100);  // Const, partially OOB low
    `checkh(x[-1:-6], 6'b000000);  // Const, fully OOB low
    `checkh(x[i.getSigned(-3)+:6], 6'b111000);  // Signed var, partially OOB low
    `checkh(x[i.getSigned(-7)+:6], 6'b000000);  // Signed var, fully OOB low
    `checkh(x[i.getUnsigned(1)+:6], 6'b011111);  // Unsigned var, in bounds

    // Wide writes
    y = 'h0;
    y[2:-2] = 5'b001001;
    `checkh(y, 96'b000010);  // Const, partially OOB low
    y = 'h0;
    y[-2:-7] = 6'b111111;
    `checkh(y, '0);  // Const, fully OOB low
    y = 'h0;
    y[i.getSigned(-2)+:5] = 5'b001001;
    `checkh(y, 96'b000010);  // Signed var, partially OOB low
    y = 'h0;
    y[i.getSigned(-7)+:6] = 6'b111111;
    `checkh(y, '0);  // Signed var, fully OOB low
    y = 'h0;
    y[i.getUnsigned(1)+:2] = 2'b11;
    `checkh(y, 96'b000110);  // Unsigned var, in bounds

    // Wide reads
    y = ~'0;
    `checkh(y[3:-2], 6'b111100);  // Const, partially OOB low
    `checkh(y[-1:-6], 6'b000000);  // Const, fully OOB low
    `checkh(y[i.getSigned(-3)+:6], 6'b111000);  // Signed var, partially OOB low
    `checkh(y[i.getSigned(-7)+:6], 6'b000000);  // Signed var, fully OOB low
    // y is 96 bits wide, so unlike the x case above, bit 6 is in range here
    `checkh(y[i.getUnsigned(1)+:6], 6'b111111);  // Unsigned var, in bounds

    $write("*-* All finished *-*\n");
    $finish;
  end
endmodule
