PROJ= forth-cpu-u4k
SRCS= alu.v cpu_top.v cpu.v gpio.v ip.v membus.v spi.v stack.v top_u4k.v top.v

YOSYS_PATH:= $(dir $(shell which yosys))/../share/yosys

all: bin sim

bin: ${PROJ}.bin


%.json: %.ys ${SRCS}
	yosys -l $(patsubst %.json,%.log,$@) $<

%.asc: %.json %.pcf
	nextpnr-ice40 --u4k --json $< --pcf $(filter %.pcf,$^) --asc $@

%.bin: %.asc
	icepack $< $@


sim: ${PROJ}_chip.vcd

%.vvp: %.v ../tb/%_tb.v ${YOSYS_PATH}/ice40/cells_sim.v
	iverilog -g2005-sv -o $@ $^

%.vcd: %.vvp
	vvp -N $<

%_chip.v: %.asc %.pcf
	icebox_vlog -L -l -c -p $(filter %.pcf,$^) $< > $@.tmp
	mv $@.tmp $@

clean:
	-rm -f $(addprefix ${PROJ},.asc .bin _chip.v .json .log _chip.v.tmp)

.SECONDARY:
