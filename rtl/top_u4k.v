`default_nettype none

module top_u4k
  #(parameter
    npins = 5
    )
(
   input             MOSI,
   input             SCK,
   input             nCS,
   inout [npins-1:0] pins
);


   wire                 clk;
SB_HFOSC #(.CLKHF_DIV("0b01"))
osc(.CLKHFEN(1),
    .CLKHFPU(1),
    .CLKHF(clk));


   reg [7:0]            reset_counter;
   wire                 reset;

initial reset_counter = 0;
assign reset = ~&reset_counter;

always @(posedge clk)
  if (reset)
    reset_counter <= reset_counter + 1;


top #(.npins(npins))
top(/*AUTOINST*/
    // Inouts
    .pins                               (pins[npins-1:0]),
    // Inputs
    .clk                                (clk),
    .reset                              (reset),
    .nCS                                (nCS),
    .SCK                                (SCK),
    .MOSI                               (MOSI));

endmodule
