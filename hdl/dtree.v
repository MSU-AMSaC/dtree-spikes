`default_nettype none
module dtree
 #( parameter FEATURES    = 3
  , parameter IN_WIDTH    = 10
  , parameter COEFF_WIDTH = 4
  )
  ( clk
  , reset

  , in_valid
  , ready
  , sample

  , level
  , path
  , out_valid
  );

  input  wire clk;
  input  wire reset;

  input  wire                         in_valid;
  output wire                         ready;
  input  wire[IN_WIDTH-1         : 0] sample;

  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */
  reg                          data_valid = 1'b0;
  reg [$clog2(FEATURES)-1 : 0] cycle_counter = 0;

  reg [IN_WIDTH-1         : 0] sample_register;
  reg [IN_WIDTH-1         : 0] multiplicand_register = 0;

  wire                             acc_load;
  wire                             acc_add;

  wire                             get_next_coeffs;
  wire                             child_direction;

  wire                             node_valid;
  wire[COEFF_WIDTH-1          : 0] coeff;
  wire                             is_one;
  wire                             is_zero;
  reg                              is_one_register = 1'b0;
  wire[IN_WIDTH-1             : 0] bias;

  wire                             mult_enable;
  reg                              mult_en_register = 1'b0;
  wire[COEFF_WIDTH+IN_WIDTH   : 0] product;
  wire[IN_WIDTH               : 0] scaled_product;
  wire[IN_WIDTH+1             : 0] product_plus_sample;
  wire                             prod_plus_sample_overflow;

  reg [IN_WIDTH               : 0] summand_register = 0;
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
  
    , .in_valid        (data_valid)
    , .child_direction (child_direction)

    , .ready           (ready)    
    , .load_bias       (acc_load)
    , .add             (acc_add)
    , .mult            (mult_enable)

    , .node_valid      (node_valid)
    , .coeff           (coeff)
    , .is_one          (is_one)
    , .is_zero         (is_zero)
    , .bias            (bias)
  
    , .level           (level)
    , .path            (path)
    , .out_valid       (out_valid)
    );

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          data_valid         <= 1'b0;
          sample_register <= 0;
          mult_en_register   <= 1'b0;
        end
      else
        begin
          data_valid         <= 1'b1;
          mult_en_register   <= mult_enable;
          if (in_valid == 1'b1)
            begin
              sample_register <= sample;
            end

          if (is_zero == 1'b0)
            begin
              if (mult_enable == 1'b1)
                begin
                  multiplicand_register <= sample_register;
                end
              else
                begin
                  if (node_valid == 1'b1)
                    begin
                      /* sign extend */
                      summand_register <= {sample_register[IN_WIDTH-1]
                                          , sample_register};
                    end
                end
            end
         
          is_one_register <= is_one;
        end
    end

  placeholder_mult
   #( .WIDTH_X(IN_WIDTH)
    , .WIDTH_A(COEFF_WIDTH)
    )
    multiply
    ( .x     (multiplicand_register)
    , .a     (coeff)

    , .y     (product)
    );
  assign scaled_product = product[IN_WIDTH+COEFF_WIDTH-1 -: IN_WIDTH];

  assign summand = (mult_en_register == 1'b1)
                   ? scaled_product
                   : ((is_one == 1'b1)
                     ? sample
                     : summand_register
                     )
                   ;
                 
  accumulator
   #( .IN_WIDTH (IN_WIDTH+1)
    )
    accumulate
    ( .clk      (clk)
    , .reset    (reset)

    , .load     (acc_load)
    , .add      (acc_add)

    , .init     ({ {2{bias[IN_WIDTH-1]}}
                 , bias
                 })
    , .a        (summand)
  
    , .y        (total)
    , .overflow (overflow)
    );
  assign child_direction = total[IN_WIDTH]; /* extract sign bit */
  
endmodule
