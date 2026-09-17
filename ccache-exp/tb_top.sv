// DESCRIPTION: Verilator ccache experiment: example top level
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-License-Identifier: CC0-1.0
//
// Top has no ports so that --main can generate a main() for it.

// verilator lint_off UNUSEDSIGNAL
// verilator lint_off DECLFILENAME

module tb_top;

  import uvm_pkg::*;
  import tb_pkg::*;

  logic       clk = 1'b0;
  logic       rst_n = 1'b0;
  logic [7:0] din = 8'h01;
  logic [7:0] dout;

  dut u_dut (
      .clk  (clk),
      .rst_n(rst_n),
      .din  (din),
      .dout (dout)
  );

  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
    for (int i = 0; i < 32; i++) begin
      @(posedge clk);
      din <= din + 8'd1;
    end
    run_test("test");
  end

endmodule
