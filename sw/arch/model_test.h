// model_test.h: the target-specific part of riscv-arch-test for apu.
// arch_test.h and every test .S expand these RVMODEL_* macros; they tell the
// tests how this target boots, halts and where the signature lives.
// Only what RV32I tests need is here.
#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

// tohost/fromhost: spike's HTIF mailbox. Storing 1 to tohost makes spike exit
// with status 0. On apu nothing listens there: tb_arch watches dmem for a
// store to this address (read from prog.cfg) and ends the simulation.
#define RVMODEL_DATA_SECTION                                    \
  .pushsection .tohost,"aw",@progbits;                          \
  .align 8; .global tohost;   tohost:   .dword 0;               \
  .align 8; .global fromhost; fromhost: .dword 0;               \
  .popsection

// end of test: one store of 1 to tohost, then "jal x0, 0" (0x0000006f) forever.
// "sw rs2, symbol, rt" is a pseudo-instruction: auipc rt + sw (pc-relative).
#define RVMODEL_HALT                                            \
  li t0, 1;                                                     \
  sw t0, tohost, t1;                                            \
  j .

// nothing to set up: the core leaves reset at RST_VEC with all GPRs written
// by the test itself (RVTEST_INIT_GPRS)
#define RVMODEL_BOOT

// the signature: everything between begin_signature and end_signature is
// dumped by spike (+signature=) and by tb_arch, one 32-bit word per line
#define RVMODEL_DATA_BEGIN                                      \
  RVMODEL_DATA_SECTION;                                         \
  .align 2; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END                                        \
  .align 2; .global end_signature; end_signature:

// console output and self-checks: unused, there is no UART yet (step 2)
#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#endif // _COMPLIANCE_MODEL_H
