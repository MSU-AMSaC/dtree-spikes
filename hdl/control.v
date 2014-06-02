`default_nettype none
module control
 #( parameter FEATURES        = 3
  , parameter COEFF_BIT_DEPTH = 4
  , parameter BIAS_BIT_DEPTH  = 10
  , parameter MAX_CLUSTERS    = 5
  )
  ( clk
  , reset

  , next
  , child_direction
  
  , load_bias
  , add
  , mult

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
  
  output reg                          load_bias;
  output reg                          add;
  output reg                          mult;

  output wire[COEFF_BIT_DEPTH-1  : 0] coeff;
  output wire                         is_one;

  output wire[BIAS_BIT_DEPTH-1   : 0] bias;
  
  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */
  reg [ 2                            /* indicates whether the child is present */
      + FEATURES                     /* one-hot encoded position of 1 coeff */
      + (FEATURES-1)*COEFF_BIT_DEPTH /* the other coefficients */
      + BIAS_BIT_DEPTH               /* the bias weight */
      : 0] coeff_memory [0 : MAX_CLUSTERS-1];

  initial 
  begin
    $readmemh("tree.txt", coeff_memory);
  end

  `define lookup_child_flags(node)               \
     coeff_memory[node]                          \
                 [  2                            \
                 +  FEATURES                     \
                 +  (FEATURES-1)*COEFF_BIT_DEPTH \
                 +  BIAS_BIT_DEPTH               \
                -: 2 ]

  `define lookup_one_pos(node)                    \
     coeff_memory[node]                           \
                 [  2                             \
                 +  FEATURES                      \
                 +  (FEATURES-1)*COEFF_BIT_DEPTH  \
                 +  BIAS_BIT_DEPTH                \
                 -  2                             \
                 -: FEATURES ]

  `define lookup_coeff(node, coeff)              \
     coeff_memory[node]                          \
                 [  2                            \
                 +  FEATURES                     \
                 +  (FEATURES-1)*COEFF_BIT_DEPTH \
                 +  BIAS_BIT_DEPTH               \
                 -  2                            \
                 -  FEATURES                     \
                 -  COEFF_BIT_DEPTH*coeff        \
                 -: COEFF_BIT_DEPTH ]

  `define lookup_bias(node)                      \
     coeff_memory[node]                          \
                 [  2                            \
                 +  FEATURES                     \
                 +  (FEATURES-1)*COEFF_BIT_DEPTH \
                 +  BIAS_BIT_DEPTH               \
                 -  2                            \
                 -  FEATURES                     \
                 -  COEFF_BIT_DEPTH*(FEATURES-1) \
                -: BIAS_BIT_DEPTH ]
 
  localparam TREE_HEIGHT = $clog2(MAX_CLUSTERS);
  reg [TREE_HEIGHT-1        : 0] node_index;
  reg [$clog2(FEATURES-1)-1 : 0] coeff_index = 0;
    
  localparam STATE_DECIDE = 0
           , STATE_INDEX  = 1
           ;

  reg [$clog2(STATE_INDEX)-1 : 0] state = STATE_DECIDE;

  reg                               first_cycle = 1'b1;
  reg                               done        = 1'b0;

  reg [1                  : 0] child_flags      = 0;
  reg                          child_valid;

  reg [BIAS_BIT_DEPTH-1     : 0] bias_i           = 0;
  reg [COEFF_BIT_DEPTH-1    : 0] coeff_i          = 0;
  reg [$clog2(FEATURES+1)-1 : 0] feature_counter  = 0;
  reg [TREE_HEIGHT-1        : 0] decision_counter = 0;
  reg [TREE_HEIGHT-1        : 0] final_depth      = 0;
 
  reg  [FEATURES-1             : 0] is_one_shr  = 0;
  reg  [FEATURES-1             : 0] path_i      = 0;
  wire [FEATURES-1             : 0] stored_one_pos;

  assign coeff      = coeff_i;
  assign is_one     = is_one_shr[FEATURES-1];
  assign bias       = bias_i;  

  assign level      = final_depth;
  assign path       = path_i;
  assign out_valid  = done & ~first_cycle;

  assign stored_one_pos = `lookup_one_pos(node_index);

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          first_cycle <= 1'b1;
          done        <= 1'b0;

          state <= STATE_DECIDE;

          coeff_index      <= 0;

          feature_counter  <= 0;
          decision_counter <= 0;
  
          final_depth      <= 0;
        end
      else
        begin
          case (state) 
            STATE_DECIDE:
              begin
                state <= STATE_INDEX;
                if (child_valid == 1'b1)
                  begin
                    decision_counter <= decision_counter + 1;
                    done  <= 1'b0;
                  end
                else
                  begin
                    final_depth      <= decision_counter;
                    decision_counter <= 0;

                    if (first_cycle == 1'b1)
                      begin
                        first_cycle <= 1'b0;
                        done <= 1'b0;
                      end 
                    else
                      begin
                        done  <= 1'b1;
                      end
                  end

                path_i[decision_counter] <= child_direction;

                child_flags <= `lookup_child_flags(node_index);
                bias_i      <= `lookup_bias(node_index);
                is_one_shr  <= stored_one_pos;
                coeff_i     <= `lookup_coeff(node_index, coeff_index);

                feature_counter <= 1;
                coeff_index     <= 0;
              end
            STATE_INDEX:
              begin
                done  <= 1'b0;

                child_flags <= child_flags;
                bias_i      <= bias_i;
                is_one_shr[FEATURES-1 : 1] <= is_one_shr[FEATURES-2 : 0];
                is_one_shr[0]              <= 1'b0;

                coeff_i     <= `lookup_coeff(node_index, coeff_index);
                coeff_index <= coeff_index + 1;

                if (feature_counter == FEATURES)
                  begin
                    feature_counter <= 0;
                    state           <= STATE_DECIDE;
                  end
                else
                  begin
                    feature_counter <= feature_counter + 1;
                    state           <= STATE_INDEX;
                  end
              end
            default:
              begin
                done  <= 1'b0;
                state <= STATE_DECIDE;
              end
          endcase
        end
    end

    always @(reset, state,
             is_one_shr, coeff_i, 
             feature_counter, decision_counter,
             child_direction, child_flags, path_i)
      begin
        if (reset == 1'b1)
          begin
            load_bias = 1'b0;
            add       = 1'b0;
            mult      = 1'b0;

            child_valid = 1'b0;
            node_index  = 0;
          end
        else
          begin
            case (state)
              STATE_DECIDE:
                begin
                  load_bias = 1'b0;
                  add       = 1'b0;
                  mult      = 1'b0;

                  case (child_flags)
                    2'b00:   child_valid = 1'b0;
                    2'b10:   child_valid = (child_direction == 1'b0);
                    2'b01:   child_valid = (child_direction == 1'b1);
                    2'b11:   child_valid = 1'b1;
                    default: child_valid = 1'b0;
                  endcase
                  
                  if (child_valid == 1'b1)
                    begin
                      if (decision_counter == 0)
                        begin
                          node_index <= 1 + child_direction;
                        end 
                      else
                        begin
                          node_index <= 3 + path_i[decision_counter-1];
                        end
                    end
                  else
                    begin
                      node_index <= 0;
                    end
                  end
              STATE_INDEX:
                begin
                  load_bias = (feature_counter == 1) 
                            ? 1'b1
                            : 1'b0;
                  add       = 1'b1;
                  mult      = ~(is_one_shr[FEATURES-1] | (coeff_i == 0));

                  child_valid = 1'b0;
                  node_index = 0;
                end
            endcase
          end
      end

endmodule
