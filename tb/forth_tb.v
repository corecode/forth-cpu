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
   reset = 1;
   #95 reset = 0;
end

initial begin
   clk             = 0;
   forever #10 clk = !clk;
end

   logic [15:0] imem[0:127];

task init_mem;
   int i;

   for (int i = $low(imem); i < $high(imem); i++)
     imem[i]   = 'he040;

   i = 0;
   imem[i++]   = 1;
   imem[i++]   = 2;
   imem[i++]   = 'he007;
endtask

initial
  init_mem();

initial
  forever
    @(posedge clk) idata = imem[iaddr];


endmodule
