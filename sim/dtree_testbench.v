`default_nettype none
`timescale 1ns/1ps
module dtree_testbench
 #( parameter FEATURES = 3
  );

reg clk   = 1'b0;
reg reset = 1'b1;

integer infile;
integer infile_status;
integer outfile;
integer outfile_status;
integer i;
integer sample_count = 0;

reg  [9 : 0] in_sample = 0;
wire         ready;
reg          valid = 1'b0;
reg  [9 : 0] sample = 0;
reg  [9 : 0] samples [0 : FEATURES-1];
wire [1 : 0] level;
wire [1 : 0] path;
wire         out_valid;
reg          features_loaded = 1'b0;

localparam STATE_IDLE   = 0
         , STATE_WRITE  = 1
         , STATE_RELOAD = 2;
reg [1:0] state = STATE_IDLE;

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
  infile  = $fopen("easy_mult.txt",       "r");
  outfile = $fopen("easy_mult_output.txt", "w");
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
          valid  <= 1'b0;
          sample_count <= 0;
          sample <= 0;
          features_loaded <= 1'b0;
        end
      else
        begin
          if (ready == 1'b1)
            begin
              if (sample_count == FEATURES)
                begin
                  valid <= 1'b0;
                  sample_count <= 0;
                  features_loaded <= 1'b1;
                end
              else
                begin
                  valid <= 1'b1;

                  sample_count <= sample_count + 1;
                  if (out_valid == 1'b1)
                    begin
                      $fwrite(outfile, "%d ", level);
                      $fwrite(outfile, "%b",  path);
                      $fwrite(outfile, "\n");
                      features_loaded <= 1'b0;
  
                      infile_status = $fscanf(infile, "%d", in_sample);
                      if (!$feof(infile))
                        begin
                          samples[0] <= in_sample;
                          sample     <= in_sample;
                        end
                    end
                  else
                    begin
                      if (features_loaded == 1'b0)
                        begin
                          infile_status = $fscanf(infile, "%d", in_sample);
                          if (!$feof(infile))
                            begin
                              samples[sample_count] <= in_sample;
                              sample                <= in_sample;
                            end
                        end
                      else
                        begin
                          sample <= samples[sample_count];
                        end
                    end
                end
            end
          else
            begin
              valid <= 1'b0;
              sample_count <= sample_count;
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
    , .in_valid  (valid)
    , .sample    (sample)
  
    , .level     (level)
    , .path      (path)
    , .out_valid (out_valid)
    );

endmodule
