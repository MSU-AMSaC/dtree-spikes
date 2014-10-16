/* adder.v
 * Variable-depth adder module, optionally signed.
 */

`default_nettype none
module adder
 #( parameter IN_WIDTH = 8
  , parameter SIGNED   = 1'b1
  )
  ( a
  , b

  , y
  , v
  );

  input  wire[IN_WIDTH-1 : 0] a;
  input  wire[IN_WIDTH-1 : 0] b;

  output wire[IN_WIDTH   : 0] y;
  output wire                 v;

  wire       [IN_WIDTH   : 0] c_in;
  wire       [IN_WIDTH   : 0] c_out;

  genvar i;
  generate
  for (i = 0; i < IN_WIDTH; i = i + 1)
    begin:INSTANTIATE_ADDERS
      full_adder add_bit
        ( .a     (a[i])
        , .b     (b[i])
        , .c_in  (c_in[i])

        , .s     (y[i])
        , .c_out (c_out[i])
        );
    end
  endgenerate

  full_adder ho_bit
    ( .a     (a[IN_WIDTH-1])  /* sign extension */
    , .b     (b[IN_WIDTH-1])
    , .c_in  (c_in[IN_WIDTH])

    , .s     (y[IN_WIDTH])
    , .c_out (c_out[IN_WIDTH])
    );

  assign c_in[0] = 1'b0;
  generate
  for (i = 1; i <= IN_WIDTH; i = i + 1)
    begin:CONNECT_CARRIES
      assign c_in[i] = c_out[i-1];
    end
  endgenerate

  generate
    if (SIGNED == 1'b0)
      begin:GENERATE_UNSIGNED_OVERFLOW
       assign v = c_out[IN_WIDTH];
      end
    else
      begin:GENERATE_SIGNED_OVERFLOW
        assign v = c_out[IN_WIDTH]
               & ~(a[IN_WIDTH-1] ^ b[IN_WIDTH-1]);
      end
  endgenerate

endmodule
