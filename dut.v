// Code your design here
// x^8 + x^2 + x^1 + 1
module prbs(
  input clk, rst, load,
  input [7:0] initial_seed,
  output prbs_out 
);
  reg [7:0] lfsr;
  wire feedback;
  assign feedback = lfsr[0];
  always@(posedge clk or negedge rst)
    begin
      if (!rst) 
        lfsr <= 8'd1;
      else if (load)
        lfsr <= initial_seed;
      else 
        begin
          if (feedback)
            begin
              lfsr[7] <= lfsr[0];
              lfsr[6] <= lfsr[7];
              lfsr[5] <= lfsr[6];
              lfsr[4] <= lfsr[5];
              lfsr[3] <= lfsr[2];
              lfsr[2] <= lfsr[3];
              lfsr[1] <= lfsr[2] ^ feedback;
              lfsr[0] <= lfsr[1] ^ feedback;
            end
          else 
            begin
              lfsr[7] <= lfsr[0];
              lfsr[6] <= lfsr[7];
              lfsr[5] <= lfsr[6];
              lfsr[4] <= lfsr[5];
              lfsr[3] <= lfsr[2];
              lfsr[2] <= lfsr[3];
              lfsr[1] <= lfsr[2];
              lfsr[0] <= lfsr[1];
            end
        end
    end
  assign prbs_out = lfsr[0];
endmodule 
                     
            
          
            
                 
