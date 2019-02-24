`default_nettype none

module cpu_top
  #(parameter
    npins = 16,
    width = 16,
    iaddr_width = 8,
    daddr_width = 9
    )
(
 input                   clk,
 input                   reset,

 input [iaddr_width-1:0] iaddr_write,
 input [width-1:0]       idata_write,
 input                   i_write,

 inout [npins-1:0]       pins
 );


   wire [iaddr_width-1:0] iaddr;
   reg [width-1:0]        idata;

   wire [daddr_width-1:0] daddr;
   wire                   dwrite;
   wire [width-1:0]       dD;
   wire [width-1:0]       dQ;

   reg [width-1:0]        iram[0:2**iaddr_width-1];

always @(posedge clk)
  if (i_write)
    iram[iaddr_write] <= idata_write;

always @(posedge clk)
  idata <= iram[iaddr];

cpu #(.width(width),
      .iaddr_width(iaddr_width),
      .daddr_width(daddr_width))
cpu(/*AUTOINST*/
    // Outputs
    .iaddr                              (iaddr[iaddr_width-1:0]),
    .daddr                              (daddr[daddr_width-1:0]),
    .dwrite                             (dwrite),
    .dD                                 (dD[width-1:0]),
    // Inputs
    .clk                                (clk),
    .reset                              (reset),
    .idata                              (idata[width-1:0]),
    .dQ                                 (dQ[width-1:0]));

membus #(.width(width),
         .npins(npins))
membus(.addr(daddr),
       .data_write(dD),
       .data_read(dQ),
       .w_strobe(dwrite),
       /*AUTOINST*/
       // Inouts
       .pins                            (pins[npins-1:0]),
       // Inputs
       .clk                             (clk),
       .reset                           (reset));


endmodule
