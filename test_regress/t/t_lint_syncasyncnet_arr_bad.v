// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

module t (
    input clk,
    input rst_both_l,
    input idx,
    input d
);
  reg mem[0:1];
  reg q;

  always @(posedge clk or negedge rst_both_l) begin
    q <= (~rst_both_l) ? 1'b0 : d;
  end

  always @(posedge clk) begin
    mem[idx] <= rst_both_l ? d : 1'b0;
  end

endmodule
