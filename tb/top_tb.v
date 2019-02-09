module top_tb;

   reg clk;
   reg reset;

   reg nCS;
   reg SCK;
   reg MOSI;

   wire [15:0] pins;


top uut(.*);

initial begin
   $dumpfile("top_tb.vcd");
   $dumpvars(0, top_tb);
   #100000 $finish;
end

initial begin
   clk       = 0;
   reset     = 1;
   #23 reset = 0;
end

initial
  forever
    #5 clk = !clk;


initial begin
   nCS  = 1;
   MOSI = 0;
   SCK = 0;
end


initial begin
   uut.cpu_top.iram[0] = 16'h8003; // 3
   uut.cpu_top.iram[1] = 16'h8101; // 101
   uut.cpu_top.iram[2] = 16'h0dc0; // !+
   uut.cpu_top.iram[3] = 16'h8002; // 2
   uut.cpu_top.iram[4] = 16'h8020; // BEGIN 20 ( 1 )
   uut.cpu_top.iram[5] = 16'h0840; // BEGIN DUP ( 2 )
   uut.cpu_top.iram[6] = 16'h600a; // WHILE ( => 3 )
   uut.cpu_top.iram[7] = 16'h8001; // 1
   uut.cpu_top.iram[8] = 16'h01c0; // -
   uut.cpu_top.iram[9] = 16'h4005; // REPEAT ( => 2 )
   uut.cpu_top.iram[10] = 16'h09c0; // DROP ( 3 )
   uut.cpu_top.iram[11] = 16'h8003; // 3
   uut.cpu_top.iram[12] = 16'h04c0; // XOR
   uut.cpu_top.iram[13] = 16'h0840; // DUP
   uut.cpu_top.iram[14] = 16'h8100; // 100
   uut.cpu_top.iram[15] = 16'h0dc0; // !+
   uut.cpu_top.iram[16] = 16'h09c0; // DROP
   uut.cpu_top.iram[17] = 16'h4004; // REPEAT ( => 1 )
end


endmodule
