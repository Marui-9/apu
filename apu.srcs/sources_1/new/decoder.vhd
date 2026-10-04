----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/28/2026 06:31:30 AM
-- Design Name: 
-- Module Name: decoder - Behavioral
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
use work.core_pkg.ALL;
use work.config_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder is
    Port ( 
    inst : in  std_logic_vector(31 downto 0);
    --
    -- for register file
    rs1       : out reg_addr;
    rs2       : out reg_addr;
    rd        : out reg_addr;
    -- operands for alu
    imm : out unsigned(XLEN-1 downto 0);
    alu_src_a : out ALU_SRC_A_T;  --rs1 / PC / 0
    alu_src_b : out ALU_SRC_B_t;   --rs2 / imm
    aluop : out ALU_OP;
    --inst_type : out INSTR_FORMAT;
    --memory 
    memread : out std_logic;
    memwrite : out std_logic;
    mem_size  : out funct3_t;   --funct3 sets (half/double)word
    -- write back
    regwrite : out std_logic;
    wb_sel    : out WB_SEL_T;
    --brnaches
    branch_type : out BRANCH_T; -- 6 branches + none + kal + jalr
    -- for hazards (haz unit stalls when flags '1' and register numbers happen to
    -- match an older (previous, already in flight) load's rd
    uses_rs1 : out std_logic;
    uses_rs2 : out std_logic;
    -- for ordering of loads and stores
    fence : out std_logic; 
    -- for privileged instruction spec
    ecall  : out std_logic;   -- environment call, trap mcause 11
    ebreak : out std_logic;   -- breakpoint, trap mcause 3
    -- for unrecognized opcode
    illegal : out std_logic
    );
end decoder;

architecture Behavioral of decoder is
    alias opcode : opcode_t is inst(6 downto 0);
    --alias rd     : reg_addr is inst(11 downto 7);
    alias funct3 : funct3_t is inst(14 downto 12);
    alias funct7 : funct7_t is inst(31 downto 25);
    --alias rs1    : reg_addr is inst(19 downto 15);
    --alias rs2    : reg_addr is inst(24 downto 20);
    begin
    rs1      <= inst(19 downto 15);
    rs2      <= inst(24 downto 20);
    rd       <= inst(11 downto 7);
    mem_size <= funct3;
    process(inst)
        --variable sign_bit : std_logic;
        --defaults is instruction that does nothing;
        begin
            imm         <= (others => '0');
            alu_src_a   <= SRC_A_RS1;
            alu_src_b   <= SRC_B_RS2;
            aluop       <= ALU_ADD;
            memread     <= '0';
            memwrite    <= '0';
            regwrite    <= '0';
            wb_sel      <= WB_ALU;
            branch_type <= BR_NONE;
            uses_rs1    <= '0';
            uses_rs2    <= '0';
            fence        <= '0';  
            illegal <= '0';
            ecall  <= '0';
            ebreak <= '0';
            
            case opcode is  
                when OPCODE_LOAD =>
                    --illegal funct3 check
                    if funct3 = "011" or funct3 = "110" or funct3 = "111" then illegal <= '1';
                    end if;
                    --data at target address is fetched, formatted in funct3 format, loaded into rd
                    imm <= unsigned(resize(signed(inst(31 downto 20)), XLEN));
                    -- resize handles the sign extension on its own to make it the same value, different length
                    alu_src_a <= SRC_A_RS1;
                    alu_src_b <= SRC_B_IMM;
                    aluop <= ALU_ADD;
                    memread <= '1';
                    memwrite <= '0';
                    --mem_size <= funct3;
                    regwrite <= '1';
                    wb_sel <= WB_MEM; --load data from memory at addr=rs1+imm
                    ---
                    branch_type <= BR_NONE;
                    --
                    uses_rs1 <= '1';
                    uses_rs2 <= '0';
                when OPCODE_STORE =>    
                    if funct3(2) = '1' or funct3 = "011" then illegal <= '1';
                    -- to be changed if the architecture becomes 64 bits in future
                    end if; 
                    --stores variable number of bits of rs2 to memory, at address of rs1+immediate
                    imm <= unsigned(resize(signed(inst(31 downto 25) & inst(11 downto 7)), XLEN));
                    alu_src_a <= SRC_A_RS1;
                    alu_src_b <= SRC_B_IMM;
                     aluop <= ALU_ADD;
                     --
                    memread <= '0';
                    memwrite <= '1';
                    regwrite <= '0';
                    --wb_sel <= WB_MEM;
                    branch_type <= BR_NONE;
                    --
                    uses_rs1 <= '1';
                    uses_rs2 <= '1';
                when OPCODE_MISC_MEM =>
                    -- fence enforces the ordering of memory operations
                    --  (load-barrier = block all subsequent loads until in-flight ones are completed, 
                    -- store-barrier = block dispatch of any subsequent stores until all prev stores compelte
                                    -- and are written to cache
                    -- or full-barrier = both of above, no load or stores until in-flight ones complete )
                    -- right now this core is in-order, so fence is essentially a NOP
                    case funct3 is
                        when "000"  => fence <= '1'; -- FENCE / FENCE.TSO / PAUSE
                        when others => illegal <= '1'; -- "001" FENCE.I, "010" CBO.* not implemented yet
                    end case;
                when OPCODE_OP_IMM =>   
                    imm <= unsigned(resize(signed(inst(31 downto 20)), XLEN));
                    alu_src_a <= SRC_A_RS1;
                    alu_src_b <= SRC_B_IMM;
                    branch_type <= BR_NONE;
                    wb_sel <= WB_ALU;
                    regwrite <= '1';
                    uses_rs1 <= '1';
                    uses_rs2 <= '0';
                    case funct3 is 
                        when FUNCT3_IMM_ADDI => aluop <= ALU_ADD;
                        when FUNCT3_IMM_SLTI => aluop <= ALU_SLT;
                        when FUNCT3_IMM_SLTIU => aluop <= ALU_SLTU;
                        when FUNCT3_IMM_XORI => aluop <= ALU_XOR;
                        when FUNCT3_IMM_ORI => aluop <= ALU_OR;
                        when FUNCT3_IMM_ANDI => aluop <= ALU_AND;
                        when FUNCT3_IMM_SLLI  => aluop <= ALU_SLL;
                                    if funct7 /= "0000000" then illegal <= '1'; end if;
                        when FUNCT3_IMM_SRLI_SRAI =>
                                    if    funct7 = FUNCT7_IMM_SRLI then aluop <= ALU_SRL;
                                    elsif funct7 = FUNCT7_IMM_SRAI then aluop <= ALU_SRA;
                                    else  illegal <= '1';
                                    end if;
                        when others => illegal <= '1';
                    end case;

                when OPCODE_AUIPC =>
                --add upper immediate to program counter (lower 12 bits of rd are filled with 0,
                --rd=pc+(imm<<12)
                    imm <= unsigned(resize(signed(inst(31 downto 12) & x"000"), XLEN));
                    -- x"000" adds 12 bits because each hex character is 4 bits
                    alu_src_a <= SRC_A_PC;
                    alu_src_b <= SRC_B_IMM;
                    -- same as defaults
                    regwrite <= '1';
                    
                when OPCODE_BRANCH =>
                   imm <= unsigned(resize(signed(inst(31) & inst(7) & inst(30 downto 25) & inst(11 downto 8) & '0'), XLEN));
                    -- always alu add for target address, comparator for condition
                    -- is a separate unit. therefore alu takes pc+imm
                    alu_src_a <= SRC_A_PC;
                    alu_src_b <= SRC_B_IMM;
                    -- funct3 signals the branch type
                    case funct3 is
                        when FUNCT3_BRANCH_BEQ  => branch_type <= BR_EQ;
                        when FUNCT3_BRANCH_BNE  => branch_type <= BR_NE;
                        when FUNCT3_BRANCH_BLT  => branch_type <= BR_LT;
                        when FUNCT3_BRANCH_BGE  => branch_type <= BR_GE;
                        when FUNCT3_BRANCH_BLTU => branch_type <= BR_LTU;
                        when FUNCT3_BRANCH_BGEU => branch_type <= BR_GEU;
                        when others             => illegal <= '1';    -- 010, 011
                    end case;
                    uses_rs1 <= '1';
                    uses_rs2 <= '1';
                when OPCODE_JALR =>
                    if funct3 /= "000" then illegal <= '1';
                    end if;
                    imm <= unsigned(resize(signed(inst(31 downto 20)), XLEN));
                    alu_src_a <= SRC_A_RS1;
                    alu_src_b <= SRC_B_IMM;
                    uses_rs1 <= '1';
                    branch_type <= BR_JALR;
                    regwrite <= '1';
                    wb_sel <= WB_PC4;

                when OPCODE_JAL =>
                -- no funct3
                    imm <= unsigned(resize(signed(inst(31) & inst(19 downto 12) & inst(20) & inst(30 downto 21) & '0'), XLEN));
                    alu_src_a <= SRC_A_PC;
                    alu_src_b <= SRC_B_IMM;
                    uses_rs1 <= '0';
                    uses_rs2 <= '0';
                    branch_type <= BR_JAL;
                    --return address pc+4 is also stored in rd
                    wb_sel <= WB_PC4;
                    regwrite <= '1';
                when OPCODE_OP =>
                    -- R-type, no imm
                    alu_src_a <= SRC_A_RS1;
                    alu_src_b <= SRC_B_RS2;
                    regwrite  <= '1';
                    uses_rs1  <= '1';
                    uses_rs2  <= '1';
                    if funct7 = "0000000" then
                        case funct3 is
                            when FUNCT3_OP_ADD_SUB => aluop <= ALU_ADD;
                            when FUNCT3_OP_SLL     => aluop <= ALU_SLL;
                            when FUNCT3_OP_SLT     => aluop <= ALU_SLT;
                            when FUNCT3_OP_SLTU    => aluop <= ALU_SLTU;
                            when FUNCT3_OP_XOR     => aluop <= ALU_XOR;
                            when FUNCT3_OP_SRL_SRA => aluop <= ALU_SRL;
                            when FUNCT3_OP_OR      => aluop <= ALU_OR;
                            when FUNCT3_OP_AND     => aluop <= ALU_AND;
                            when others            => null;
                        end case;
                    elsif funct7 = "0100000" then
                        case funct3 is
                            when FUNCT3_OP_ADD_SUB => aluop <= ALU_SUB;
                            when FUNCT3_OP_SRL_SRA => aluop <= ALU_SRA;
                            when others            => illegal <= '1';  
                        end case;
                    else
                        illegal <= '1';   -- 0000001 = RV32M (MUL/DIV)
                    end if;
                when OPCODE_LUI =>
                    -- loads the immediate into the upper bits of rd, lower 12 bits zeroed
                    imm <= unsigned(resize(signed(inst(31 downto 12) & x"000"), XLEN));
                    alu_src_a <= SRC_A_ZERO;   -- 0 + imm = imm to preserve it
                    alu_src_b <= SRC_B_IMM;
                    regwrite <= '1';
                    --defaults for rest
                when OPCODE_SYSTEM =>
                    -- RV32I: only ECALL/EBREAK. CSR instructions (Zicsr) and MRET/WFI
                    -- (privileged spec) share this opcode and are illegal for now
                    if inst = x"00000073" then
                        ecall <= '1';
                    elsif inst = x"00100073" then
                        ebreak <= '1';
                    else
                        illegal <= '1';
                    end if;
                when others => illegal <= '1';
            end case;
       end process;
end Behavioral;
