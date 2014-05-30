`default_nettype none
module placeholder_mult
 #( parameter WIDTH_X = 10
  , parameter WIDTH_A = 4
  )
  ( clk
  , reset
  
  , en

  , x
  , a

  , y
  );

  input  wire clk;
  input  wire reset;
  
  input  wire en;

  input  wire signed [WIDTH_X-1 : 0] x;
  input  wire signed [WIDTH_A-1 : 0] a;
  
  output wire signed [WIDTH_X + WIDTH_A : 0] y;

  /* module body */
  reg  signed [WIDTH_X + WIDTH_A-1 : 0] product = 0;

  assign y        = (en == 1'b1)
                  ? a*x
                  : 0;

endmodule
