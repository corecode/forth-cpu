`ifndef unique
 `define unique unique
`endif

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

   input logic clk;
   input logic reset;

   output wire [iaddr_width-1:0] iaddr;
   input logic [instr_width-1:0] idata;

   output logic [daddr_width-1:0] daddr;
   input logic [width-1:0]        ddata_read;
   output logic [width-1:0]       ddata_write;
   output logic                   dwrite;

   logic [instr_width-1:0]        instr;

   logic [stack_width-1:0]        PSP;
   wire [stack_width-1:0]         PSP_next;
   logic [stack_width-1:0]        RSP;
   wire [stack_width-1:0]         RSP_next;
   logic [iaddr_width-1:0]        IP;
   logic [iaddr_width-1:0]        IP_next;
   logic [width-1:0]              TOS;
   logic [width-1:0]              TOS_next;

   logic [width-1:0]              pstack[0:stacksize-1];
   logic [stack_width-1:0]        pstack_addr;
   logic [width-1:0]              pstack_top;

   logic [width-1:0]              rstack[0:stacksize-1];
   logic [stack_width-1:0]        rstack_addr;
   logic [width-1:0]              rstack_top;


/*
		psp_en	psp_dir	tos_sel	op	rsp_en	rsp_dir	rst_sel	ip_sel

 DUP		1	1	01		0	-	-	0
 SWAP		0	-	10		0	-	-	0
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

 */

   enum logic [2:0]
        {
         O_NOT  = 3'b000,
         O_ASHR = 3'b001,
         O_EQ0  = 3'b010,
         O_NEG  = 3'b011,
         O_AND  = 3'b100,
         O_OR   = 3'b101,
         O_XOR  = 3'b110,
         O_ADD  = 3'b111
         }
        o_alu;

   wire                           o_psp_en;
   wire                           o_psp_dir;
   wire                           o_rsp_en;
   wire                           o_rsp_dir;
   enum logic [1:0]
        {
         O_ALU    = 'b00,
         O_TOS    = 'b01,
         O_PSTACK = 'b10,
         O_RSTACK = 'b11
         }
        o_tos_sel;

   enum logic [1:0]
        {
         O_IP_IMM     = 'b00,
         O_IP_CONDIMM = 'b01,
         O_IP_TOS     = 'b10,
         O_IP_INC     = 'b11
         }
        o_ipsel;

   logic o_ret;

   logic [width-2:0] o_imm;
   logic [iaddr_width-1:0] o_imm_pc;

assign o_imm     = !instr[instr_width-1];

assign o_alu     = instr[2:0];
assign o_psp_en  = instr[2] | o_imm;
assign o_psp_dir = instr[3] | o_imm;
assign o_rsp_en  = (instr[4] | o_ret) & !o_imm;
assign o_rsp_dir = instr[5] & !o_ret;
assign o_tos_sel = instr[7:6];
assign o_ret     = instr[instr_width-4];
assign o_ipsel   = instr[instr_width-2:instr_width-3];

assign o_imm_pc  = instr[iaddr_width-1:0];


   logic [instr_width-1:0] OP_NOP = 'he040;

// | 15  | 14  | 13  | 12  | ...
// | imm |   ipsel   | ret | ...
// |  7  |  6  |   5   |   4  |   3   |   2  |  1  |  0  |
// |  tos_sel  |rsp_dir|rsp_en|psp_dir|psp_en|    alu    |

// conditional signals ///////////////////////////

   logic TOS_is_zero;
assign TOS_is_zero = !(|TOS);

   logic need_wait;
always @(posedge clk)
  if (reset)
    need_wait <= 1;
  else
    need_wait <= 0;

// instruction fetch /////////////////////////////

   logic [iaddr_width-1:0] IP_inc;
assign IP_inc = IP + 1;

always @(*)
  `unique
    case (1'b1)
      need_wait: IP_next = IP;
      o_imm: IP_next     = IP_inc;
      o_ret: IP_next     = rstack_top;
      default:
        case (o_ipsel)
          O_IP_IMM    : IP_next = o_imm_pc;
          O_IP_CONDIMM: IP_next = TOS_is_zero ? o_imm_pc : IP_inc;
          O_IP_INC    : IP_next = IP_inc;
          O_IP_TOS    : IP_next = TOS;
        endcase
    endcase

always @(posedge clk)
  if (reset)
    IP <= 0;
  else
    IP <= IP_next;

assign iaddr = IP_next;
assign instr = need_wait ? OP_NOP : idata;

// RSP ///////////////////////////////////////////

   logic [stack_width-1:0] RSP_inc;

always @(*)
  `unique
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
    RSP <= RSP_next;

   logic [iaddr_width-1:0] rstack_next;
assign rstack_next = o_ipsel == O_IP_INC ? TOS : IP_next;

always @(posedge clk)
  if (o_rsp_en && o_rsp_dir)
    rstack[RSP_next] <= rstack_next;

always @(posedge clk)
  if (o_rsp_en && o_rsp_dir)
    rstack_top <= rstack_next;
  else
    rstack_top <= rstack[RSP_next];

// PSP ///////////////////////////////////////////

   logic [stack_width-1:0]        PSP_inc;

always @(*)
  `unique
    casex ({o_psp_en, o_psp_dir})
      2'b0?: PSP_inc = 0;
      2'b10: PSP_inc = -1;
      2'b11: PSP_inc = 1;
    endcase

assign PSP_next = PSP + PSP_inc;

always @(posedge clk)
  if (reset)
    PSP <= 0;
  else
    PSP <= PSP_next;


always @(posedge clk)
  if (o_psp_en && o_psp_dir)
    pstack[PSP_next] <= TOS;

always @(posedge clk)
  if (o_psp_en && o_psp_dir)
    pstack_top <= TOS;
  else
    pstack_top <= pstack[PSP_next];

// ALU ///////////////////////////////////////////

   wire [width-1:0]               ain1, ain2;
   logic [width-1:0]              alu_out;
assign ain1 = TOS;
assign ain2 = pstack_top;

always @(*)
  `unique
    case (o_alu)
      O_ASHR: alu_out = {ain1[width-1],ain1[width-1:1]};
      O_NOT: alu_out  = ~ain1;
      O_EQ0: alu_out  = TOS_is_zero ? -1 : 0;
      O_NEG: alu_out  = -ain1;
      O_AND: alu_out  = ain1 & ain2;
      O_OR: alu_out   = ain1 | ain2;
      O_XOR: alu_out  = ain1 ^ ain2;
      O_ADD: alu_out  = ain1 + ain2;
      //    O_SUB: alu_out  = ain - ain2;
    endcase

// TOS ///////////////////////////////////////////

always @(*)
  if (o_imm)
    TOS_next = {1'b0, instr[instr_width-2:0]};
  else
    `unique
      case (o_tos_sel)
        O_TOS:    TOS_next = TOS;
        O_ALU:    TOS_next = alu_out;
        O_PSTACK: TOS_next = pstack_top;
        O_RSTACK: TOS_next = rstack_top;
      endcase

always @(posedge clk)
  if (reset)
    TOS <= 0;
  else
    TOS <= TOS_next;

endmodule
