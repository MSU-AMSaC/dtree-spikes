module memory_model
 #( parameter DEPTH = 24
  , parameter WORDS = 5
  )
  ( clk
  , reset

  , ce
  , we
  , a
  , d
  , q
  );

  input  wire clk;
  input  wire reset;

  input  wire ce;
  input  wire we;
  input  wire[$clog2(WORDS)-1 : 0] a;
  input  wire[DEPTH-1         : 0] d;
  output reg [DEPTH-1         : 0] q;

  wire [DEPTH-1 : 0] coeff_memory [0 : WORDS-1];
  reg  [DEPTH-1 : 0] data = 0;

  wire [WORDS-1 : 0] one_hot_address;
  wire [WORDS-1 : 0] gated_clks;

  decoder
   #( .WIDTH (WORDS)
    )
    decode_address
    ( .encoded (a)
    , .one_hot (one_hot_address)
    );

  genvar i;
  generate
  for (i = 0; i < WORDS; i = i + 1)
    begin: GENERATE_MEMORY_CELLS
      assign gated_clks[i] = clk & ce & one_hot_address[i];

      memory_cell
       #( .WIDTH (DEPTH)
        )
        node
        ( .clk   (gated_clks[i])
        , .reset (reset)

        , .ce    (ce)
        , .we    (we)
        , .d     (d)
        , .q     (coeff_memory[i])
        );
    end
  endgenerate

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          q <= 0;
        end
      else
        begin
          q <= coeff_memory[a];
        end
   end

endmodule
