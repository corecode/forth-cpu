module alu_reg_sel
  #(parameter
    width = 16
    )
(
 input [width-1:0]      rstack_top,
 input [width-1:0]      pstack_top,
 input                  rstack_sel,
 output reg [width-1:0] reg_result
 );

always @(*)
  case (1'b1)
    rstack_sel: reg_result = rstack_top;
    default:    reg_result = pstack_top;
  endcase

endmodule


module alu_logic
  #(parameter
    width = 16
    )
(
 input [width-1:0]      TOS,
 input [width-1:0]      arg,
 input [1:0]            logic_op,
 output reg [width-1:0] logic_result
 );

always @(*)
  case (logic_op)
    2'b00: logic_result = TOS ^ arg;
    2'b01: logic_result = TOS | arg;
    2'b10: logic_result = TOS & arg;
    2'b11: logic_result = ~TOS;
  endcase

endmodule


module alu_adder
  #(parameter
    width = 16
    )
(
 input [width-1:0]      TOS,
 input [width-1:0]      arg,
 input                  sub,
 input                  inc,
 output reg [width-1:0] adder_result
 );

always @(*)
  if (sub)
    adder_result = arg - TOS;
  else
    adder_result = arg + TOS + inc;

endmodule


module alu_mux
  #(parameter
    width = 16
    )
(
 input [width-1:0]      logic_result,
 input [width-1:0]      TOS,
 input                  shift_sel,
 output reg [width-1:0] alu_mux_result
 );

always @(*)
  case (1'b1)
    shift_sel: alu_mux_result = {TOS[width-1],TOS[width-1:1]};
    default:   alu_mux_result = logic_result;
  endcase

endmodule


module tos_mux
  #(parameter
    width = 16
    )
(
 input [width-1:0]      reg_result,
 input [width-1:0]      alu_mux_result,
 input [width-1:0]      adder_result,
 input [width-1:0]      imm,
 input                  reg_sel,
 input                  adder_sel,
 input                  zero_sel,
 input                  imm_sel,
 output reg [width-1:0] tos_result
 );

always @(*)
  case (1'b1)
    adder_sel & ~imm_sel: tos_result = adder_result;
    imm_sel:              tos_result = imm;
    zero_sel:             tos_result = 0;
    reg_sel:              tos_result = reg_result;
    default:              tos_result = alu_mux_result;
  endcase

endmodule


module tos_comb
  #(parameter
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
 input              inc,
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

   wire [width-1:0] arg;

assign arg = zero_arg ? 0 : pstack_top;

alu_reg_sel #(.width(width)) alu_reg_sel(.*);
alu_logic #(.width(width)) alu_logic(.*);
alu_adder #(.width(width)) alu_adder(.*);
alu_mux #(.width(width)) alu_mux(.*);
tos_mux #(.width(width)) tos_mux(.zero_sel(zero_sel & ~TOS_is_zero), .*);

endmodule


module tos_mem
  #(parameter
    width = 16,
    daddr_width = 8
    )
(
 input                    clk,
 input                    reset,
 input                    wait_state,

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
  if (reset)
    TOS_r <= {width{1'bx}};
  else
    if (!wait_state)
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
    mem_read_r <= mem_read;

endmodule
