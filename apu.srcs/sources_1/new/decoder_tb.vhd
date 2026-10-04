----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/04/2026 06:06:40 AM
-- Design Name: 
-- Module Name: decoder_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
library work;
use work.core_pkg.all;
use work.config_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder_tb is
--  Port ( );
end decoder_tb;

architecture test of decoder_tb is
    signal inst_tb        : std_logic_vector(31 downto 0);
    -- for register file
    signal rs1_tb         : reg_addr;
    signal rs2_tb         : reg_addr;
    signal rd_tb          : reg_addr;
    -- operands for alu
    signal imm_tb         : unsigned(XLEN-1 downto 0);
    signal alu_src_a_tb   : ALU_SRC_A_T;  --rs1 / PC / 0
    signal alu_src_b_tb   : ALU_SRC_B_T;  --rs2 / imm
    signal aluop_tb       : ALU_OP;
    --memory
    signal memread_tb     : std_logic;
    signal memwrite_tb    : std_logic;
    signal mem_size_tb    : funct3_t;     --funct3 sets (half/double)word
    -- write back
    signal regwrite_tb    : std_logic;
    signal wb_sel_tb      : WB_SEL_T;
    --brnaches
    signal branch_type_tb : BRANCH_T;     -- 6 branches + none + jal + jalr
    -- for hazards
    signal uses_rs1_tb    : std_logic;
    signal uses_rs2_tb    : std_logic;
    -- for ordering of loads and stores
    signal fence_tb       : std_logic;
    -- for privileged instruction spec
    signal ecall_tb       : std_logic;    -- environment call, trap mcause 11
    signal ebreak_tb      : std_logic;    -- breakpoint, trap mcause 3
    -- for unrecognized opcode
    signal illegal_tb     : std_logic;
begin
    dut: entity work.decoder
    port map(
        inst        => inst_tb,
        rs1         => rs1_tb,
        rs2         => rs2_tb,
        rd          => rd_tb,
        imm         => imm_tb,
        alu_src_a   => alu_src_a_tb,
        alu_src_b   => alu_src_b_tb,
        aluop       => aluop_tb,
        memread     => memread_tb,
        memwrite    => memwrite_tb,
        mem_size    => mem_size_tb,
        regwrite    => regwrite_tb,
        wb_sel      => wb_sel_tb,
        branch_type => branch_type_tb,
        uses_rs1    => uses_rs1_tb,
        uses_rs2    => uses_rs2_tb,
        fence       => fence_tb,
        ecall       => ecall_tb,
        ebreak      => ebreak_tb,
        illegal     => illegal_tb
    );
    
    stimulus: process   
        begin
        --addi x7, x8, 33
        inst_tb <= "00000010000101000000001110010011";
        wait for 10 ns;
        assert rs1_tb = "01000" report "bad regfile outs" severity error;
        assert imm_tb = "000000100001" report "bad imm outs" severity error;
        assert rd_tb = "00111" report "bad rd outs" severity error;
        assert alu_src_a_tb = SRC_A_RS1 report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_IMM report "bad alusrc b" severity error;
        assert regwrite_tb = '1' and uses_rs1_tb='1' report "bad reg flags" severity error;
        assert aluop_tb = ALU_ADD report "bad aluop" severity error;
        
        -- addi x1, x0, -1  checks sign extension
        inst_tb <= x"FFF00093";   
        wait for 10 ns;
        assert imm_tb = (imm_tb'range => '1');
        -- sub x8, x9, x10
        inst_tb <= "01000000101001001000010000110011";
        wait for 10 ns;
        assert rs1_tb = "01001" report "bad rs1 out" severity error;
        assert rs2_tb = "01010" report "bad rs2 outs" severity error;
        assert rd_tb = "01000" report "bad rd outs" severity error;
        assert alu_src_a_tb = SRC_A_RS1 report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_RS2 report "bad alusrc b" severity error;
        assert regwrite_tb = '1' and uses_rs1_tb='1' and uses_rs2_tb='1' 
            report "bad reg flags" severity error;
        assert aluop_tb = ALU_SUB report "bad aluop" severity error;
        
        --srai x8, x9, 9
        inst_tb <= "01000000100101001101010000010011";
        wait for 10 ns;
        assert rd_tb = "01000" report "bad rd outs" severity error;
        assert rs1_tb = "01001" report "bad rs1 out" severity error;
        assert imm_tb(4 downto 0) = to_unsigned(9, XLEN) report "bad imm outs" severity error;
        assert aluop_tb = ALU_SRA and alu_src_b_tb = SRC_B_IMM and regwrite_tb = '1'
            report "bad alu outs" severity error;
        assert alu_src_a_tb = SRC_A_RS1 report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_IMM report "bad alusrc b" severity error;
        assert regwrite_tb = '1' and uses_rs1_tb='1' and uses_rs2_tb='0' 
            report "bad reg flags" severity error;
        
        --lw x8, 59(x9)    = lw rd, imm(rs1)
         inst_tb <= "00000011101101001010010000000011";
        wait for 10 ns;
        assert rd_tb = "01000" report "bad rd outs" severity error;
        assert rs1_tb = "01001" report "bad rs1 out" severity error;
        assert imm_tb = to_unsigned(59, XLEN) report "bad imm outs" severity error;
        assert aluop_tb = ALU_ADD and alu_src_b_tb = SRC_B_IMM and regwrite_tb = '1'
            report "bad alu outs" severity error;
        assert memread_tb = '1' and wb_sel_tb = WB_MEM;
        assert alu_src_a_tb = SRC_A_RS1 report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_IMM report "bad alusrc b" severity error;
        assert regwrite_tb = '1' and uses_rs1_tb='1' and uses_rs2_tb='0' 
            report "bad reg flags" severity error;
            
        --sw x10, 59(x9) 
        inst_tb <= "00000010101001001010110110100011";
        wait for 10 ns;
        assert rs2_tb = "01010" report "bad rs2 outs" severity error;
        assert rs1_tb = "01001" report "bad rs1 outs" severity error;
        assert imm_tb = to_unsigned(59, XLEN) report "bad imm outs" severity error;
        assert aluop_tb = ALU_ADD and alu_src_b_tb = SRC_B_IMM 
            report "bad alu outs" severity error;
        assert memread_tb ='0' and memwrite_tb = '1' report "bad mem outs" severity error;
        assert alu_src_a_tb = SRC_A_RS1 report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_IMM report "bad alusrc b" severity error;
        assert regwrite_tb = '0' and uses_rs1_tb='1' and uses_rs2_tb='1' 
            report "bad reg flags" severity error;
            
        --beq x9, x10, -12    
        inst_tb <= "11111110101001001000101011100011";
        wait for 10 ns;
        assert rs1_tb = "01001" report "bad rs1 outs" severity error;
        assert rs2_tb = "01010" report "bad rs2 outs" severity error;
        assert signed(imm_tb) = to_signed(-12, XLEN) report "bad imm outs" severity error;
        assert aluop_tb = ALU_ADD and alu_src_b_tb = SRC_B_IMM 
            report "bad alu outs" severity error;
        assert memread_tb ='0' and memwrite_tb = '0' report "bad mem outs" severity error;
        assert alu_src_a_tb = SRC_A_PC report "bad alusrc a" severity error;
        assert alu_src_b_tb = SRC_B_IMM report "bad alusrc b" severity error;
        assert regwrite_tb = '0' and uses_rs1_tb='1' and uses_rs2_tb='1' 
            report "bad reg flags" severity error;
        assert branch_type_tb = BR_EQ;
        
        --jal x9, 2050
        inst_tb <= "00000000001100000000010011101111";
        wait for 10 ns;
        assert imm_tb = to_unsigned(2050, XLEN) report "bad imm outs" severity error;
        assert rd_tb = "01001" report "bad rd outs" severity error; 
        assert branch_type_tb = BR_JAL report "wrong branch" severity error;
        assert wb_sel_tb = WB_PC4 report "wrong wb_sel" severity error;
        assert regwrite_tb = '1' and uses_rs1_tb = '0' and uses_rs2_tb = '0'
        report "wrong reg flags" severity error;
        
        --lui x7, 74565  = 0x12345
        inst_tb <= "00010010001101000101001110110111";
        wait for 10 ns;
        assert imm_tb = x"12345000" report "bad imm out" severity error;
        assert alu_src_a_tb = SRC_A_ZERO report "bad alusrc" severity error;
        --illegal
        inst_tb <= x"00000000";
        wait for 10 ns;
        assert illegal_tb ='1' report "illegal instruction not recognized" severity error;

        --ecall
        inst_tb <= x"00000073";
        wait for 10 ns;
        assert ecall_tb = '1' and ebreak_tb = '0' report "ecall not recognized" severity error;
        assert illegal_tb = '0' report "ecall flagged illegal" severity error;
        assert regwrite_tb = '0' and memread_tb = '0' and memwrite_tb = '0'
            report "ecall has side effects" severity error;

        --malformed ecall: rd = x1 instead of x0, must be illegal
        inst_tb <= x"000000F3";
        wait for 10 ns;
        assert illegal_tb = '1' report "malformed ecall not flagged illegal" severity error;
        assert ecall_tb = '0' report "malformed ecall decoded as ecall" severity error;

        report "decoder_tb finished" severity note;
        wait;

    end process;
end test;
