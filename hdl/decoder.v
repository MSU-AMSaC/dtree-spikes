module decoder
 #( parameter  WIDTH     = 16 
  )
  ( encoded
  , one_hot
  );
  
  localparam LOG_WIDTH = $clog2(WIDTH);
 
  input  wire [LOG_WIDTH-1 : 0] encoded;
  output wire [WIDTH-1     : 0] one_hot;
 
  genvar i;
  generate
  for (i = 0; i < WIDTH; i = i + 1)
  begin: GENERATE_ONE_HOT_ENCODING
    assign one_hot[i] = (encoded == i) ? 1'b1 : 1'b0;
  end
  endgenerate
  
endmodule
