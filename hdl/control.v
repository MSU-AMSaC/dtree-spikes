`default_nettype none
module control
 #( parameter FEATURES        = 3
  , parameter COEFF_BIT_DEPTH = 4
  , parameter BIAS_BIT_DEPTH  = 10
  )
  ( clk
  , reset

  , next
  , child_direction
  
  , coeff
  , is_one
  , bias

  , level
  , path
  , out_valid
  );

  input  wire clk;
  input  wire reset;

  input  wire next;
  input  wire child_direction;
  
  output wire[COEFF_BIT_DEPTH-1  : 0] coeff;
  output wire                         is_one;

  output wire[BIAS_BIT_DEPTH-1   : 0] bias;
  
  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */
  reg [COEFF_BIT_DEPTH-1 : 0] coeff_i  = 0;
  reg                         is_one_i = 1'b0;
 
  assign coeff  = coeff_i;
  assign is_one = is_one_i;
  assign bias   = 1234;  

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          coeff_i  <= 0;
          is_one_i <= 1'b0;
        end
      else
        begin
          if (coeff_i == {COEFF_BIT_DEPTH{1'b1}})
            begin
              coeff_i  <= 0;
              is_one_i <= 1'b1;
            end
          else
            begin
              coeff_i  <= coeff_i + 1;
              is_one_i <= 1'b0;
            end
        end
    end  
endmodule
