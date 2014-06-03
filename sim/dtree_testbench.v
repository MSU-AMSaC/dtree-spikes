`default_nettype none
`timescale 1ns/1ps
module dtree_testbench;

reg clk   = 1'b0;
reg reset = 1'b1;

integer infile;
integer infile_status;
integer outfile;
integer outfile_status;
integer i;

reg  [9 : 0] in_sample = 0;
wire         ready;
reg  [9 : 0] sample = 0;
wire [1 : 0] level;
wire [1 : 0] path;
wire         out_valid;

integer reset_counter = 0;

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
  infile  = $fopen("E1_02.txt",       "r");
  outfile = $fopen("easy_output.txt", "w");
end

  always @(posedge clk)
    begin
      if (reset_counter >= 20)
        begin
          reset_counter <= 20;
          reset <= 1'b0;
        end
      else
        begin
          reset_counter <= reset_counter + 1;
          reset <= 1'b1;
        end
    end

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          sample <= 0;
        end
      else
        begin
          if (ready == 1'b1)
            begin
              infile_status = $fscanf(infile, "%d", in_sample);
              if (!$feof(infile))
                begin
                  sample <= in_sample;
                end
              if (out_valid == 1'b1)
                begin
                  $fwrite(outfile, "%d ", level);
                  $fwrite(outfile, "%b",  path);
                  $fwrite(outfile, "\n");
                end
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

    , .ready     (ready)  
    , .sample    (sample)
  
    , .level     (level)
    , .path      (path)
    , .out_valid (out_valid)
    );

endmodule
