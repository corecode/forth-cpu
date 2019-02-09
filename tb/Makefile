SRC= ../rtl/cpu.v ../rtl/alu.v ../rtl/stack.v ../rtl/ip.v lut.v ../rtl/gpio.v ../rtl/membus.v ../rtl/cpu_top.v ../rtl/spi.v ../rtl/top.v
TB= cpu_tb top_tb

test: $(addsuffix .vcd,${TB})

%.vvp: %.v ${SRC}
	iverilog -g2005-sv -Dunique= -o $@ $^

.PRECIOUS: %.vvp

%.vcd: %.vvp .FORCE
	vvp $^ -lxt2

.FORCE:

clean:
	-rm -f $(addsuffix .vcd,${TB}) $(addsuffix .vvp,${TB})
