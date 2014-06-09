module memory_model
 #( parameter DEPTH = 24
  , parameter WORDS = 8

  , parameter FEATURES        = 3
  , parameter COEFF_BIT_DEPTH = 4
  , parameter BIAS_BIT_DEPTH  = 10
  )
  ( clk
  , reset

  , ce
  , we
  , a
  , d
  );

  input  wire clk;
  input  wire reset;

  input  wire ce;
  input  wire we;
  input  wire[$clog2(WORDS)-1 : 0] a;
  inout  wire[DEPTH-1         : 0] d;

  reg [ 2                            /* indicates whether the child is present */
      + FEATURES                     /* one-hot encoded position of 1 coeff */
      + (FEATURES-1)*COEFF_BIT_DEPTH /* the other coefficients */
      + BIAS_BIT_DEPTH               /* the bias weight */
      : 0] coeff_memory [0 : WORDS-1];

  reg [ 2                            
      + FEATURES                     
      + (FEATURES-1)*COEFF_BIT_DEPTH
      + BIAS_BIT_DEPTH              
      : 0] data = 0;

  assign d = ((ce == 1'b1) && (we == 1'b1))
           ? {DEPTH{1'bZ}}
           : data;

  initial
  begin
    $readmemh("easy_mult_tree.txt", coeff_memory);
  end

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          data <= 0;
        end
      else
        begin
          if (ce == 1'b1)
            begin
              data <= coeff_memory[a];
              if (we == 1'b1)
                begin
                  coeff_memory[a] <= d;
                end
            end
        end
    end

endmodule
