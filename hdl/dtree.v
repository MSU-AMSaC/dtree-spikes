`default_nettype none
module dtree
 #( parameter FEATURES    = 3
  , parameter IN_WIDTH    = 10
  , parameter COEFF_WIDTH = 4
  )
  ( clk
  , reset

  , sample

  , level
  , path
  , out_valid
  );

  input  wire clk;
  input  wire reset;

  input  wire[IN_WIDTH-1         : 0] sample;

  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */
  reg[$clog2(FEATURES)-1 : 0] cycle_counter = 0;

  wire                             load_acc;
  wire                             get_next_coeffs;
  wire                             child_direction;
  wire[COEFF_WIDTH-1          : 0] coeff;
  wire                             is_one;
  wire[IN_WIDTH-1             : 0] bias;
  wire[COEFF_WIDTH+IN_WIDTH   : 0] product;
  wire[IN_WIDTH               : 0] summand;
  wire[IN_WIDTH+1             : 0] total;
  wire                             overflow;

  control
   #( .FEATURES        (3)
    , .COEFF_BIT_DEPTH (4)
    , .BIAS_BIT_DEPTH  (10)
    )
    controller
    ( .clk             (clk)
    , .reset           (reset)
  
    , .next            (get_next_coeffs)
    , .child_direction (child_direction)
    
    , .coeff           (coeff)
    , .is_one          (is_one)
    , .bias            (bias)
  
    , .level           (level)
    , .path            (path)
    , .out_valid       (out_valid)
    );

  placeholder_mult
   #( .WIDTH_X(IN_WIDTH)
    , .WIDTH_A(COEFF_WIDTH)
    )
    multiply
    ( .clk   (clk)
    , .reset (reset)
  
    , .x     (sample)
    , .a     (coeff)

    , .y     (product)
    );

  assign summand = (is_one == 1'b1)
                 ? {sample[IN_WIDTH-1], sample}
                 : product[IN_WIDTH+COEFF_WIDTH-1 : COEFF_WIDTH-1];
                 
  accumulator
   #( .IN_WIDTH (IN_WIDTH+1)
    )
    accumulate
    ( .clk      (clk)
    , .reset    (reset)
  
    , .init     ({ {2{bias[IN_WIDTH-1]}}
                 , bias
                 })
    , .load     (load_acc)
    , .a        (summand)
  
    , .y        (total)
    , .overflow (overflow)
    );
  assign child_direction = total[IN_WIDTH];
  
endmodule
