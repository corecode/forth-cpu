module cpu_execute
  #(
    width = 16,
    idata_width = width,
    iaddr_width = 10,
    daddr_width = 8,
    psaddr_width = 8,
    rsaddr_width = 8
    )
(
 input                    clk,
 input                    reset,

 output [iaddr_width-1:0] iaddr,
 input [width-1:0]        idata,

 output [daddr_width-1:0] daddr,
 output                   dwrite,
 output [width-1:0]       dD,
 input [width-1:0]        dQ,

 output                   TOS_is_zero,

 input                    pdec,
 input                    pchange,
 input                    pupdate,

 input                    rdec,
 input                    rchange,

 input [width-1:0]        imm,
 input                    rstack_sel,
 input                    zero_arg,
 input [1:0]              logic_op,
 input                    sub,
 input                    adder_sel,
 input                    shift_sel,
 input                    zero_sel,
 input                    reg_sel,
 input                    imm_sel,

 input [iaddr_width-1:0]  ip_imm,
 input                    ip_imm_sel,
 input                    ip_skip,
 input                    ip_tos_sel,
 input                    ip_reg_sel,
 input                    rstack_ip_sel,

 input                    mem_write,
 input                    mem_read
);

   reg [iaddr_width-1:0]  IP;
   wire [iaddr_width-1:0] ip_result;

   wire [width-1:0]       TOS;
   wire [width-1:0]       pstack_top;
   wire [width-1:0]       rstack_top;
   wire [width-1:0]       rstack_result;
   wire [width-1:0]       tos_result;


tos_comb #(.width(width))
tos_comb(.*);

tos_mem #(.width(width),
          .daddr_width(daddr_width))
tos_mem(.*);


stack #(.saddr_width(psaddr_width))
pstack(.D(TOS),
       .dec(pdec),
       .change(pchange),
       .update(pupdate),
       .Q(pstack_top),
       .*);


assign rstack_result = rstack_ip_sel ? IP : TOS;

stack #(.saddr_width(rsaddr_width))
rstack(.D(rstack_result),
       .dec(rdec),
       .change(rchange),
       .update(rchange),
       .Q(rstack_top),
       .*);


ip_comb #(.iaddr_width(iaddr_width))
ip_comb(.TOS(TOS[iaddr_width-1:0]),
        .rstack_top(rstack_top[iaddr_width-1:0]),
        .*);

always @(posedge clk, posedge reset)
  if (reset)
    IP <= 0;
  else
    IP <= ip_result;

assign iaddr = ip_result;

endmodule


module cpu_decode
  #(
    width = 16,
    idata_width = width,
    iaddr_width = 10
    )
(
 input [idata_width-1:0]  idata,

 output reg               pdec,
 output reg               pchange,
 output reg               pupdate,

 output reg               rdec,
 output reg               rchange,

 output [width-1:0]       imm,
 output reg               rstack_sel,
 output reg               zero_arg,
 output reg [1:0]         logic_op,
 output reg               sub,
 output reg               adder_sel,
 output reg               shift_sel,
 output reg               zero_sel,
 output reg               reg_sel,
 output                   imm_sel,

 output [iaddr_width-1:0] ip_imm,
 output                   ip_imm_sel,
 output                   ip_skip,
 output                   ip_tos_sel,
 output                   ip_reg_sel,
 output                   rstack_ip_sel,

 output reg               mem_write,
 output reg               mem_read
 );

/*
 *			LIT	CALL	BRANCH	0BRANCH	+RET	ALU
 * 15: imm_sel		1	0	0	0	0	0
 * 14: ip_imm_sel[1]		0	1	1	0	0
 * 13: ip_imm_sel[0]		1	0	1	0	0
 * 12: ret				 	 	1	x
 * 11: tos_op[3]
 * 10: tos_op[2]
 *  9: tos_op[1]
 *  8: tos_op[0]
 *
 */

   reg [3:0]              tos_op;
   wire                   ip_cond;
   reg [1:0]              pstack_op;
   reg [1:0]              rstack_op;
   wire                   is_call;
   wire                   is_execute;

   wire                   i_imm_sel;
   wire [1:0]             i_ip_imm_sel;
   wire                   i_ret;
   wire [3:0]             i_tos_op;
   wire [1:0]             i_pstack_op;
   wire [1:0]             i_rstack_op;

assign {
        i_imm_sel,              // 15
        i_ip_imm_sel,           // 14, 13
        i_ret,                  // 12
        i_tos_op,               // 11, 10, 9, 8
        i_pstack_op,            // 7, 6
        i_rstack_op             // 5, 4
        } = idata[15:4];

assign imm_sel    = i_imm_sel;
assign ip_imm_sel = |{i_ip_imm_sel} & ~imm_sel;
assign ip_cond    = &{i_ip_imm_sel};
assign ip_skip    = ip_cond & ~imm_sel;

assign imm = {1'b0,idata[14:0]};
assign ip_imm = idata[iaddr_width-1:0];

/*
 *		r_ipsel	rdec	rchange	p_op	tos_op
 *
 * CALL		1	0	1	00	TOS
 * BRANCH	0	0	0	00	TOS
 * 0BRANCH	0	0	0	11	pstack
 * EXECUTE	1	0	1	(11	pstack)
 * +RET		0	1	1
 * >R		0	0	1	(11	pstack)
 * R>		0	1	1	(01	rstack)
 * R@		0	0	0	(01	rstack)
 */

assign is_execute = i_rstack_op == 2'b10;
assign is_call = i_ip_imm_sel == 2'b01;

assign ip_tos_sel = ~i_ret;     // TOS/nRSTACK
assign ip_reg_sel = (i_ret | is_execute) & ~imm_sel;

assign rstack_ip_sel = is_call | is_execute; // CALL EXECUTE


always @(*)
  case (1'b1)
    imm_sel:    rstack_op = 2'b00;
    is_call:    rstack_op = 2'b01;
    ip_imm_sel: rstack_op = 2'b00;
    default:    rstack_op = i_rstack_op;
  endcase

always @(*)
  case (rstack_op)
    2'b00: begin
       rchange = 0;
       rdec = 0;
    end
    2'b01: begin
       rchange = 1;
       rdec = 0;
    end
    2'b10: begin
       rchange = 1;
       rdec = 0;
    end
    2'b11: begin
       rchange = 1;
       rdec = 1;
    end
  endcase

always @(*)
  case (1'b1)
    ip_imm:     pstack_op = 2'b01;
    ip_cond:    pstack_op = 2'b11;
    ip_imm_sel: pstack_op = 2'b00;
    default:    pstack_op = i_pstack_op;
  endcase

always @(*) begin
   pupdate = 1'bx;
   pdec    = 1'bx;

   case (pstack_op)
     2'b00: begin
        pchange = 0;
        pupdate = 0;
     end
     2'b01: begin
        pchange = 1;
        pdec    = 0;
     end
     2'b10: begin
        pchange = 0;
        pupdate = 1;
     end
     2'b11: begin
        pchange = 1;
        pdec    = 1;
     end
   endcase
end


always @(*)
  case (1'b1)
    ip_cond:    tos_op = 4'h9;
    ip_imm_sel: tos_op = 4'h8;
    default:    tos_op = i_tos_op;
  endcase

always @(*) begin
   rstack_sel = 1'b0;
   zero_arg   = 1'bx;
   logic_op   = 1'bx;
   sub        = 1'bx;
   adder_sel  = 1'bx;
   shift_sel  = 1'bx;
   zero_sel   = 1'b0;
   reg_sel    = 1'bx;

   mem_read   = 1'b0;
   mem_write  = 1'b0;

   case (tos_op)
     4'h0: begin                // +
        zero_arg  = 1;
        logic_op  = 2'b00;
        sub       = 0;
        adder_sel = 1;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h1: begin                // -
        logic_op  = 2'b11;
        sub       = 1;
        adder_sel = 1;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h2: begin                // /2
        shift_sel = 1;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h3: begin                // 0=
        zero_arg  = 1;
        logic_op  = 2'b11;
        adder_sel = 0;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h4: begin                // XOR
        rstack_sel = 0;
        zero_arg   = 0;
        logic_op   = 2'b00;
        adder_sel  = 0;
        shift_sel  = 0;
        zero_sel   = 0;
        reg_sel    = 0;
     end
     4'h5: begin                // OR
        rstack_sel = 0;
        zero_arg   = 0;
        logic_op   = 2'b01;
        adder_sel  = 0;
        shift_sel  = 0;
        zero_sel   = 0;
        reg_sel    = 0;
     end
     4'h6: begin                // AND
        rstack_sel = 0;
        zero_arg   = 0;
        logic_op   = 2'b10;
        adder_sel  = 0;
        shift_sel  = 0;
        zero_sel   = 0;
        reg_sel    = 0;
     end
     4'h7: begin                // NOT
        logic_op  = 2'b11;
        adder_sel = 0;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h8: begin                // TOS: DUP, XXX use for ip_imm_sel
        zero_arg  = 1;
        logic_op  = 2'b00;
        adder_sel = 0;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'h9: begin                // pstack: SWAP DROP EXECUTE LIT !'
        rstack_sel = 0;
        zero_arg   = 0;
        reg_sel    = 1;
     end
     4'ha: begin                // rstack: R> R@
        rstack_sel = 1;
        zero_arg   = 0;
        reg_sel    = 1;
     end
     4'hc: begin                // @
        mem_read = 1;
        zero_arg  = 1;
        logic_op  = 2'b00;
        adder_sel = 0;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     4'hd: begin                // !
        mem_write = 1;
        zero_arg  = 1;
        logic_op  = 2'b00;
        adder_sel = 0;
        shift_sel = 0;
        zero_sel  = 0;
        reg_sel   = 0;
     end
     default: begin             // missing: XXX @ !'
        zero_arg = 1;
        reg_sel  = 1;
     end
   endcase
end

endmodule


module cpu
  #(
    width = 16,
    idata_width = width,
    iaddr_width = 10,
    daddr_width = 8,
    psaddr_width = 8,
    rsaddr_width = 8
    )
(
 input                    clk,
 input                    reset,

 output [iaddr_width-1:0] iaddr,
 input [width-1:0]        idata,

 output [daddr_width-1:0] daddr,
 output                   dwrite,
 output [width-1:0]       dD,
 input [width-1:0]        dQ
 );

   wire                   TOS_is_zero;

   wire                   pdec;
   wire                   pchange;
   wire                   pupdate;

   wire                   rdec;
   wire                   rchange;

   wire [width-1:0]       imm;
   wire                   rstack_sel;
   wire                   zero_arg;
   wire [1:0]             logic_op;
   wire                   sub;
   wire                   adder_sel;
   wire                   shift_sel;
   wire                   zero_sel;
   wire                   reg_sel;
   wire                   imm_sel;

   wire [iaddr_width-1:0] ip_imm;
   wire                   ip_imm_sel;
   wire                   ip_skip;
   wire                   ip_tos_sel;
   wire                   ip_reg_sel;
   wire                   rstack_ip_sel;

   wire                   mem_write;
   wire                   mem_read;

cpu_decode #(.width(width), .idata_width(idata_width))
cpu_decode(.*);

cpu_execute #(.width(width),
              .idata_width(idata_width),
              .iaddr_width(iaddr_width),
              .daddr_width(daddr_width),
              .psaddr_width(psaddr_width),
              .rsaddr_width(rsaddr_width))
cpu_execute(.*);

endmodule
