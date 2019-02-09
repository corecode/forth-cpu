module ip_comb
  #(parameter
    iaddr_width = 10
    )
(
 input [iaddr_width-1:0]      IP,
 input [iaddr_width-1:0]      TOS,
 input [iaddr_width-1:0]      rstack_top,

 input                        TOS_is_zero,

 input [iaddr_width-1:0]      ip_imm,
 input                        ip_tos_sel,
 input                        ip_reg_sel,
 input                        ip_imm_sel,
 input                        ip_skip,

 output [iaddr_width-1:0]     ip_inc,
 output reg [iaddr_width-1:0] ip_result
 );

assign ip_inc = IP + 1;

always @(*)
  case (1'b1)
    ip_skip && ~TOS_is_zero:   ip_result = ip_inc;
    ip_imm_sel:                ip_result = ip_imm;
    ip_reg_sel && !ip_tos_sel: ip_result = rstack_top;
    ip_reg_sel && ip_tos_sel:  ip_result = TOS;
    default:                   ip_result = ip_inc;
  endcase

endmodule
