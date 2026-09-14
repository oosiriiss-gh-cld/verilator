// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk,
    input rst,
    output reg out
);
  /* verilator no_inline_module */
  // no-inline to root module
  logic lfsr_d;
  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      lfsr_d <= lfsr_d;
    end
  end
  always_ff @(posedge clk) begin
    out <= (rst) ? 0 : 1;
  end
endmodule
