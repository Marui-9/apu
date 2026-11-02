#!/usr/bin/env python3
"""RV32I reference model for apu test programs in .mem format.

Runs a .mem image the way the apu SoC sees it (code at RST_VEC, memory that
ignores address bits above ADDR_WIDTH+1) and prints a commit trace in the
"spike --log-commits" format, so it can be diffed against the trace.txt that
tb_soc writes. Stops after the first "jal x0, 0" (the halt loop).

Used instead of spike for hand-written tests that touch low addresses
(e.g. lw 512(x0)), which only exist on apu because of address aliasing.

usage: rv32i_ref.py test1.mem [-o expected.trace] [--addr-width 14] [--regs]
"""
import argparse
import sys

M32 = 0xFFFFFFFF


def sext(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if v >> (bits - 1) else v


def load_mem(path, depth):
    words = [0] * depth
    with open(path) as f:
        for i, line in enumerate(f):
            if i >= depth:
                break
            words[i] = int(line.split()[0], 16)  # first token, like hread
    return words


class Mem:
    def __init__(self, words, addr_width):
        self.w = words
        self.mask = (1 << addr_width) - 1

    def idx(self, a):
        return (a >> 2) & self.mask           # same as addr(ADDR_WIDTH+1 downto 2)

    def read(self, a, size):                 # size in bytes, little endian
        word = self.w[self.idx(a)]
        sh = (a & 3) * 8
        return (word >> sh) & ((1 << (8 * size)) - 1)

    def write(self, a, size, v):
        i, sh = self.idx(a), (a & 3) * 8
        m = ((1 << (8 * size)) - 1) << sh
        self.w[i] = (self.w[i] & ~m & M32) | ((v << sh) & m)


def run(mem, pc, max_steps):
    x = [0] * 32
    out = []
    for _ in range(max_steps):
        inst = mem.w[mem.idx(pc)]
        op, rd = inst & 0x7F, (inst >> 7) & 0x1F
        f3, rs1, rs2, f7 = (inst >> 12) & 7, (inst >> 15) & 0x1F, (inst >> 20) & 0x1F, inst >> 25
        a, b = x[rs1], x[rs2]
        imm_i = sext(inst >> 20, 12)
        imm_s = sext(((inst >> 25) << 5) | ((inst >> 7) & 0x1F), 12)
        imm_b = sext(((inst >> 31) << 12) | (((inst >> 7) & 1) << 11)
                     | (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0xF) << 1), 13)
        imm_j = sext(((inst >> 31) << 20) | (((inst >> 12) & 0xFF) << 12)
                     | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1), 21)
        nxt, wr, memlog = (pc + 4) & M32, None, ""

        if op == 0x37:                                   # lui
            wr = inst & 0xFFFFF000
        elif op == 0x17:                                 # auipc
            wr = (pc + (inst & 0xFFFFF000)) & M32
        elif op == 0x6F:                                 # jal
            wr, nxt = nxt, (pc + imm_j) & M32
        elif op == 0x67:                                 # jalr
            wr, nxt = nxt, (a + imm_i) & M32 & ~1
        elif op == 0x63:                                 # branches
            sa, sb = sext(a, 32), sext(b, 32)
            taken = {0: a == b, 1: a != b, 4: sa < sb, 5: sa >= sb, 6: a < b, 7: a >= b}[f3]
            if taken:
                nxt = (pc + imm_b) & M32
        elif op == 0x03:                                 # loads
            addr = (a + imm_i) & M32
            size = 1 << (f3 & 3)
            v = mem.read(addr, size)
            wr = v if f3 & 4 else sext(v, 8 * size) & M32
            memlog = f" mem 0x{addr:08x}"
        elif op == 0x23:                                 # stores
            addr = (a + imm_s) & M32
            size = 1 << f3
            v = b & ((1 << (8 * size)) - 1)
            mem.write(addr, size, v)
            memlog = f" mem 0x{addr:08x} 0x{v:0{2 * size}x}"
        elif op in (0x13, 0x33):                         # op-imm / op
            imm = op == 0x13
            b2 = imm_i & M32 if imm else b
            sh = b2 & 0x1F
            if f3 == 0:
                wr = a - b2 if (not imm and f7 == 0x20) else a + b2
            elif f3 == 1:
                wr = a << sh
            elif f3 == 2:
                wr = int(sext(a, 32) < sext(b2, 32))
            elif f3 == 3:
                wr = int(a < b2)
            elif f3 == 4:
                wr = a ^ b2
            elif f3 == 5:
                wr = (sext(a, 32) >> sh) if (inst >> 30) & 1 else a >> sh
            elif f3 == 6:
                wr = a | b2
            else:
                wr = a & b2
            wr &= M32
        elif op == 0x0F:                                 # fence: nop
            pass
        else:
            sys.exit(f"unsupported instruction 0x{inst:08x} at 0x{pc:08x}")

        line = f"core   0: 3 0x{pc:08x} (0x{inst:08x})"
        if wr is not None and rd != 0:
            x[rd] = wr
            line += f" x{rd:<2d} 0x{wr:08x}"
        out.append(line + memlog)
        if inst == 0x0000006F:                           # jal x0, 0: halt loop
            return out, x
        pc = nxt
    sys.exit(f"no halt loop after {max_steps} instructions")


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("mem")
    p.add_argument("-o", "--out", help="trace file (default: stdout)")
    p.add_argument("--addr-width", type=int, default=14, help="memory ADDR_WIDTH generic")
    p.add_argument("--rst-vec", type=lambda s: int(s, 0), default=0x80000000)
    p.add_argument("--max-steps", type=int, default=100000)
    p.add_argument("--regs", action="store_true", help="also print final registers to stderr")
    args = p.parse_args()

    mem = Mem(load_mem(args.mem, 1 << args.addr_width), args.addr_width)
    out, x = run(mem, args.rst_vec, args.max_steps)
    text = "\n".join(out) + "\n"
    if args.out:
        with open(args.out, "w") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
    if args.regs:
        for i in range(32):
            print(f"x{i:<2d} 0x{x[i]:08x}", file=sys.stderr)


if __name__ == "__main__":
    main()
