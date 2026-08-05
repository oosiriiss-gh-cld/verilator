// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk
);

  reg [7:0] arr[0:9];

  always @(posedge clk) begin
    arr[-5] = 8'h00;  // must be an error here, index is constant and out of range
  end
endmodule
