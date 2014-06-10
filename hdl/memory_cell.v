module memory_cell
 #( parameter WIDTH = 24 
  )
  ( clk
  , reset

  , ce
  , we
  , d
  , q
  );

  input  wire clk;
  input  wire reset;

  input  wire ce;
  input  wire we;
  input  wire [WIDTH-1 : 0] d;
  output wire [WIDTH-1 : 0] q;

  reg [WIDTH-1 : 0] data = 0;

  assign q = data;
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
              if (we == 1'b1)
                begin
                  data <= d;
                end
            end
        end
    end

endmodule
