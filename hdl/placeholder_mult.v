`default_nettype none
module placeholder_mult
 #( parameter WIDTH_X = 10
  , parameter WIDTH_A = 4
  )
  ( clk
  , reset
  
  , x
  , a

  , y
  );

  input  wire clk;
  input  wire reset;
  
  input  wire [WIDTH_X-1 : 0] x;
  input  wire [WIDTH_A-1 : 0] a;
  
  output wire signed [WIDTH_X + WIDTH_A : 0] y;

  /* module body */
  wire signed [WIDTH_X : 0] signed_x;
  wire signed [WIDTH_A : 0] signed_a;

  reg  signed [WIDTH_X + WIDTH_A : 0] product = 0;
  
  assign signed_a = a;
  assign signed_x = x;
  assign y        = product;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          product <= 0;
        end 
      else
        begin
          product <= signed_a * signed_x;
        end
    end

endmodule
