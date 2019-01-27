SRC= ../rtl/forth.v
TB= forth_tb

test: $(addsuffix .vcd,${TB})

%.vvp: %.v ${SRC}
	iverilog -g2005-sv -Dunique= -o $@ $^

.PRECIOUS: %.vvp

%.vcd: %.vvp
	vvp $^ -lxt2

clean:
	-rm -f $(addsuffix .vcd,${TB}) $(addsuffix .vvp,${TB})
