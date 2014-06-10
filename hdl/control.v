`default_nettype none
module control
 #( parameter FEATURES        = 3
  , parameter COEFF_WIDTH = 4
  , parameter BIAS_WIDTH  = 10
  , parameter MAX_CLUSTERS    = 5
  , parameter CHANNEL_COUNT   = 1
  )
  ( clk
  , reset

  , in_valid
  , child_direction

  , ch_index
  , node_index
  , read_mem
  , node_data
  
  , mem_ready
  , ccore_ready
  , load_bias
  , add
  , mult

  , node_valid
  , coeff
  , is_one
  , is_zero
  , bias

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

  input  wire in_valid;
  input  wire child_direction;

  output wire [$clog2(CHANNEL_COUNT)-1 : 0] ch_index;
  output wire [$clog2(FEATURES)-1      : 0] node_index;
  output wire                               read_mem;
  input  wire [NODE_SIZE-1             : 0] node_data;

  input  wire                         mem_ready;
  output wire                         ccore_ready;
  output reg                          load_bias;
  output reg                          add;
  output wire                         mult;

  output reg                          node_valid;
  output wire[COEFF_WIDTH-1  : 0] coeff;
  output wire                         is_one;
  output wire                         is_zero;
  output wire[BIAS_WIDTH-1   : 0] bias;
  
  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */

  `define lookup_child_flags     \
        2                        \
     +  FEATURES                 \
     +  (FEATURES-1)*COEFF_WIDTH \
     +  BIAS_WIDTH               \
     -: 2

  `define lookup_one_pos         \
        2                        \
     +  FEATURES                 \
     +  (FEATURES-1)*COEFF_WIDTH \
     +  BIAS_WIDTH               \
     -  2                        \
     -: FEATURES

  `define lookup_coeff(coeff)    \
        2                        \
     +  FEATURES                 \
     +  (FEATURES-1)*COEFF_WIDTH \
     +  BIAS_WIDTH               \
     -  2                        \
     -  FEATURES                 \
     -  COEFF_WIDTH*coeff        \
     -: COEFF_WIDTH

  `define lookup_bias            \
        2                        \
     +  FEATURES                 \
     +  (FEATURES-1)*COEFF_WIDTH \
     +  BIAS_WIDTH               \
     -  2                        \
     -  FEATURES                 \
     -  COEFF_WIDTH*(FEATURES-1) \
     -: BIAS_WIDTH

  localparam TREE_HEIGHT = $clog2(MAX_CLUSTERS);
  reg [TREE_HEIGHT-1           : 0] node_index_i  = 0;
  reg [$clog2(CHANNEL_COUNT)-1 : 0] ch_index_i    = 0;
  reg [$clog2(FEATURES-1)-1    : 0] coeff_index   = 0;
    
  localparam STATE_DECIDE = 0
           , STATE_INDEX  = 1
           ;
  reg state = STATE_DECIDE;

  reg                               first_cycle  = 1'b1;
  reg                               done         = 1'b0;

  wire [1                      : 0] child_flags;
  reg                               child_valid;

  wire [BIAS_WIDTH-1     : 0] bias_i;
  reg  [COEFF_WIDTH-1    : 0] coeff_i = 0;
  reg                             mult_i;
  reg  [$clog2(FEATURES+1)-1 : 0] feature_counter  = 0;
  reg  [TREE_HEIGHT-1        : 0] decision_counter = 0;
  reg  [TREE_HEIGHT-1        : 0] final_depth      = 0;

  reg  [FEATURES-1             : 0] is_one_shr  = 0;
  wire                              is_one_i;
  reg                               is_zero_i;
  reg  [$clog2(FEATURES)-2     : 0] path_i      = 0;
  wire [FEATURES-1             : 0] stored_one_pos;
  wire [COEFF_WIDTH-1      : 0] stored_coeff;

  assign ccore_ready = ~reset
                     & (feature_counter != FEATURES-1);
  assign level      = decision_counter;
  assign path       = {path_i, child_direction}; /* truncate to LO bits */
  assign out_valid  = done;
  assign mult       = mult_i;

  assign read_mem   = 1'b1;
  assign node_index = node_index_i;
  assign ch_index   = ch_index_i;

  assign child_flags    = node_data[`lookup_child_flags];
  assign bias           = node_data[`lookup_bias];
  assign stored_coeff   = node_data[`lookup_coeff(coeff_index)];
  assign stored_one_pos = node_data[`lookup_one_pos];
  assign coeff          = coeff_i;

  assign is_one_i       = | (stored_one_pos & is_one_shr);
  assign is_one         = is_one_i;
  assign is_zero        = is_zero_i;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          first_cycle <= 1'b1;

          state <= STATE_DECIDE;

          node_index_i       <= 0;
          coeff_index      <= 0;

          feature_counter  <= 0;
          decision_counter <= 0;
  
          final_depth      <= 0;

          path_i           <= 0;
        end
      else
        begin
          if (mem_ready == 1'b0)
            begin
              first_cycle <= 1'b1;

              state <= STATE_DECIDE;

              node_index_i       <= 0;
              coeff_index      <= 0;

              feature_counter  <= 0;
              decision_counter <= 0;

              final_depth      <= 0;

              path_i           <= 0;
            end
          else
            begin
              if (mult_i)
                begin
                  coeff_i <= node_data[`lookup_coeff(coeff_index)];
                end

              case (state)
                STATE_DECIDE:
                begin
                  state <= STATE_INDEX;

                  if (child_valid == 1'b1)
                    begin
                      decision_counter <= decision_counter + 1;
                      path_i <= {path_i, child_direction}; /* truncate to LO bits */
                    end
                  else
                    begin
                      decision_counter <= 0;
                      path_i <= 0;

                      if (first_cycle == 1'b1)
                        begin
                          first_cycle <= 1'b0;
                        end
                    end

                    is_one_shr <= {1'b1, {(FEATURES-1){1'b0}}};

                    feature_counter <= 0;
                  end
                STATE_INDEX:
                  begin
                    is_one_shr[FEATURES-2 : 0] <= is_one_shr[FEATURES-1 : 1];
                    is_one_shr[FEATURES-1]     <= 1'b0;

                    if (feature_counter == FEATURES)
                      begin
                        coeff_index     <= 0;
                        feature_counter <= 0;
                        state           <= STATE_DECIDE;

                        if (child_valid == 1'b1)
                          begin
                            if (decision_counter == 0)
                              begin
                                node_index_i <= 1 + child_direction;
                              end 
                            else
                              begin
                                node_index_i <= 3 + path_i[0];
                              end
                          end
                        else
                          begin
                            node_index_i <= 0;
                          end
                      end
                    else
                      begin
                        if (is_one_i == 1'b0)
                          begin
                            coeff_index <= coeff_index + 1;
                          end
                        feature_counter <= feature_counter + 1;
                        state           <= STATE_INDEX;
                      end
                  end
                default:
                  begin
                    state <= STATE_DECIDE;
                  end
              endcase
            end
        end
    end

    always @(reset, state, first_cycle,
             is_one_i, stored_coeff, 
             feature_counter, decision_counter,
             child_direction, child_flags, path_i)
      begin
        if (reset == 1'b1)
          begin
            node_valid = 1'b0;
            is_zero_i  = 1'b0;
            load_bias  = 1'b0;
            add        = 1'b0;
            mult_i     = 1'b0;

            child_valid = 1'b0;
            done        = 1'b0;
          end
        else
          begin
            case (child_flags)
              2'b00:   child_valid = 1'b0;
              2'b10:   child_valid = (child_direction == 1'b0);
              2'b01:   child_valid = (child_direction == 1'b1);
              2'b11:   child_valid = 1'b1;
              default: child_valid = 1'b0;
            endcase

            case (state)
              STATE_DECIDE:
                begin
                  node_valid = 1'b0;
                  is_zero_i  = 1'b0;
                  load_bias  = 1'b0;
                  add        = 1'b0;
                  mult_i     = 1'b0;

                  done       = ~child_valid
                             & ~first_cycle;
                end

              STATE_INDEX:
                begin
                  node_valid = 1'b1;
                  is_zero_i  = (stored_coeff == 0)
                             & ~is_one_i;
                  load_bias  = (feature_counter == 0) 
                             ? 1'b1
                             : 1'b0;
                  add        = is_one_i 
                             | (feature_counter != 0)
                             & ~(stored_coeff == 0);
                  mult_i     = ~is_one_i 
                             & ~(stored_coeff == 0)
                             & (feature_counter != FEATURES);
                  done       = 1'b0;
                end
              default:
                begin
                  node_valid = 1'b0;
                  load_bias  = 1'b0;
                  add        = 1'b0;
                  mult_i     = 1'b0;
                  done       = 1'b0;
                end
            endcase
          end
      end

endmodule
