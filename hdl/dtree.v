/* dtree.v
 * Top level module for an oblique decision tree neural spike classification
 * hardware module.
 */
`default_nettype none
module dtree
 #( parameter FEATURES      = 3  /* input features to consider */
  , parameter IN_WIDTH      = 10 /* bit width of features */
  , parameter COEFF_WIDTH   = 2  /* bit width of hyperplane coefficients */
  , parameter BIAS_WIDTH    = 10 /* bit width of hyperplane bias */
  , parameter MAX_CLUSTERS  = 5  /* more than 5 is not presently supported */
  , parameter CHANNEL_COUNT = 4  /* # of copies, for power/area comparison */
  )
  ( clk
  , reset

  , wr_node
  , node_addr
  , node_data_in

  , in_valid
  , ready
  , sample

  , level
  , path
  , out_valid
  );

  localparam NODE_SIZE = 2 +
                         FEATURES +
                         (FEATURES-1)*COEFF_WIDTH +
                         BIAS_WIDTH +
                         1;

  input  wire clk;
  input  wire reset;

  /* for initializing the coefficient memory */
  input  wire                                            wr_node;
  input  wire [$clog2(CHANNEL_COUNT*MAX_CLUSTERS)-1 : 0] node_addr;
  input  wire [NODE_SIZE-1                          : 0] node_data_in;

  input  wire                                            in_valid;
  output wire                                            ready;
  input  wire[IN_WIDTH-1         : 0]                    sample;

  /* how deep did we make it down the tree? */
  output wire[$clog2(FEATURES)-1 : 0]                    level;
  /* what branch was taken at each node? */
  output wire[$clog2(FEATURES)-1 : 0]                    path;
  output wire                                            out_valid;

  /*******************************************************************/
  wire                                            ccore_ready;
  reg                                             data_valid = 1'b0;
  reg [$clog2(FEATURES)-1 : 0]                    cycle_counter = 0;

  reg [IN_WIDTH-1         : 0]                    sample_register;
  reg [IN_WIDTH-1         : 0]                    multiplicand_register = 0;

  wire                                            acc_load;
  wire                                            acc_add;

  wire                                            get_next_coeffs;
  wire                                            child_direction;

  wire [$clog2(CHANNEL_COUNT)-1 : 0]              ch_index;
  wire [$clog2(FEATURES)-1      : 0]              node_index;
  wire [NODE_SIZE-1             : 0]              node_data_out;

  wire                                            coeff_mem_ce;
  wire                                            coeff_mem_we;
  wire [$clog2(MAX_CLUSTERS*CHANNEL_COUNT)-1 : 0] coeff_mem_a;
  wire [NODE_SIZE-1                          : 0] coeff_mem_q;

  reg                                             node_mem_full = 1'b0;
  reg  [$clog2(CHANNEL_COUNT*MAX_CLUSTERS)-1 : 0] node_counter  = 0;

  wire                                            node_valid;
  wire[COEFF_WIDTH-1          : 0]                coeff;
  wire                                            is_one;
  wire                                            is_zero;
  reg                                             is_one_register = 1'b0;
  wire[BIAS_WIDTH-1           : 0]                bias;

  wire                                            mult_enable;
  reg                                             mult_en_register = 1'b0;

  wire signed [COEFF_WIDTH+IN_WIDTH-1 : 0]        product;
  wire signed [IN_WIDTH-1             : 0]        scaled_product;

  wire        [IN_WIDTH-2             : 0]        shifted;

  reg  signed [IN_WIDTH               : 0]        summand_register = 0;
  wire signed [IN_WIDTH               : 0]        summand;
  wire signed [IN_WIDTH+1             : 0]        total;
  wire                                            overflow;

  assign ready = ccore_ready & node_mem_full;

  assign coeff_mem_a = (node_mem_full == 1'b0)
                     ? node_counter
                     : ch_index*MAX_CLUSTERS + node_index;

  /* simulate an addressable memory using flip-flops */
  memory_model
    #( .DEPTH           (NODE_SIZE)
     , .WORDS           (MAX_CLUSTERS*CHANNEL_COUNT)
     )
     mem_instance
     ( .clk   (clk)
     , .reset (reset)

     , .ce    (coeff_mem_ce)
     , .we    (wr_node)
     , .a     (coeff_mem_a)
     , .d     (node_data_in)
     , .q     (node_data_out)
     );

  control
   #( .FEATURES      (FEATURES)
    , .COEFF_WIDTH   (COEFF_WIDTH)
    , .BIAS_WIDTH    (BIAS_WIDTH)
    , .MAX_CLUSTERS  (MAX_CLUSTERS)
    , .CHANNEL_COUNT (CHANNEL_COUNT)
    )
    controller
    ( .clk             (clk)
    , .reset           (reset)

    , .mem_ready       (node_mem_full)
    , .in_valid        (data_valid)
    , .child_direction (child_direction)

    , .ccore_ready     (ccore_ready)
    , .load_bias       (acc_load)
    , .add             (acc_add)
    , .mult            (mult_enable)

    , .ch_index        (ch_index)
    , .node_index      (node_index)
    , .read_mem        (coeff_mem_ce)
    , .node_data       (node_data_out)

    , .node_valid      (node_valid)
    , .coeff           (coeff)
    , .is_one          (is_one)
    , .is_zero         (is_zero)
    , .bias            (bias)

    , .level           (level)
    , .path            (path)
    , .out_valid       (out_valid)
    );

  /* process to allow memory initialization */
  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          data_valid         <= 1'b0;
          sample_register    <= 0;
          mult_en_register   <= 1'b0;

          node_mem_full      <= 1'b0;
          node_counter       <= 0;
        end
      else
        begin
          if (node_mem_full == 1'b0)
            begin
              if (wr_node == 1'b1)
                begin
                  if (node_counter == (MAX_CLUSTERS*CHANNEL_COUNT)-1)
                    begin
                      node_counter  <= 0;
                      node_mem_full <= 1'b1;
                    end
                  else
                    begin
                      node_counter  <= node_counter + 1;
                      node_mem_full <= 1'b0;
                    end
                end
            end
          else
            begin
              node_mem_full <= 1'b1;

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
                      multiplicand_register <= sample;
                    end
                  else
                    begin
                      if (node_valid == 1'b1)
                        begin
                          /* sign extend */
                          summand_register <= {sample[IN_WIDTH-1], sample};
                        end
                    end
                end

              is_one_register <= is_one;
            end
        end
    end

  /* when coefficients can only be 1 or 2 bits it is not necessary to
   * do a full signed integer multiplication
   */
  generate
  if (COEFF_WIDTH > 2)
    begin: GENERATE_SIGNED_MULTIPLY
      placeholder_mult
       #( .WIDTH_X(IN_WIDTH)
        , .WIDTH_A(COEFF_WIDTH)
        )
        multiply
        ( .x     (multiplicand_register)
        , .a     (coeff)
        , .y     (product)
        );
      assign scaled_product = product[IN_WIDTH+COEFF_WIDTH-2 -: IN_WIDTH];
    end
  else
    begin: GENERATE_SIGNED_SHIFT
      signed_div_2
       #( .WIDTH (IN_WIDTH)
        )
        divide
        ( .x   (multiplicand_register)
        , .sgn (coeff[COEFF_WIDTH-1])
        , .y   (shifted)
        );
      assign scaled_product = {shifted[IN_WIDTH-2], shifted};
    end
  endgenerate

  assign summand = (mult_en_register == 1'b1)
                   ? {scaled_product[IN_WIDTH-1], scaled_product}
                   : ((is_one == 1'b1)
                     ? {sample[IN_WIDTH-1], sample}
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
