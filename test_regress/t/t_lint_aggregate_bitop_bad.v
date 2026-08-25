// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

module t;
   logic arr[3];
   logic x, y, z;

   initial begin
      y = arr & x;
      z = arr + x;
   end
endmodule
