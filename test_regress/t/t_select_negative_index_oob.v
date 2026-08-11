// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t (
    input arr[7],
    input arr2[2:-2],
    input arr3[6:2],
    input [4:0] vec,
    output out,
    output out2,
    output out3,
    output [2:0] out4,
    output [4:0] out5
);
  assign out = arr[-1];
  assign out2 = arr2[-3];
  assign out3 = arr3[-1];
  assign out4 = vec[-1:-3];
  assign out5 = vec[2:-2];
endmodule
