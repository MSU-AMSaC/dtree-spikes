`default_nettype none
module accumulator
 #( parameter IN_WIDTH = 14
  )
  ( clk
  , reset

  , load
  , add

  , init
  , a

  , y
  , overflow
  );

  input  wire clk;
  input  wire reset;
  
  input  wire                 load;
  input  wire                 add;

  input  wire[IN_WIDTH   : 0] init;
  input  wire[IN_WIDTH-1 : 0] a;
  
  output wire[IN_WIDTH   : 0] y;
  output wire              overflow;

  reg        [IN_WIDTH   : 0] acc = 0;

  wire       [IN_WIDTH   : 0] left_summand;
  wire       [IN_WIDTH   : 0] right_summand;
  wire       [IN_WIDTH+1 : 0] sum;

  assign y = acc;//sum;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          acc <= 0;
        end
      else
        begin
          acc <= sum[IN_WIDTH : 0];
        end
    end

  assign left_summand  = (load == 1'b1)
                       ? init
                       : acc;
  assign right_summand = (add  == 1'b1)
                       ? {a[IN_WIDTH-1], a} /* sign extension */
                       : {IN_WIDTH{1'b0}};
  adder 
   #( .IN_WIDTH (IN_WIDTH+1)
    )
   adder_instance
   ( .a (left_summand)
   , .b (right_summand) 

   , .y (sum)
   , .v (overflow)
   );

endmodule
