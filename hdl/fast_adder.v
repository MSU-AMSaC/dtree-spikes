/* fast_adder.v
 * Allow the synthesizer to generate a fast combinational adder.
 */
module fast_adder
#( parameter IN_WIDTH = 8
  , parameter SIGNED   = 1'b1
  )
  ( a
  , b

  , y
  );

  input  wire signed [IN_WIDTH-1 : 0] a;
  input  wire signed [IN_WIDTH-1 : 0] b;

  output wire signed [IN_WIDTH   : 0] y;

  assign y = a + b;

endmodule
