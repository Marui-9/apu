# sw/arch/Makefile: riscv-arch-test RV32I tests for apu, plus spike's reference results.
# Runs on the host, after "source ~/rv32_tools/env.sh".
#
#   make                  build every selected test and its references
#   make TESTS=add-01     only these tests (space separated, in quotes if several)
#   make list             show the selected and the excluded tests
#   make compare          after run_dut.sh: apu against spike, PASS/FAIL per test
#   make clean
#
# For each test X, build/ gets:
#   X.elf         the compiled test
#   X.dis         its disassembly, to look up the pcs that show up in traces
#   X.ref.sig     spike's signature: the expected results, one word per line
#   X.spike.log   spike's commit trace
#   X.mem, X.cfg  memory image and symbol addresses for tb_arch (elf2mem.py)
# run_dut.sh later adds X.dut.sig and X.dut.trace next to them.

RV      ?= $(HOME)/rv32_tools
SUITE   := $(RV)/riscv-arch-test/riscv-test-suite
SRC_DIR := $(SUITE)/rv32i_m/I/src
ENV_DIR := $(SUITE)/env
TOOLS   := ../tools
BUILD   := build

# misalign1-jalr-01 needs the instruction-address-misaligned trap (step 3)
EXCLUDE   := misalign1-jalr-01
ALL_TESTS := $(basename $(notdir $(wildcard $(SRC_DIR)/*.S)))
TESTS     := $(filter-out $(EXCLUDE),$(ALL_TESTS))

PREFIX  := riscv-none-elf-
CC      := $(PREFIX)gcc
OBJDUMP := $(PREFIX)objdump
SPIKE   := spike
PYTHON  := python3

# -nostdlib: no crt0/libc, the test is the whole program
# -e: the tests start at rvtest_entry_point, not at link.ld's _start; spike starts at the ELF entry
# -I .: our model_test.h, -I ENV_DIR: arch_test.h and test_macros.h
# TEST_CASE_1: every test wraps its body in #ifdef TEST_CASE_1
CFLAGS := -march=rv32i -mabi=ilp32 -mcmodel=medany -static -nostdlib \
          -T link.ld -Wl,-e,rvtest_entry_point \
          -I . -I $(ENV_DIR) -DXLEN=32 -DTEST_CASE_1=True

ifeq ($(ALL_TESTS),)
$(error no tests found in $(SRC_DIR))
endif
ifeq ($(shell command -v $(CC)),)
$(error $(CC) not found: run "source ~/rv32_tools/env.sh" first)
endif

# a recipe that fails leaves no half-written target behind
.DELETE_ON_ERROR:
# without this, make deletes the .elf files once everything made from them exists
.SECONDARY:
.PHONY: all list compare clean

all: $(foreach t,$(TESTS),$(BUILD)/$(t).dis $(BUILD)/$(t).ref.sig $(BUILD)/$(t).mem)

$(BUILD):
	mkdir -p $@

# model_test.h and link.ld are prerequisites too: changing them rebuilds every test
$(BUILD)/%.elf: $(SRC_DIR)/%.S model_test.h link.ld | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

# -M numeric: registers as x0..x31, the same names the traces use
$(BUILD)/%.dis: $(BUILD)/%.elf
	$(OBJDUMP) -d -M numeric $< > $@

# one spike run writes both files ("&:" tells make one recipe makes both).
# spike exits when the test stores to tohost; timeout catches a test that never does
$(BUILD)/%.ref.sig $(BUILD)/%.spike.log &: $(BUILD)/%.elf
	timeout 60 $(SPIKE) --isa=rv32i --log-commits --log=$(BUILD)/$*.spike.log \
		+signature=$(BUILD)/$*.ref.sig +signature-granularity=4 $<

$(BUILD)/%.mem $(BUILD)/%.cfg &: $(BUILD)/%.elf
	$(PYTHON) $(TOOLS)/elf2mem.py $< $(BUILD)/$*.mem $(BUILD)/$*.cfg

list:
	@echo "selected: $(TESTS)"
	@echo "excluded: $(EXCLUDE)"

compare:
	$(PYTHON) $(TOOLS)/compare.py $(BUILD) $(TESTS)

clean:
	rm -rf $(BUILD)
