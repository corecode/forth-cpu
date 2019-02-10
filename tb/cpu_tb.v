`default_nettype none

`define assert_eq(v1, v2) \
if(($isunknown(v1) && !$isunknown(v2)) || v1 != v2) begin \
   $display("%s:%d: %s == %s failed: %x != %x", `__FILE__,`__LINE__,`"v1`",`"v2`",v1,v2); \
   $finish(1); \
     end


module cpu_tb;

   logic        clk;
   logic        reset;

   wire [9:0]   iaddr;
   logic [15:0] idata;

   wire [7:0]   daddr;
   wire [15:0]  dD;
   reg [15:0]   dQ;
   wire         dwrite;

cpu uut(.clk(clk), .reset(reset), .iaddr(iaddr), .idata(idata), .daddr(daddr), .dD(dD), .dQ(dQ), .dwrite(dwrite));

initial begin
   $dumpfile("cpu_tb.vcd");
   $dumpvars(0, cpu_tb);
   #100000 $finish;
end

initial begin
   clk             = 0;
   forever #10 clk = !clk;
end

task run_program;
   logic [15:0] imem[0:127];
   int i;

   for (int i = $low(imem); i < $high(imem); i++)
     imem[i]   = 'he040;

   i = 0;
   imem[i++]   = 1;
   imem[i++]   = 2;
   imem[i++]   = 'he007;

   forever
     @(posedge clk) idata = imem[iaddr];
endtask


   typedef logic [15:0] val;

task reset_cpu(val IP_start=0);
   reset            = 1;

   for (int i = $low(uut.cpu_execute.pstack.stack_mem); i <= $high(uut.cpu_execute.pstack.stack_mem); i++)
     uut.cpu_execute.pstack.stack_mem[i] = 'hxxxx;

   @(posedge clk) #5;
   reset = 0;
   uut.cpu_execute.IP = IP_start;
   //@(posedge clk);              // fetch
endtask

task exec_op(logic [15:0] op);
   idata = op;
   @(posedge clk);              // exec
endtask

task check_result(string check, val IP_e, val PSP_e, val RSP_e, val TOS_e);
   $display("testing %s", check);

   idata = OP_NOP;
   @(posedge clk);                          // let new signals manifest
   `assert_eq(uut.cpu_execute.IP, IP_e);
   `assert_eq(uut.cpu_execute.pstack.SP, PSP_e);
   `assert_eq(uut.cpu_execute.rstack.SP, RSP_e);
   `assert_eq(uut.cpu_execute.TOS, TOS_e);
endtask

task check_pstack(int idx, val data_e);
   `assert_eq(uut.cpu_execute.pstack.stack_mem[uut.cpu_execute.pstack.SP-idx], data_e);
endtask

task check_rstack(int idx, val data_e);
   `assert_eq(uut.cpu_execute.rstack.stack_mem[uut.cpu_execute.rstack.SP-idx], data_e);
endtask

typedef enum {
              OP_NOP     = 'h0800,
              OP_NOT     = 'h0700,
              OP_ASHR    = 'h0200,
              OP_EQ0     = 'h0300,
              OP_AND     = 'h06c0,
              OP_OR      = 'h05c0,
              OP_XOR     = 'h04c0,
              OP_ADD     = 'h00c0,
              OP_SUB     = 'h01c0,
              OP_DUP     = 'h0840,
              OP_SWAP    = 'h0980,
              OP_DROP    = 'h09c0,
              OP_TO_R    = 'h09d0,
              OP_R_FROM  = 'h0a70,
              OP_R_FETCH = 'h0a40,
              OP_BRANCH  = 'h4000,
              OP_0BRANCH = 'h6000,
              OP_CALL    = 'h2000,
              OP_EXECUTE = 'h09e0,
              OP_RETURN  = 'h1030,
              OP_MWRITE  = 'h0dc0,
              OP_MREAD   = 'h0c00,
              OP_LIT     = 'h8000
      } opcodes;

initial begin
   // mnem, IP, PSP, RSP, TOS

   reset_cpu(100);
   exec_op(OP_LIT | 'h0000);
   check_result("lit 0", 101, 1, 0, 0);

   reset_cpu(100);
   exec_op(OP_LIT | 'h7fff);
   check_result("lit 7fff", 101, 1, 0, 'h7fff);

   reset_cpu(100);
   exec_op(OP_LIT | 'h7fff);
   exec_op(OP_NOP);
   check_result("7fff NOP", 102, 1, 0, 'h7fff);

   reset_cpu();
   exec_op(OP_LIT | 'h1000);
   exec_op(OP_LIT | 'h2000);
   check_result("two immed", 2, 2, 0, 'h2000);
   check_pstack(0, 'h1000);

   reset_cpu();
   exec_op(OP_LIT | 'h7fff);
   exec_op(OP_NOT);
   check_result("NOT", 2, 1, 0, 'h8000);

   reset_cpu();
   exec_op(OP_LIT | 'h7fff);
   exec_op(OP_ASHR);
   check_result("2/ (positive)", 2, 1, 0, 'h3fff);

   reset_cpu();
   exec_op(OP_LIT | 'h7fff);
   exec_op(OP_NOT);
   exec_op(OP_ASHR);
   check_result("2/ (negative)", 3, 1, 0, 'hc000);

   reset_cpu();
   exec_op(OP_LIT | 'h0000);
   exec_op(OP_EQ0);
   check_result("0= (true)", 2, 1, 0, 'hffff);

   reset_cpu();
   exec_op(OP_LIT | 'h1000);
   exec_op(OP_EQ0);
   check_result("0= (false)", 2, 1, 0, 'h0);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_AND);
   check_result("AND", 3, 1, 0, 'h1230);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_OR);
   check_result("OR", 3, 1, 0, 'h567c);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_XOR);
   check_result("XOR", 3, 1, 0, 'h444c);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_ADD);
   check_result("ADD", 3, 1, 0, 'h68ac);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h1000);
   exec_op(OP_SUB);
   check_result("SUB", 3, 1, 0, 'h0234);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_DUP);
   check_result("1234 DUP", 2, 2, 0, 'h1234);
   check_pstack(0, 'h1234);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_SWAP);
   check_result("1234 5678 SWAP", 3, 2, 0, 'h1234);
   check_pstack(0, 'h5678);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_LIT | 'h0abc);
   exec_op(OP_DROP);
   check_result("1234 5678 0abc DROP", 4, 2, 0, 'h5678);
   check_pstack(0, 'h1234);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_LIT | 'h0abc);
   exec_op(OP_TO_R);
   check_result("1234 5678 0abc >R", 4, 2, 1, 'h5678);
   check_pstack(0, 'h1234);
   check_rstack(0, 'h0abc);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h5678);
   exec_op(OP_LIT | 'h0abc);
   exec_op(OP_TO_R);
   exec_op(OP_DROP);
   exec_op(OP_R_FROM);
   check_result("1234 5678 0abc >R DROP R>", 6, 2, 0, 'h0abc);
   check_pstack(0, 'h1234);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_TO_R);
   exec_op(OP_R_FETCH);
   check_result("1234 >R R@", 3, 1, 1, 'h1234);
   check_rstack(0, 'h1234);

   reset_cpu();
   exec_op(OP_BRANCH | 'h0300);
   check_result("BRANCH(0300)", 'h0300, 0, 0, 'hxxxx);

   reset_cpu();
   exec_op(OP_LIT | 'h0000);
   exec_op(OP_0BRANCH | 'h0300);
   check_result("0 0BRANCH", 'h0300, 0, 0, 'hxxxx);

   reset_cpu();
   exec_op(OP_LIT | 'h0001);
   exec_op(OP_0BRANCH | 'h0300);
   check_result("1 0BRANCH", 2, 0, 0, 'hxxxx);

   reset_cpu();
   exec_op(OP_CALL | 'h0300);
   check_result("CALL(0300)", 'h0300, 0, 1, 'hxxxx);
   check_rstack(0, 1);

   reset_cpu();
   exec_op(OP_LIT | 'h0300);
   exec_op(OP_EXECUTE);
   check_result("300 EXECUTE", 'h0300, 0, 1, 'hxxxx);
   check_rstack(0, 2);

   reset_cpu();
   exec_op(OP_LIT | 'h0300);
   exec_op(OP_TO_R);
   exec_op(OP_RETURN);
   check_result("300 >R RETURN", 'h0300, 0, 0, 'hxxxx);

   reset_cpu();
   exec_op(OP_LIT | 'h0300);
   exec_op(OP_TO_R);
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_RETURN|OP_NOT);
   check_result("300 >R 1234 NOT+RETURN", 'h0300, 1, 0, 'hedcb);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h0056);
   exec_op(OP_MWRITE);
   check_result("1234 56 !'", 3, 1, 0, 'h0057);

   reset_cpu();
   exec_op(OP_LIT | 'h1234);
   exec_op(OP_LIT | 'h0056);
   exec_op(OP_MWRITE);
   dQ = 'h2345;
   exec_op(OP_MREAD);
   check_result("1234 56 !' @", 4, 1, 0, 'h2345);

   $finish;
end

endmodule
