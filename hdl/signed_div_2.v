/* signed_div_2.v
 * Compute division by 2 using a right-shift, taking care of the sign bit.
 * This enables us to multiply by a fractional 2-bit number without an
 * actual multiplication circuit.
 */
module signed_div_2
 #( parameter WIDTH = 10
  )
  ( x
  , sgn
  , y
  );

  input  wire signed [WIDTH-1 : 0] x;
  input  wire sgn;
  output wire signed [WIDTH-2 : 0] y;

  assign y = {sgn ^ x[WIDTH-1], x[WIDTH-3 : 0]};

endmodule
