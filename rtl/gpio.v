`default_nettype none

module gpio
  #(parameter
    npins = 16
    )
(
 input                  clk,
 input                  reset,

 input [npins-1:0]      data_write,
 output reg [npins-1:0] data_read,
 input [1:0]            addr,
 input                  w_strobe,

 inout [npins-1:0]      pins
 );

   reg [npins-1:0]      enable;
   reg [npins-1:0]      pin_out;
   wire [npins-1:0]     pin_in;

always @(posedge clk, posedge reset)
  if (reset)
    enable <= 0;
  else if (w_strobe && addr == 2'b01)
    enable <= data_write;

always @(posedge clk, posedge reset)
  if (reset)
    pin_out <= 0;
  else if (w_strobe && addr == 2'b00)
    pin_out <= data_write;

   genvar               i;
for (i = 0; i < npins; i = i + 1) begin
`ifndef INFER_PIN
   assign pins[i] = enable[i] ? pin_out[i] : 1'bz;
   assign pin_in = pins;
`else
   SB_IO #(.PIN_TYPE(6'b101000)) io
     (
      .PACKAGE_PIN(pins[i]),
      .INPUT_CLK(clk),
      .OUTPUT_ENABLE(enable[i]),
      .D_OUT_0(pin_out[i]),
      .D_IN_0(pin_in[i])
      );
`endif
end

always @(posedge clk)
  data_read <= pin_in;

endmodule
