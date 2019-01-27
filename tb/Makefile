SRC= ../rtl/forth.v
TB= forth_tb

test: $(addsuffix .vcd,${TB})

%.vvp: %.v ${SRC}
	iverilog -g2005-sv -Dunique= -o $@ $^

.PRECIOUS: %.vvp

%.vcd: %.vvp .FORCE
	vvp $^ -lxt2

.FORCE:

clean:
	-rm -f $(addsuffix .vcd,${TB}) $(addsuffix .vvp,${TB})
