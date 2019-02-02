module alu_reg_sel
  #(
    width = 16
    )
(
 input [width-1:0]      rstack_top,
 input [width-1:0]      pstack_top,
 input                  rstack_sel,
 input                  zero_arg,
 output reg [width-1:0] reg_result
 );

always @(*)
  case (1'b1)
    zero_arg:   reg_result = 0;
    rstack_sel: reg_result = rstack_top;
    default:    reg_result = pstack_top;
  endcase

endmodule


module alu_logic
  #(
    width = 16
    )
(
 input [width-1:0]      TOS,
 input [width-1:0]      NOS,
 input [1:0]            logic_op,
 output reg [width-1:0] logic_result
 );

always @(*)
  case (logic_op)
    2'b00: logic_result = TOS ^ NOS;
    2'b01: logic_result = TOS | NOS;
    2'b10: logic_result = TOS & NOS;
    2'b11: logic_result = ~TOS;
  endcase

endmodule


module alu_adder
  #(
    width = 16
    )
(
 input [width-1:0]      TOS,
 input [width-1:0]      NOS,
 input                  sub,
 output reg [width-1:0] adder_result
 );

always @(*)
  if (sub)
    adder_result = NOS - TOS;
  else
    adder_result = NOS + TOS;

endmodule


module alu_mux
  #(
    width = 16
    )
(
 input [width-1:0]      logic_result,
 input [width-1:0]      adder_result,
 input [width-1:0]      TOS,
 input                  adder_sel,
 input                  shift_sel,
 input                  zero_sel,
 output reg [width-1:0] alu_mux_result
 );

always @(*)
  case (1'b1)
    adder_sel: alu_mux_result = adder_result;
    zero_sel:  alu_mux_result = 0;
    shift_sel: alu_mux_result = {TOS[width-1],TOS[width-1:1]};
    default:   alu_mux_result = logic_result;
  endcase

endmodule


module tos_mux
  #(
    width = 16
    )
(
 input [width-1:0]      reg_result,
 input [width-1:0]      alu_mux_result,
 input [width-1:0]      imm,
 input                  reg_sel,
 input                  imm_sel,
 output reg [width-1:0] tos_result
 );

always @(*)
  case (1'b1)
    imm_sel: tos_result = imm;
    reg_sel: tos_result = reg_result;
    default: tos_result = alu_mux_result;
  endcase

endmodule


module tos_comb
  #(
    width = 16
    )
(
 input [width-1:0]  TOS,
 input [width-1:0]  rstack_top,
 input [width-1:0]  pstack_top,

 input              TOS_is_zero,

 input [width-1:0]  imm,
 input              rstack_sel,
 input              zero_arg,
 input [1:0]        logic_op,
 input              sub,
 input              adder_sel,
 input              shift_sel,
 input              zero_sel,
 input              reg_sel,
 input              imm_sel,
 output [width-1:0] tos_result
 );

   wire [width-1:0] reg_result;
   wire [width-1:0] logic_result;
   wire [width-1:0] adder_result;
   wire [width-1:0] alu_mux_result;

alu_reg_sel #(.width(width)) alu_reg_sel(.*);
alu_logic #(.width(width)) alu_logic(.NOS(reg_result), .*);
alu_adder #(.width(width)) alu_adder(.NOS(pstack_top), .*);
alu_mux #(.width(width)) alu_mux(.zero_sel(zero_sel & ~TOS_is_zero), .*);
tos_mux #(.width(width)) tos_mux(.*);

// XXX somehow synplify duplicates the alu_reg_sel LUTs?

endmodule


module tos_mem
  #(
    width = 16,
    daddr_width = 8
    )
(
 input                    clk,
 input                    reset,

 input [width-1:0]        tos_result,
 output [width-1:0]       TOS,
 input [width-1:0]        pstack_top,

 output                   TOS_is_zero,

 output [daddr_width-1:0] daddr,
 output                   dwrite,
 output [width-1:0]       dD,
 input [width-1:0]        dQ,

 input                    mem_write,
 input                    mem_read
 );

   reg                    mem_read_r;
   reg [width-1:0]        TOS_r;


always @(posedge clk)
  TOS_r <= tos_result;

assign TOS = mem_read_r ? dQ : TOS_r;

assign TOS_is_zero = TOS == 0;

// always @(posedge clk)
//   daddr <= tos_result;
assign daddr = TOS;
assign dD = pstack_top;
assign dwrite = mem_write;

always @(posedge clk or posedge reset)
  if (reset)
    mem_read_r <= 0;
  else
    mem_read_r     <= mem_read;

endmodule
