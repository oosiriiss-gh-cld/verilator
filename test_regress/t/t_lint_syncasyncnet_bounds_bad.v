// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain
// SPDX-FileCopyrightText: 2026 Antmicro
// SPDX-License-Identifier: CC0-1.0

// A genuine synchronous + asynchronous reset mix on 'rst_n'.  The memory depth
// is not a power of two, so the write statement is wrapped in a generated
// bounds-check 'if' and the synchronous reset read rides along inside it.
// SYNCASYNCNET must still be reported: only assertion logic is exempt, not
// everything Verilator happens to wrap in a generated 'if'.

module t (
    input        clk,
    input        rst_n,
    input  [2:0] waddr,
    input  [7:0] d,
    output logic [7:0] o
);
  logic [7:0] mem [0:5];

  always_ff @(posedge clk) begin
    // Synchronous use of rst_n
    mem[waddr] <= rst_n ? d : 8'h00;
  end

  // Asynchronous use of rst_n
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) o <= 8'h00;
    else o <= mem[waddr];
  end
endmodule
