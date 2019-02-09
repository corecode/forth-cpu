module spi
  #(parameter
    width = 16)
(
 input                  nCS,
 input                  SCK,
 input                  MOSI,

 input                  clk,
 input                  reset,

 output reg [width-1:0] shiftreg,
 output reg             new_transfer,
 output reg             transfer_done,
 output wire            chip_selected,
 output reg             data_ready
 );


   reg [2:0]        nCS_s;
   wire             nCS_rising, nCS_falling;

   reg [2:0]        SCK_s;
   wire             SCK_rising;

   reg [1:0]        MOSI_s;
   wire             MOSI_sync;

   reg [$clog2(width)-1:0] numbits;
   wire                    is_last_bit;


always @(posedge clk)
  nCS_s <= {nCS_s[1:0], nCS};

assign nCS_rising = (nCS_s[2:1] == 2'b01);
assign nCS_falling = (nCS_s[2:1] == 2'b10);
assign chip_selected = ~nCS_s[1];


always @(posedge clk)
  SCK_s <= {SCK_s[1:0], SCK};

assign SCK_rising = (SCK_s[2:1] == 2'b01);


always @(posedge clk)
  MOSI_s <= {MOSI_s[0], MOSI};

assign MOSI_sync = MOSI_s[1];


assign is_last_bit = numbits == width - 1;

always @(posedge clk) begin
   if (~chip_selected) begin
      numbits <= 0;
   end else if (SCK_rising) begin
      numbits  <= numbits + 1;
      if (is_last_bit)
        numbits <= 0;
      shiftreg <= {shiftreg[width-2:0], MOSI_sync};
   end
end


always @(posedge clk, posedge reset)
  if (reset)
    data_ready <= 0;
  else
    data_ready <= chip_selected && SCK_rising && is_last_bit;


always @(posedge clk, posedge reset)
  if (reset)
    new_transfer <= 0;
  else
    new_transfer <= nCS_falling;


always @(posedge clk, posedge reset)
  if (reset)
    transfer_done <= 0;
  else
    transfer_done <= nCS_rising;


endmodule
