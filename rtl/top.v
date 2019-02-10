`default_nettype none

module top
  #(parameter
    npins = 16
    )
(
 input             clk,
 input             reset,

 input             nCS,
 input             SCK,
 input             MOSI,

 inout [npins-1:0] pins
 );

localparam iaddr_width = 8;
localparam width = 16;

   reg [iaddr_width-1:0] iaddr_write;
   wire [width-1:0]      idata_write;
   wire                  i_write;

   wire                  transfer_done;
   wire                  new_transfer;
   wire                  chip_selected;


always @(posedge clk)
  if (new_transfer)
    iaddr_write <= 0;
  else if (i_write)
    iaddr_write <= iaddr_write + 1;

spi spi(.data_ready(i_write),
        .shiftreg(idata_write),
        .transfer_done(),
        .*);
cpu_top cpu_top(.reset(reset | chip_selected),
                .*);


endmodule
