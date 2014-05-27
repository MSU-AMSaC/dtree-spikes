`default_nettype none
module accumulator
 #( parameter IN_WIDTH = 14
  )
  ( clk
  , reset

  , init
  , load
  , a

  , y
  , overflow
  );

  input  wire clk;
  input  wire reset;
  
  input  wire[IN_WIDTH   : 0] init;
  input  wire              load;
  input  wire[IN_WIDTH-1 : 0] a;
  
  output wire[IN_WIDTH   : 0] y;
  output wire              overflow;

  reg        [IN_WIDTH   : 0] acc = 0;
  wire       [IN_WIDTH+1 : 0] sum;

  assign y = acc;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          acc <= 0;
        end
      else
        begin
          if (load == 1'b1)
            begin
              acc <= init;
            end
          else
            begin
              acc <= sum[IN_WIDTH : 0];
            end
        end
    end

  adder 
   #( .IN_WIDTH (IN_WIDTH+1)
    )
   adder_instance
   ( .a (acc)
   , .b ({a[IN_WIDTH-1], a}) /* sign extension */

   , .y (sum)
   , .v (overflow)
   );

endmodule
