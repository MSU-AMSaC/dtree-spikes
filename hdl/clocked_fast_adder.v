module clocked_fast_adder
 #( parameter IN_WIDTH = 11
  )
  ( clk
  , reset

  , a
  , b
  , y
  );

  input wire clk;
  input wire reset;

  input  wire signed [IN_WIDTH-1 : 0] a;
  input  wire signed [IN_WIDTH-1 : 0] b;
  output reg  signed [IN_WIDTH   : 0] y;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          y <= 0;
        end
      else
        begin
          y <= a + b;
        end
    end

endmodule


