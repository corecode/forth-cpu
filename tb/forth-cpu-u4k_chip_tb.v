`default_nettype none
`timescale 1 ns / 1 ps

module forth_cpu_u4k_chip_tb;

   reg        nCS;
   reg        SCK;
   reg        MOSI;

   wire [4:0] pins;
   wire       pin_23;           // clk

chip uut(.*);

initial begin
   $dumpfile("forth-cpu-u4k_chip.vcd");
   $dumpvars(0, forth_cpu_u4k_chip_tb);
   #100000 $finish;
end


   reg       clk;
assign pin_23 = clk;

initial begin
   clk = 0;
   #100;
   forever begin
      clk = !clk;
      #20;
   end
end


initial begin
   nCS  = 1;
   MOSI = 0;
   SCK = 0;
end

task send_val(input [15:0] val);
   int i;

   for (i = 0; i < 16; i = i + 1) begin
      MOSI = val[15-i];
      #50;
      SCK = 1;
      #50;
      SCK = 0;
   end
endtask


initial begin
   repeat (1000) @(posedge clk);

   #15;
   nCS = 0;

   send_val(16'h8003); // 3
   send_val(16'h8101); // 101
   send_val(16'h0dc0); // !+
   send_val(16'h8002); // 2
   send_val(16'h8020); // BEGIN 20 ( 1 )
   send_val(16'h0840); // BEGIN DUP ( 2 )
   send_val(16'h600a); // WHILE ( => 3 )
   send_val(16'h8001); // 1
   send_val(16'h01c0); // -
   send_val(16'h4005); // REPEAT ( => 2 )
   send_val(16'h09c0); // DROP ( 3 )
   send_val(16'h8003); // 3
   send_val(16'h04c0); // XOR
   send_val(16'h0840); // DUP
   send_val(16'h8100); // 100
   send_val(16'h0dc0); // !+
   send_val(16'h09c0); // DROP
   send_val(16'h4004); // REPEAT ( => 1 )

   #15;
   nCS = 1;
end


endmodule
