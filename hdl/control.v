`default_nettype none
module control
 #( parameter FEATURES        = 3
  , parameter COEFF_BIT_DEPTH = 4
  , parameter BIAS_BIT_DEPTH  = 10
  , parameter MAX_CLUSTERS    = 5
  , parameter CHANNEL_COUNT   = 16
  )
  ( clk
  , reset

  , in_valid
  , child_direction
  
  , ready
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

  input  wire clk;
  input  wire reset;

  input  wire in_valid;
  input  wire child_direction;
  
  output wire                         ready;
  output reg                          load_bias;
  output reg                          add;
  output wire                         mult;

  output reg                          node_valid;
  output wire[COEFF_BIT_DEPTH-1  : 0] coeff;
  output wire                         is_one;
  output wire                         is_zero;
  output wire[BIAS_BIT_DEPTH-1   : 0] bias;
  
  output wire[$clog2(FEATURES)-1 : 0] level;
  output wire[$clog2(FEATURES)-1 : 0] path;
  output wire                         out_valid;
  
  /* module body */

  `define lookup_child_flags         \
        2                            \
     +  FEATURES                     \
     +  (FEATURES-1)*COEFF_BIT_DEPTH \
     +  BIAS_BIT_DEPTH               \
     -: 2

  `define lookup_one_pos             \
        2                            \
     +  FEATURES                     \
     +  (FEATURES-1)*COEFF_BIT_DEPTH \
     +  BIAS_BIT_DEPTH               \
     -  2                            \
     -: FEATURES

  `define lookup_coeff(coeff)        \
        2                            \
     +  FEATURES                     \
     +  (FEATURES-1)*COEFF_BIT_DEPTH \
     +  BIAS_BIT_DEPTH               \
     -  2                            \
     -  FEATURES                     \
     -  COEFF_BIT_DEPTH*coeff        \
     -: COEFF_BIT_DEPTH

  `define lookup_bias                \
        2                            \
     +  FEATURES                     \
     +  (FEATURES-1)*COEFF_BIT_DEPTH \
     +  BIAS_BIT_DEPTH               \
     -  2                            \
     -  FEATURES                     \
     -  COEFF_BIT_DEPTH*(FEATURES-1) \
     -: BIAS_BIT_DEPTH

  localparam TREE_HEIGHT = $clog2(MAX_CLUSTERS);
  reg [TREE_HEIGHT-1           : 0] node_index  = 0;
  reg [$clog2(CHANNEL_COUNT)-1 : 0] ch_index    = 0;
  reg [$clog2(FEATURES-1)-1    : 0] coeff_index = 0;
    
  localparam STATE_DECIDE = 0
           , STATE_INDEX  = 1
           ;
  reg state = STATE_DECIDE;

  reg                               system_ready = 1'b0;
  reg                               first_cycle  = 1'b1;
  reg                               done         = 1'b0;

  wire [1                      : 0] child_flags;
  reg                               child_valid;

  wire [BIAS_BIT_DEPTH-1     : 0] bias_i;
  reg  [COEFF_BIT_DEPTH-1    : 0] coeff_i = 0;
  reg                             mult_i;
  reg  [$clog2(FEATURES+1)-1 : 0] feature_counter  = 0;
  reg  [TREE_HEIGHT-1        : 0] decision_counter = 0;
  reg  [TREE_HEIGHT-1        : 0] final_depth      = 0;
 

  wire                              coeff_mem_ce;
  wire                              coeff_mem_we;
  wire [$clog2(MAX_CLUSTERS*CHANNEL_COUNT)-1 : 0] coeff_mem_a;
  wire [23:0]                       coeff_mem_d;

  reg  [FEATURES-1             : 0] is_one_shr  = 0;
  wire                              is_one_i;
  reg                               is_zero_i;
  reg  [FEATURES-1             : 0] path_i      = 0;
  wire [FEATURES-1             : 0] stored_one_pos;
  wire [COEFF_BIT_DEPTH-1      : 0] stored_coeff;

  assign ready      = ~reset
                    & (is_zero_i | is_one_i | (feature_counter == 0));
  assign level      = final_depth;
  assign path       = path_i;
  assign out_valid  = done;
  assign mult       = mult_i;

  assign coeff_mem_ce   = 1'b1;
  assign coeff_mem_we   = 1'b0;
  assign coeff_mem_a    = ch_index*MAX_CLUSTERS + node_index;

  memory_model
    #( .DEPTH           (24)
     , .WORDS           (MAX_CLUSTERS*CHANNEL_COUNT)
     , .FEATURES        (FEATURES)
     , .COEFF_BIT_DEPTH (COEFF_BIT_DEPTH)
     , .BIAS_BIT_DEPTH  (BIAS_BIT_DEPTH)
     )
     mem_instance
     ( .clk   (clk)
     , .reset (reset)

     , .ce    (coeff_mem_ce)
     , .we    (coeff_mem_we)
     , .a     (coeff_mem_a)
     , .d     (coeff_mem_d)
     );

  assign child_flags    = coeff_mem_d[`lookup_child_flags];
  assign bias           = coeff_mem_d[`lookup_bias];
  assign stored_coeff   = coeff_mem_d[`lookup_coeff(coeff_index)];
  assign stored_one_pos = coeff_mem_d[`lookup_one_pos];
  assign coeff          = coeff_i;

  assign is_one_i       = | (stored_one_pos & is_one_shr);
  assign is_one         = is_one_i;
  assign is_zero        = is_zero_i;

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          system_ready <= 1'b0;
          first_cycle <= 1'b1;
          done        <= 1'b0;

          state <= STATE_DECIDE;

          node_index       <= 0;
          coeff_index      <= 0;

          feature_counter  <= 0;
          decision_counter <= 0;
  
          final_depth      <= 0;
        end
      else
        begin
              if (mult_i)
                begin
                  coeff_i <= coeff_mem_d[`lookup_coeff(coeff_index)];
                end

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
                          done        <= 1'b0;
                        end
                      else
                        begin
                          done        <= 1'b1;
                        end
                    end

                    path_i[decision_counter] <= child_direction;
                    is_one_shr               <= {1'b1, {(FEATURES-1){1'b0}}};

                    feature_counter <= 0;
                  end
                STATE_INDEX:
                  begin
                    done  <= 1'b0;

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
                    done  <= 1'b0;
                    state <= STATE_DECIDE;
                  end
              endcase
        end
    end

    always @(reset, state,
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
                end
              default:
                begin
                  node_valid = 1'b0;
                  load_bias  = 1'b0;
                  add        = 1'b0;
                  mult_i     = 1'b0;
                end
            endcase
          end
      end

endmodule
