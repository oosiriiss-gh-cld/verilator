// DESCRIPTION: Verilator ccache experiment: example DUT
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0
//
// Plain RTL modules. The point of this file is that module headers (unlike
// class headers) get pulled into V<prefix>__Syms.h by
// src/V3EmitCSyms.cpp:943-947, and __Syms.h is reached from every generated
// .cpp via __pch.h. So edits here are predicted to have a far larger ccache
// blast radius than edits in tb_pkg.sv.
//
// The "bonus" / "extra_lane_out" signals exist so that run_experiment.sh can
// splice in a NEW signal or a NEW instance that is genuinely live. A dangling
// signal would just be optimized away, and the experiment would measure
// nothing.
//
// Lines tagged EXP:... are edit points used by run_experiment.sh. Do not
// reword them.

// verilator lint_off UNUSEDSIGNAL
// verilator lint_off DECLFILENAME

module dut_lane #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  logic [WIDTH-1:0] stage0;
  logic [WIDTH-1:0] stage1;
  logic [WIDTH-1:0] accum;
  logic [WIDTH-1:0] bonus;

  assign bonus = '0;  // EXP:DUT_SIGNAL

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage0 <= '0;
      stage1 <= '0;
      accum  <= '0;
    end else begin
      stage0 <= din;
      stage1 <= stage0 ^ {stage0[WIDTH-2:0], stage0[WIDTH-1]};
      accum  <= accum + stage1;
    end
  end

  assign dout = accum ^ bonus;

endmodule

module dut (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] din,
    output logic [7:0] dout
);

  logic [7:0] lane_out[4];
  logic [7:0] extra_lane_out;

  dut_lane #(.WIDTH(8)) lane0 (.clk(clk), .rst_n(rst_n), .din(din),         .dout(lane_out[0]));
  dut_lane #(.WIDTH(8)) lane1 (.clk(clk), .rst_n(rst_n), .din(lane_out[0]), .dout(lane_out[1]));
  dut_lane #(.WIDTH(8)) lane2 (.clk(clk), .rst_n(rst_n), .din(lane_out[1]), .dout(lane_out[2]));
  dut_lane #(.WIDTH(8)) lane3 (.clk(clk), .rst_n(rst_n), .din(lane_out[2]), .dout(lane_out[3]));

  assign extra_lane_out = '0;  // EXP:DUT_INSTANCE

  assign dout = lane_out[3] ^ extra_lane_out;

endmodule
