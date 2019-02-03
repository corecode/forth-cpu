module SB_LUT4
  #(parameter
    [15:0] LUT_INIT = 16'h0000
    )
(
 output O,
 input I0,
 input I1,
 input I2,
 input I3
 );

assign O = LUT_INIT[{I3,I2,I1,I0}];

endmodule


module SB_CARRY
  (
   output CO,
   input CI,
   input I0,
   input I1
   );

assign CO = CI + I0 + I1 > 1;

endmodule
