`default_nettype none
`timescale 1ns/1ps
module dtree_testbench
 #( parameter FEATURES     = 3
  , parameter COEFF_WIDTH  = 4
  , parameter IN_WIDTH     = 10
  , parameter BIAS_WIDTH   = 10
  , parameter MAX_CLUSTERS = 5
  , parameter CHANNELS     = 1

  , parameter DUMP_INPUT   = 0
  );


localparam NODE_SIZE = 2 +
                       FEATURES +
                       (FEATURES-1)*COEFF_WIDTH +
                       BIAS_WIDTH +
                       1;

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

reg  [NODE_SIZE-1 : 0]            nodes [0 : MAX_CLUSTERS-1];
wire [NODE_SIZE-1 : 0]            node_data;
reg  [$clog2(MAX_CLUSTERS)-1 : 0] node_counter;
reg                               write_node = 1'b0;

localparam STATE_WRITE_NODES = 0
         , STATE_WRITE_DATA  = 1;
reg [1:0] state = STATE_WRITE_NODES;

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
  $readmemh("easy_tree.txt", nodes);
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

  assign node_data = nodes[node_counter];

  always @(posedge clk)
    begin
      if (reset == 1'b1)
        begin
          valid  <= 1'b0;
          sample_count <= 0;
          sample <= 0;
          features_loaded <= 1'b0;

          state <= STATE_WRITE_NODES;
          node_counter <= 0;
          write_node   <= 1'b0;
        end
      else
        begin
          case (state)
            STATE_WRITE_NODES:
              begin
                valid  <= 1'b0;
                sample_count <= 0;
                sample <= 0;
                features_loaded <= 1'b0;

                if (node_counter == MAX_CLUSTERS-1)
                  begin
                    state <= STATE_WRITE_DATA;
                    node_counter <= 0;
                  end
                else
                  begin
                    state <= STATE_WRITE_NODES;
                    node_counter <= node_counter + 1;
                  end
              end
            STATE_WRITE_DATA:
              begin
                node_counter <= 0;
                write_node   <= 1'b0;
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
                            if (DUMP_INPUT == 1'b1)
                              begin
                                for (i = 0; i < FEATURES; i = i + 1)
                                  begin
                                    $fwrite(outfile, "%d ", samples[sample_count]);
                                  end
                              end
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
            default:
              begin
                state           <= STATE_WRITE_NODES;
                node_counter    <= 0;
                write_node      <= 1'b0;
                valid           <= 1'b0;
                features_loaded <= 1'b0;
                sample_count    <= 0;
              end
          endcase
        end
    end

  always @(reset, state)
    begin
      case(state)
        STATE_WRITE_NODES:
          begin
            write_node = 1'b1;
          end
        STATE_WRITE_DATA:
          begin
            write_node = 1'b0;
          end
        default:
          begin
            write_node = 1'b0;
          end
      endcase
    end

  dtree
   #( .FEATURES      (FEATURES)
    , .IN_WIDTH      (IN_WIDTH)
    , .COEFF_WIDTH   (COEFF_WIDTH)
    , .BIAS_WIDTH    (BIAS_WIDTH)
    , .MAX_CLUSTERS  (MAX_CLUSTERS)
    , .CHANNEL_COUNT (CHANNELS)
    )
    dut
    ( .clk       (clk)
    , .reset     (reset)

    , .ready     (ready)
    , .in_valid  (valid)
    , .sample    (sample)

    , .wr_node      (write_node)
    , .node_addr    (node_counter)
    , .node_data_in (node_data)
  
    , .level     (level)
    , .path      (path)
    , .out_valid (out_valid)
    );

endmodule
