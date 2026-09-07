// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

module t (
  input clk_i,
  input rst_ni,
  input d_i,
  output reg q_async_o,
  output reg q_sync_o
);
/* verilator no_inline_module */
// no-inline to root module

  // Asynchronous reset usage of 'rst_ni'
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      q_async_o <= 1'b0;
    end
    else begin
      q_async_o <= d_i;
    end
  end

  // Synchronous reset usage of 'rst_ni', reached through an alias that V3Dfg
  // substitutes away.  The warning must still point at the reference below,
  // and not at the declaration of 'rst_ni'.
  logic rst_n_alias;
  assign rst_n_alias = rst_ni;
  always_ff @(posedge clk_i) begin
    if (!rst_n_alias) begin
      q_sync_o <= 1'b0;
    end
    else begin
      q_sync_o <= d_i;
    end
  end

endmodule
