module id32 (id34.id35 id36);
  id34 id39();
  assign id39.id42 = 1'b0;
  assign id36.id42 = id39.id42;
endmodule

module id44 (id34.id45 id46);
  id34 id47();
  assign id46.id42 = id47.id42;
  id32 id49 (.id36(id47.id35));
endmodule

interface id34;
  logic id42;
  modport id35(output id42);
  modport id45(output id42);
endinterface
