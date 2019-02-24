`default_nettype none

module membus
  #(parameter
    width = 16,
    npins = 16
    )
(
 input                  clk,
 input                  reset,

 input [width-1:0]      data_write,
 output reg [width-1:0] data_read,
 input [8:0]            addr,
 input                  w_strobe,

 inout [npins-1:0]      pins
 );

   reg              mem_sel_read, mem_sel_write;
   reg              gpio_sel_read, gpio_sel_write;

   wire [width-1:0] gpio_data_read;
   wire [width-1:0] mem_data_read;

always @(*) begin
   mem_sel_write = 0;
   gpio_sel_write = 0;
   casez (addr)
     9'b0_????_????: mem_sel_write  = 1;
     9'b1_0000_000?: gpio_sel_write = 1;
     default: ;
   endcase
end

always @(posedge clk) begin
   mem_sel_read <= mem_sel_write;
   gpio_sel_read <= gpio_sel_write;
end


always @(*)
  case (1'b1)
    mem_sel_read:  data_read = mem_data_read;
    gpio_sel_read: data_read = gpio_data_read;
    default:  data_read = {width{1'bx}};
  endcase

mem #(.width(width),
      .addr_width(8))
mem(.data_read(mem_data_read),
    .addr(addr[7:0]),
    .w_strobe(w_strobe && mem_sel_write),
    /*AUTOINST*/
    // Inputs
    .clk                                (clk),
    .reset                              (reset),
    .data_write                         (data_write[width-1:0]));

gpio #(.npins(npins))
gpio(.data_read(gpio_data_read),
     .addr(addr[1:0]),
     .w_strobe(w_strobe & gpio_sel_write),
     /*AUTOINST*/
     // Inouts
     .pins                              (pins[npins-1:0]),
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .data_write                        (data_write[npins-1:0]));

endmodule


module mem
#(parameter
  width = 16,
  addr_width = 8
  )
(
 input                  clk,
 input                  reset,

 input [width-1:0]      data_write,
 output reg [width-1:0] data_read,
 input [addr_width-1:0] addr,
 input                  w_strobe
 );

   reg [width-1:0]      memory[0:2**addr_width-1];

always @(posedge clk)
  if (w_strobe)
    memory[addr] <= data_write;

always @(posedge clk)
  data_read <= memory[addr];

endmodule
