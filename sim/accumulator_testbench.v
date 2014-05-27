`default_nettype none
module accumulator_testbench
  (
  );

reg clk   = 1'b0;
reg reset = 1'b0;

reg          load  = 1'b0;
reg [13 : 0] a = 0;
wire[14 : 0] y;
wire         overflow;
reg [2:0]    state = 0;

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
  #500 reset = 1'b1;
  #500 reset = 1'b0;
end

accumulator
 #( .IN_WIDTH    (14)
  )
  accumulator_instance
  ( .clk      (clk)
  , .reset    (reset)

  , .init     (15'd0)
  , .load     (load)
  , .a        (a)

  , .y        (y)
  , .overflow (overflow)
  );

always @(posedge clk)
  begin
    if (reset == 1'b1)
      begin
        load  <= 1'b1;
        a     <= 0;
        state <= 0;
      end
    else
      begin
        if (state == 'd7)
          begin
            state <= 0;
          end
        else
          begin
            state <= state + 1;
          end
        case (state)
          0:
            begin
              load <= 1'b0;
              a    <= 14'd12;
            end
          1:
            begin
              load <= 1'b0;
              a    <= -14'd7;
            end
          2:
            begin
              load <= 1'b0;
              a    <= 14'd2;
            end
          3:
            begin
              load <= 1'b0;
              a    <= 14'd3;
            end
          4:
            begin
              load <= 1'b1;
              a    <= -14'd123;
            end
          5:
            begin
              load <= 1'b0;
              a    <= -14'd1;
            end
          6:
            begin
              load <= 1'b0;
              a    <= 14'd8190;
            end
          7:
            begin
              load <= 1'b0;
              a    <= 14'd8190;
            end
        endcase
      end
  end

endmodule
