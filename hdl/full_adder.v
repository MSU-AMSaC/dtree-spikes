module full_adder
  ( a
  , b
  , c_in
  
  , s
  , c_out
  );

  input  wire a;
  input  wire b;
  input  wire c_in;

  output wire s;
  output wire c_out;

  wire s_1;
  wire c_1;
  wire c_2;

  half_adder half_1
    ( .a (a)
    , .b (b)
    , .s (s_1)
    , .c (c_1)
    );

  half_adder half_2
    ( .a (s_1)
    , .b (c_in)
    , .s (s)
    , .c (c_2)
    );

  assign c_out = c_1 | c_2;

endmodule
