// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

interface Iface;
   logic sig;
   modport mp(output sig);
endinterface

module Mid (Iface.mp io_out, output logic obs);
   Iface loc();  // loc.sig is never driven by anything
   assign io_out.sig = loc.sig;
   assign obs = loc.sig;
endmodule

// 't' has an interface modport port, and as the top module that port is
// unconnected.  Writes through it must not land on some unrelated interface
// instance elsewhere in the design.
module t (Iface.mp io_top);
   logic d = 1'b1;
   logic obs;

   Iface inner();

   assign io_top.sig = d;

   Mid u_mid (.io_out(inner.mp), .obs(obs));

   initial begin
      // u_mid.loc.sig has no driver, so obs must not track 'd'
      if (obs !== 1'b0) begin
         $write("%%Error: obs=%b follows 'd' written to the unconnected top-level interface port\n", obs);
         $stop;
      end
      $write("*-* All Finished *-*\n");
      $finish;
   end
endmodule
