module id32 (id34.id35 id36, output logic id64);
  id34 id39();
  assign id36.id42 = id39.id42;
  assign id64      = id39.id42;
endmodule

module id44 (id34.id45 id46, input logic id65, output logic id64);
  id34 id47();
  assign id46.id42 = id65;
  id32 id49 (.id36(id47.id35), .id64(id64));
endmodule

interface id34;
  logic id42;
  modport id35(output id42);
  modport id45(output id42);
endinterface
