`define assert_eq(v1, v2) \
if($isunknown(v1) || v1 != v2) begin \
   $display("%s:%d: %s == %s failed: %x != %x", `__FILE__,`__LINE__,`"v1`",`"v2`",v1,v2); \
   $finish(1); \
     end


module forth_tb;

   logic clk;
   logic reset;

   wire [9:0] iaddr;
   logic [15:0] idata;

   wire [7:0]  daddr;
   wire [15:0] ddata_write;
   wire [15:0] ddata_read;
   wire        dwrite;

forth uut(.clk(clk), .reset(reset), .iaddr(iaddr), .idata(idata), .daddr(daddr), .ddata_write(ddata_write), .ddata_read(ddata_read), .dwrite(dwrite));

initial begin
   $dumpfile("forth_tb.vcd");
   $dumpvars(0, forth_tb);
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
   reset = 1;

   for (int i = $low(uut.pstack); i <= $high(uut.pstack); i++)
     uut.pstack[i] = 'hxxxx;

   @(posedge clk) #5;
   reset = 0;
   uut.IP = IP_start;
   @(posedge clk);              // fetch
endtask

task exec_op(logic [15:0] op);
   idata = op;
   @(posedge clk);              // exec
endtask

task check_result(string check, val IP_e, val PSP_e, val RSP_e, val TOS_e);
   $display("testing %s", check);

   idata = OP_NOP;
   @(posedge clk);                          // let new signals manifest
   `assert_eq(uut.IP, IP_e);
   `assert_eq(uut.PSP, PSP_e);
   `assert_eq(uut.RSP, RSP_e);
   `assert_eq(uut.TOS, TOS_e);
endtask

task check_pstack(int idx, val data_e);
   `assert_eq(uut.pstack[uut.PSP-idx], data_e);
endtask

task check_rstack(int idx, val data_e);
   `assert_eq(uut.rstack[uut.RSP-idx], data_e);
endtask

typedef enum {
              OP_NOP    = 'he040,
              OP_NOT    = 'he000,
              OP_ASHR   = 'he001,
              OP_EQ0    = 'he002,
              OP_NEG    = 'he003,
              OP_AND    = 'he004,
              OP_OR     = 'he005,
              OP_XOR    = 'he006,
              OP_ADD    = 'he007,
              OP_DUP    = 'he04c,
              OP_SWAP   = 'he088,
              OP_DROP   = 'he084,
              OP_TO_R   = 'he0b4,
              OP_R_FROM = 'he0dc
      } opcodes;

initial begin
   // mnem, IP, PSP, RSP, TOS

   reset_cpu(100);
   exec_op('h0000);
   check_result("lit 0", 101, 1, 0, 0);

   reset_cpu(100);
   exec_op('h7fff);
   check_result("lit 7fff", 101, 1, 0, 'h7fff);

   reset_cpu(100);
   exec_op(OP_NOP);
   check_result("NOP", 101, 0, 0, 0);

   reset_cpu();
   exec_op('h1000);
   exec_op('h2000);
   check_result("two immed", 2, 2, 0, 'h2000);
   check_pstack(0, 'h1000);

   reset_cpu();
   exec_op('h7fff);
   exec_op(OP_NOT);
   check_result("NOT", 2, 1, 0, 'h8000);

   reset_cpu();
   exec_op('h7fff);
   exec_op(OP_ASHR);
   check_result("2/ (positive)", 2, 1, 0, 'h3fff);

   reset_cpu();
   exec_op('h7fff);
   exec_op(OP_NOT);
   exec_op(OP_ASHR);
   check_result("2/ (negative)", 3, 1, 0, 'hc000);

   reset_cpu();
   exec_op('h0000);
   exec_op(OP_EQ0);
   check_result("0= (true)", 2, 1, 0, 'hffff);

   reset_cpu();
   exec_op('h1000);
   exec_op(OP_EQ0);
   check_result("0= (false)", 2, 1, 0, 'h0);

   reset_cpu();
   exec_op('h0);
   exec_op(OP_NEG);
   check_result("0 NEG", 2, 1, 0, 'h0);

   reset_cpu();
   exec_op('h0001);
   exec_op(OP_NEG);
   check_result("1 NEG", 2, 1, 0, 'hffff);

   reset_cpu();
   exec_op('h5555);
   exec_op(OP_NEG);
   exec_op(OP_NEG);
   check_result("0x5555 NEG NEG", 3, 1, 0, 'h5555);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op(OP_AND);
   check_result("AND", 3, 1, 0, 'h1230);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op(OP_OR);
   check_result("OR", 3, 1, 0, 'h567c);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op(OP_XOR);
   check_result("XOR", 3, 1, 0, 'h444c);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op(OP_ADD);
   check_result("ADD", 3, 1, 0, 'h68ac);

   reset_cpu();
   exec_op('h1234);
   exec_op(OP_DUP);
   check_result("1234 DUP", 2, 2, 0, 'h1234);
   check_pstack(0, 'h1234);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op(OP_SWAP);
   check_result("1234 5678 SWAP", 3, 2, 0, 'h1234);
   check_pstack(0, 'h5678);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op('h0abc);
   exec_op(OP_DROP);
   check_result("1234 5678 0abc DROP", 4, 2, 0, 'h5678);
   check_pstack(0, 'h1234);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op('h0abc);
   exec_op(OP_TO_R);
   check_result("1234 5678 0abc >R", 4, 2, 1, 'h5678);
   check_pstack(0, 'h1234);
   check_rstack(0, 'h0abc);

   reset_cpu();
   exec_op('h1234);
   exec_op('h5678);
   exec_op('h0abc);
   exec_op(OP_TO_R);
   exec_op(OP_DROP);
   exec_op(OP_R_FROM);
   check_result("1234 5678 0abc >R DROP R>", 6, 2, 0, 'h0abc);
   check_pstack(0, 'h1234);

   $finish;
end

endmodule
