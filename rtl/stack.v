`default_nettype none

module sp_comb
  #(parameter
    saddr_width = 8
    )
(
 input [saddr_width-1:0]  SP,
 input                    dec,
 input                    change,
 output [saddr_width-1:0] SP_result
 );


   wire [saddr_width-1:0] result;
   wire [saddr_width-1:0] arg;
assign arg = dec ? -1 : 1;
assign result = change ? SP + arg : SP;

`ifndef NO_MANUAL_LUTS

   wire [saddr_width-1:0] carry;

assign carry[0] = change ^ dec;

   genvar                 i;
for (i = 0; i < saddr_width; i = i + 1)
 begin
   SB_LUT4 #(.LUT_INIT(i != 0 ? 16'b1001_0110_1100_1100 : 16'b0011_0011_1100_1100))
   incdec(.O(SP_result[i]),
          .I0(carry[i]),
          .I1(SP[i]),
          .I2(dec),
          .I3(change));

   if (i < saddr_width-1)
     SB_CARRY carry(.CO(carry[i+1]),
                    .CI(carry[i]),
                    .I0(SP[i]),
                    .I1(dec));
end

`ifdef FORMAL
$assert(SP_result == result);
`endif

`else

assign SP_result = result;

`endif

endmodule


module stack
  #(parameter
    saddr_width = 8,
    width = 16
    )
(
 input                  clk,
 input                  reset,
 input                  wait_state,

 input [width-1:0]      D,
 input                  dec,
 input                  change,
 input                  update,
 output reg [width-1:0] Q
 );

   reg [width-1:0]  stack_mem[0:(2**saddr_width)-1];
   reg [saddr_width-1:0] SP;
   wire [saddr_width-1:0] SP_result;

sp_comb #(.saddr_width(saddr_width)) sp_comb(.*);

always @(posedge clk)
  if (reset)
    SP <= 0;
  else
    if (!wait_state)
      SP <= SP_result;

always @(posedge clk)
  if (!wait_state)
    if (update)
      stack_mem[SP_result] <= D;

always @(*)
  Q = stack_mem[SP];

endmodule
