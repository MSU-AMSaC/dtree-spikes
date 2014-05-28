`default_nettype none
module control
 #( parameter FEATURES        = 3
  , parameter COEFF_BIT_DEPTH = 4
  , parameter BIAS_BIT_DEPTH  = 10
  , parameter MAX_CLUSTERS    = 8
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
reg [ 2                            /* indicates whether the child is present */
      + FEATURES                     /* one-hot encoded position of 1 coeff */
      + (FEATURES-1)*COEFF_BIT_DEPTH /* the other coefficients */
      + BIAS_BIT_DEPTH               /* the bias weight */
      - 1 
      //+ DEPTH - (2 + FEATURES + (FEATURES-1)*COEFF_BIT_DEPTH + BIAS_BIT_DEPTH - 1) /* padding */
      : 0] coeff_memory [0 : MAX_CLUSTERS-1];

  function lookup_child_flags;
    input node;
    begin
      lookup_child_flags = coeff_memory[node]
                                       [  2                       
                                       +  FEATURES                     
                                       +  (FEATURES-1)*COEFF_BIT_DEPTH 
                                       +  BIAS_BIT_DEPTH              
                                       -  1 

                                       -: 2 ];
    end
  endfunction

  function lookup_one_pos;
    input node;
    begin
      lookup_one_pos = coeff_memory[node]
                                   [  2                       
                                   +  FEATURES                     
                                   +  (FEATURES-1)*COEFF_BIT_DEPTH 
                                   +  BIAS_BIT_DEPTH              
                                   -  1 

                                   -  2 
                                   -: FEATURES ];
    end
  endfunction

  function lookup_coeff;
    input node, coeff;
    begin
      lookup_coeff = coeff_memory[node]
                                 [  2                        
                                   +  FEATURES                     
                                   +  (FEATURES-1)*COEFF_BIT_DEPTH 
                                   +  BIAS_BIT_DEPTH              
                                   -  1  

                                   -  2
                                   -  FEATURES
                                   -  COEFF_BIT_DEPTH*coeff
                                   -: COEFF_BIT_DEPTH ];
    end
  endfunction

  function lookup_bias;
    input node;
    begin
      lookup_bias = coeff_memory[node]
                                [  2                        
                                   +  FEATURES                     
                                   +  (FEATURES-1)*COEFF_BIT_DEPTH 
                                   +  BIAS_BIT_DEPTH              
                                   -  1  

                                   -  2
                                   -  FEATURES
                                   -  COEFF_BIT_DEPTH*(FEATURES-1)
                                   -: BIAS_BIT_DEPTH ];
    end
  endfunction


  reg [$clog2(MAX_CLUSTERS)-1   : 0] node_index  = 0;
  reg [$clog2(FEATURES-1)-1     : 0] coeff_index = 0;
    
  localparam STATE_READ   = 0
           , STATE_INDEX  = 1
           , STATE_DECIDE = 2
           , STATE_DONE   = 3
           ;

  reg [$clog2(STATE_DONE)-1 : 0] state = STATE_READ;

  reg [1                      : 0] child_flags      = 0;
  reg [BIAS_BIT_DEPTH-1       : 0] bias_i           = 0;
  reg [COEFF_BIT_DEPTH-1      : 0] coeff_i          = 0;
  reg [$clog2(FEATURES)-1     : 0] feature_counter  = 0;
  reg [$clog2(MAX_CLUSTERS)-1 : 0] decision_counter = 0;
 
  reg  [FEATURES-1             : 0] is_one_shr       = 0;
  wire [FEATURES-1             : 0] stored_one_pos;

  assign coeff  = coeff_i;
  assign is_one = is_one_shr[FEATURES-1];
  assign bias   = bias_i;  

  assign stored_one_pos = lookup_one_pos(node_index);

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          state           <= STATE_READ;
          node_index      <= 0;
          coeff_index     <= 0;

          feature_counter <= 0;
          decision_counter   <= 0;
        end
      else
        begin
          case (state) 
            STATE_READ:
              begin
                child_flags <= lookup_child_flags(node_index);
                bias_i      <= lookup_bias(node_index);
                is_one_shr  <= stored_one_pos;
                      if (child_direction == 1'b0)
                        begin
                          state <= STATE_DONE;
                        end
                      else
                        begin
                          state <= STATE_READ;
                        end
                coeff_i     <= lookup_coeff(node_index, coeff_index);

                if (stored_one_pos[FEATURES-1] == 1'b1)
                  begin
                    coeff_index <= coeff_index;
                  end 
                else
                  begin
                    coeff_index <= coeff_index + 1;
                  end

                state <= STATE_INDEX;
              end
            STATE_INDEX:
              begin
                child_flags <= child_flags;
                bias_i      <= bias_i;
                is_one_shr[FEATURES-1 : 1] <= is_one_shr[FEATURES-2 : 0];

                coeff_i     <= lookup_coeff(node_index, coeff_index);
                if (is_one_shr[FEATURES-1] == 1'b1)
                  begin
                    coeff_index <= coeff_index;
                  end 
                else
                  begin
                    coeff_index <= coeff_index + 1;
                  end

                if (feature_counter == FEATURES-1)
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
            STATE_DECIDE:
              begin
                case (child_flags)
                  2'b00: /* leaf */
                    begin
                      state <= STATE_DONE;
                      
                    end
                  2'b01: /* right child only */
                    begin
                      if (child_direction == 1'b0)
                        begin
                          state <= STATE_DONE;
                        end
                      else
                        begin
                          state <= STATE_READ;
                          decision_counter <= decision_counter + 1;
                        end
                    end
                  2'b10: /* left child only */
                    begin
                      if (child_direction == 1'b1)
                        begin
                          state <= STATE_DONE;
                        end
                      else
                        begin
                          state <= STATE_READ;
                          decision_counter <= decision_counter + 1;
                        end
                    end
                  2'b11: /* both children present */
                    begin
                      state <= STATE_READ;
                      decision_counter <= decision_counter + 1;
                    end
                endcase
                node_index  <= (node_index << 1) + child_direction;
                coeff_index <= 0;
              end
            STATE_DONE:
              begin
                state <= STATE_READ;
                node_index       <= 0;
                coeff_index      <= 0;
                decision_counter <= 0;
              end
            default: 
              begin
                state <= STATE_READ;
                node_index       <= 0;
                coeff_index      <= 0;
                decision_counter <= 0;
              end
          endcase
        end
    end

/*
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
*/
endmodule
