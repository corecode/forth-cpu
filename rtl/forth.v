module forth
  (
   clk,
   reset,

   iaddr,
   idata,

   daddr,
   ddata_write,
   ddata_read,
   dwrite,
   );

parameter width = 16;
parameter stacksize = 256;
parameter iaddr_width = 10;
parameter daddr_width = 8;

localparam instr_width = 16;
localparam stack_width = $clog2(stacksize);

   input clk;
   input reset;

   output [iaddr_width-1:0] iaddr;
   input [instr_width-1:0]  idata;

   output [daddr_width-1:0] daddr;
   input [width-1:0]        ddata_read;
   output [width-1:0]       ddata_write;
   output                   dwrite;

   wire [instr_width-1:0]   instr;

   reg [stack_width-1:0]    PSP;
   wire [stack_width-1:0]   PSP_next;
   reg [stack_width-1:0]    RSP;
   wire [stack_width-1:0]   RSP_next;
   reg [iaddr_width-1:0]    IP;
   reg [iaddr_width-1:0]    IP_next;
   reg [width-1:0]          TOS;
   reg [width-1:0]          TOS_next;

   reg [width-1:0]          pstack[0:stacksize-1];
   wire [width-1:0]         pstack_top;

   reg [width-1:0]          rstack[0:stacksize-1];
   wire [width-1:0]         rstack_top;


/*
		psp_en	psp_dir	tos_sel	op	rsp_en	rsp_dir	rst_sel	ip_sel

 DUP		1	1	01		0	-	-	0
 SWAP		0	1	10		0	-	-	0
 DROP		1	0	10		0	-	-	0
 >R		1	0	10		1	1	0	0
 R>		1	1	11		1	0	-	0

 LITERAL	1	1	--		0	-	-	0

 BRANCH		0	-	01		0	-	-	imm
 0BRANCH	1	0	10		0	-	-	cond imm
 CALL		0	-	01		1	1	1	imm
 RETURN		0	-	01		1	0	-	rstack
 EXECUTE	1	0	10		1	1	1	tos

 AND		1	0	00	00	0			0
 OR		1	0	00	01	0			0
 XOR		1	0	00	10	0			0
 ADD		1	0	00	11	0			0
// SUB		1	0	00

 2/		0	-	00	01	0			0
 NEGATE		0	-	00	00	0			0
 0=		0	-	00	10	0			0
 NEGATIVE	0	-	00	11	0			0

 @		1	0	01 XXX
 !++		1	0	01

 Bit Layout:

 | 15  | 14  | 13  | 12  | ...
 | imm |   ipsel   | ret | ...
 |  7  |  6  |   5   |   4  |   3   |   2  |  1  |  0  |
 |  tos_sel  |rsp_dir|rsp_en|psp_dir|psp_en|    alu    |

 */

`define O_NOT  3'b000
`define O_ASHR 3'b001
`define O_EQ0  3'b010
`define O_NEG  3'b011
`define O_AND  3'b100
`define O_OR   3'b101
`define O_XOR  3'b110
`define O_ADD  3'b111
   wire [2:0]               o_alu;

`define O_PSP_NONE 2'b00
`define O_PSP_DEC  2'b01
`define O_PSP_UPD  2'b10
`define O_PSP_INC  2'b11
   wire                     o_psp_en;
   wire                     o_psp_dir;

   wire                     o_rsp_en;
   wire                     o_rsp_dir;

`define O_ALU    2'b00
`define O_TOS    2'b01
`define O_PSTACK 2'b10
`define O_RSTACK 2'b11
   wire [1:0]               o_tos_sel;

`define O_IP_CONDIMM 2'b00
`define O_IP_IMM     2'b01
`define O_IP_CALL    2'b10
`define O_IP_INC     2'b11
   wire [1:0]               o_ipsel;

   wire                     o_ret;

   wire                     o_is_lit;
   wire                     o_is_imm_pc;
   wire                     o_is_imm;
   wire [width-2:0]         o_imm;
   wire [iaddr_width-1:0]   o_imm_pc;

assign o_is_lit  = ~instr[instr_width-1];
assign o_imm     = instr[width-2:0];
assign o_imm_pc  = instr[iaddr_width-1:0];
assign o_is_imm_pc = ~o_is_lit & ~&o_ipsel;
assign o_is_imm  = o_is_lit | o_is_imm_pc;

assign o_alu     = instr[2:0];
assign o_psp_en  = (instr[2] | ~|o_ipsel) | o_is_lit;
assign o_psp_dir = (instr[3] & &o_ipsel) | o_is_lit;
assign i_rsp_en  = instr[4];
assign o_rsp_en  = (i_rsp_en | o_ret | (o_ipsel == `O_IP_CALL)) & !o_is_lit;
assign o_rsp_dir = instr[5] | (o_ipsel == `O_IP_CALL);
assign o_tos_sel = instr[7:6];
assign o_ret     = instr[instr_width-4];
assign o_ipsel   = instr[instr_width-2:instr_width-3];



`define OP_NOP 16'he040


// conditional signals ///////////////////////////

   wire                  TOS_is_zero;
assign TOS_is_zero = !(|TOS);

   reg need_wait;
always @(posedge clk)
  if (reset)
    need_wait <= 1;
  else
    need_wait <= 0;

// instruction fetch /////////////////////////////

   wire [iaddr_width-1:0] IP_inc;
assign IP_inc = IP + 1;

assign IP_from_TOS = !o_is_imm && o_ret && i_rsp_en;
assign IP_from_rstack = !o_is_imm && o_ret && !i_rsp_en;
assign IP_from_imm = o_is_imm_pc && (|o_ipsel || TOS_is_zero);

always @(*)
  case (1'b1)
    IP_from_imm:    IP_next = o_imm_pc;
    IP_from_rstack: IP_next = rstack_top;
    IP_from_TOS:    IP_next = TOS;
    default:        IP_next = IP_inc;
  endcase

always @(posedge clk)
  if (reset)
    IP <= 0;
  else
    if (!need_wait)
      IP <= IP_next;

assign iaddr = IP_next;
assign instr = idata;

// RSP ///////////////////////////////////////////

   reg [stack_width-1:0]  RSP_inc;
always @(*)
  casex ({o_rsp_en, o_rsp_dir})
    2'b0?: RSP_inc = 0;
    2'b10: RSP_inc = -1;
    2'b11: RSP_inc = 1;
  endcase

assign RSP_next = RSP + RSP_inc;

always @(posedge clk)
  if (reset)
    RSP <= 0;
  else
    if (!need_wait)
      RSP <= RSP_next;

   wire [width-1:0]       rstack_next;
assign rstack_maybe_load_TOS = !o_is_imm && !o_ret;
assign rstack_next = rstack_maybe_load_TOS ? TOS : IP_inc;

always @(posedge clk)
  if (!need_wait)
    if (o_rsp_en && o_rsp_dir)
      rstack[RSP_next] <= rstack_next;

assign rstack_top = rstack[RSP];

// PSP ///////////////////////////////////////////

   reg [stack_width-1:0]  PSP_inc;
always @(*)
  case ({o_psp_dir,o_psp_en})
    `O_PSP_NONE: PSP_inc = 0;
    `O_PSP_UPD:  PSP_inc = 0;
    `O_PSP_DEC:  PSP_inc = -1;
    `O_PSP_INC:  PSP_inc = 1;
  endcase

assign PSP_next = PSP + PSP_inc;

always @(posedge clk)
  if (reset)
    PSP <= 0;
  else
    if (!need_wait)
      PSP <= PSP_next;


always @(posedge clk)
  if (!need_wait)
    if (o_psp_dir)
      pstack[PSP_next] <= TOS;

assign pstack_top = pstack[PSP];

// ALU ///////////////////////////////////////////

   wire [width-1:0]       ain1, ain2;
   reg [width-1:0]        alu_out;
assign ain1 = TOS;
assign ain2 = pstack_top;

   wire [width-1:0]       ain1_inv, alu_add1, alu_add2, alu_add;
assign ain1_inv = ~ain1;
assign alu_add1 = o_alu[2] ? ain1 : ain1_inv;
assign alu_add2 = o_alu[2] ? ain2 : 1;
assign alu_add = alu_add1 + alu_add2;

always @(*)
  case (o_alu)
    `O_NOT: alu_out  = ain1_inv;
    `O_ASHR: alu_out = {ain1[width-1],ain1[width-1:1]};
    `O_EQ0: alu_out  = TOS_is_zero ? ain1_inv : 0;
    `O_AND: alu_out  = ain1 & ain2;
    `O_OR: alu_out   = ain1 | ain2;
    `O_XOR: alu_out  = ain1 ^ ain2;
    `O_ADD: alu_out  = alu_add;
    `O_NEG: alu_out  = alu_add;
  endcase

// TOS ///////////////////////////////////////////

always @(*)
  case (1'b1)
    o_is_lit: TOS_next    = {1'b0, o_imm};
    o_ipsel == `O_IP_IMM: TOS_next = TOS;
    o_ipsel == `O_IP_CALL: TOS_next = TOS;
    default:
      case (o_tos_sel)
        `O_TOS:    TOS_next = TOS;
        `O_ALU:    TOS_next = alu_out;
        `O_PSTACK: TOS_next = pstack_top;
        `O_RSTACK: TOS_next = rstack_top;
      endcase
  endcase

always @(posedge clk)
  if (reset)
    TOS <= 0;
  else
    if (!need_wait)
      TOS <= TOS_next;

endmodule
