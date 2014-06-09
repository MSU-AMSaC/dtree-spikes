module memory_model
 #( parameter DEPTH = 24
  , parameter WORDS = 8
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
  output wire[DEPTH-1         : 0] q;

  reg [DEPTH-1 : 0] coeff_memory [0 : WORDS-1];
  reg [DEPTH-1 : 0] data = 0;

  assign q = data;

  initial
  begin
    $readmemh("easy_tree.txt", coeff_memory);
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
