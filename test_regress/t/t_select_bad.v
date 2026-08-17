// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2026 by Antmicro.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

function automatic logic sink(logic v);
  return v;
endfunction

// We don't care about the result so just cast to logic to keep one function
// for simplicity. Cannot cast expression to void as it is currently a syntax
// error.
`define s(expr) void'(sink(logic'(expr)));

module t;
  // Unpacked
  logic arr1[7];
  logic arr2[5:9];  // High declared range
  logic arr3[-2:2];  // Negative declared range
  //// Packed
  bit [6:0] vec1;
  bit [9:5] vec2;
  bit [2:-2] vec3;
  //// Unpacked with packed
  bit [3:0] arr4[5];
  bit [3:0] arr5[6:10];
  bit [3:0] arr6[-3:4];
  //// Packed with packed
  bit [4:0][3:0] vec4;
  bit [10:6][3:0] vec5;
  bit [4:-3][3:0] vec6;

  initial begin
    `s(arr1[-1] | arr1[8])  // low/high
    `s(arr1[-2:2] | arr1[-6:-2])  // partial/full OOB low
    `s(arr1[5:8] | arr1[8:11])  // partial/full OOB high

    `s(arr2[4] | arr2[10])
    `s(arr2[3:7] | arr2[-1:3])
    `s(arr2[8:11] | arr2[11:14])

    `s(arr3[-3] | arr3[3])
    `s(arr3[-4:0] | arr3[-8:-4])
    `s(arr3[1:4] | arr3[4:7])

    `s(vec1[-1] | vec1[7])
    `s(vec1[2:-2] | vec1[-2:-6])
    `s(vec1[8:5] | vec1[11:8])

    `s(vec2[4] | vec2[10])
    `s(vec2[7:3] | vec2[3:-1])
    `s(vec2[11:8] | vec2[14:11])

    `s(vec3[-3] | vec3[3])
    `s(vec3[0:-4] | vec3[-4:-8])
    `s(vec3[4:1] | vec3[7:4])

    `s(arr4[-1] | arr4[5])
    `s(arr4[-2:2] | arr4[-6:-2])
    `s(arr4[3:6] | arr4[6:9])

    `s(arr5[5] | arr5[11])
    `s(arr5[4:8] | arr5[0:4])
    `s(arr5[9:12] | arr5[12:15])

    `s(arr6[-4] | arr6[5])
    `s(arr6[-5:-1] | arr6[-9:-5])
    `s(arr6[3:6] | arr6[6:9])

    `s(vec4[-1] | vec4[5])
    `s((vec4[2:-2] | vec4[-2:-6]))
    `s((vec4[6:3] | vec4[9:6]))

    `s(vec5[5] | vec5[11])
    `s((vec5[8:4] | vec5[4:0]))
    `s((vec5[12:9] | vec5[15:12]))

    `s(vec6[-4] | vec6[5])
    `s((vec6[-1:-5] | vec6[-5:-9]))
    `s((vec6[6:3] | vec6[9:6]))


    // Non-32-bit index
    `s(vec1[8'h01])
    `s(arr1[8'h01])

    // Packed tristate
    `s(vec1[(1'h0/1'b0)])
    `s(vec1[71:(1'h0/1'b0)])
    `s(vec1[(1'h0/1'b0):71])
    `s(vec1[(1'h0/1'b0)+:2])
    `s(vec1[2+:(1'h0/1'b0)])
    `s(vec1[(1'h0/1'b0)-:2])
    `s(vec1[2-:(1'h0/1'b0)])

    // Unpacked tristate
    `s(arr1[(1'h0/1'b0)])
    `s(arr1[71:(1'h0/1'b0)])
    `s(arr1[(1'h0/1'b0):71])
    `s(arr1[(1'h0/1'b0)+:2])
    `s(arr1[2+:(1'h0/1'b0)])
    `s(arr1[(1'h0/1'b0)-:2])
    `s(arr1[2-:(1'h0/1'b0)])
  end
endmodule
