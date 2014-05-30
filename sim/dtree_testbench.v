`default_nettype none
module dtree_testbench
  (
  );

reg clk   = 1'b0;
reg reset = 1'b1;

reg  [9 : 0] sample = 0;
wire [1 : 0] level;
wire [1 : 0] path;
wire         out_valid;

initial
begin
  clk = 1'b0;
  while (1)
  begin
    #20 clk = ~clk;
  end
end

initial
begin
  #500 reset = 1'b0;
end

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          sample <= 0;
        end
      else
        begin
          if (sample == {10{1'b1}})
            begin
              sample <= 0;
            end
          else
            begin
              sample <= sample + 1;
            end
        end
    end

  dtree
   #( .FEATURES    (3)
    , .IN_WIDTH    (10)
    , .COEFF_WIDTH (4)
    )
    dut
    ( .clk       (clk)
    , .reset     (reset)
  
    , .sample    (sample)
  
    , .level     (level)
    , .path      (path)
    , .out_valid (out_valid)
    );

endmodule
