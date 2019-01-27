`define assert_eq(v1, v2) \
if(v1 != v2) begin \
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

task test_opcode(string mnem, logic [15:0] op, val IP_e, val PSP_e, val RSP_e, val TOS_e);
   $display("testing opcode %h, %s", op, mnem);

   reset = 1;
   @(posedge clk) #5;
   uut.IP = 100;
   reset = 0;
   idata = op;
   @(posedge clk);              // fetch
   @(posedge clk);              // execute

   #1;                          // let new signals manifest
   `assert_eq(uut.IP, IP_e);
   `assert_eq(uut.PSP, PSP_e);
   `assert_eq(uut.RSP, RSP_e);
   `assert_eq(uut.TOS, TOS_e);
endtask

typedef enum {
              OP_NOP = 'he040,
              OP_AND = 'he007
      } opcodes;

initial begin
   // mnem, op, IP, PSP, RSP, TOS
   test_opcode("lit 0", 'h0000, 101, 1, 0, 0);
   test_opcode("lit 7fff", 'h7fff, 101, 1, 0, 'h7fff);
   test_opcode("NOP", OP_NOP, 101, 0, 0, 0);
   //test_opcode("AND", OP_AND, 101, 0, 0, 0);
   $finish;
end

endmodule
