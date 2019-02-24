SRC= cpu.v alu.v stack.v ip.v gpio.v membus.v cpu_top.v spi.v top.v top_u4k.v
TB= cpu_tb top_tb top_u4k_tb

LIB=${YOSYS_PATH}/ice40/cells_sim.v

vpath %.v ../rtl

YOSYS_PATH:= $(dir $(shell which yosys))/../share/yosys

test: $(addsuffix .vcd,${TB})

%.vvp: %.v ${SRC} ${LIB}
	iverilog -g2005-sv -Dunique= -o $@ $^

.PRECIOUS: %.vvp

%.vcd: %.vvp .FORCE
	vvp $^ -lxt2

.FORCE:

clean:
	-rm -f $(addsuffix .vcd,${TB}) $(addsuffix .vvp,${TB})
