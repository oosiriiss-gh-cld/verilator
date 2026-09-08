// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t;

  initial begin
    bit [5:0] x;
    bit [1:0] z;

    // verilator lint_off SELRANGE
    {x[2:-2], z} = 7'b0100111;
    // verilator lint_on SELRANGE
  end
endmodule
