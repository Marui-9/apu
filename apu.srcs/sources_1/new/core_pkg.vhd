----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/01/2026 09:29:54 AM
-- Design Name: 
-- Module Name: config_pkg - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

package core_pkg is 
    subtype opcode_t is std_logic_vector(6 downto 0);
    subtype funct3_t is std_logic_vector(2 downto 0);
    subtype funct7_t is std_logic_vector(6 downto 0);
    -- (RV32I base, inst[1:0] = "11" always)
    constant OPCODE_LOAD     : opcode_t := "0000011"; --unique: LB
    constant OPCODE_STORE    : opcode_t := "0100011";
    constant OPCODE_MISC_MEM : opcode_t := "0001111"; -- FENCE (all have 000 as funct3)
    constant OPCODE_OP_IMM   : opcode_t := "0010011";
    constant OPCODE_AUIPC    : opcode_t := "0010111";--unique Utype
    constant OPCODE_BRANCH   : opcode_t := "1100011";
    constant OPCODE_JALR     : opcode_t := "1100111";--unique
    constant OPCODE_JAL      : opcode_t := "1101111";--unique
    constant OPCODE_OP       : opcode_t := "0110011";
    constant OPCODE_LUI      : opcode_t := "0110111";--unique Utype
    constant OPCODE_SYSTEM   : opcode_t := "1110011";--funct3"000" for both ECALL & EBREAK
    ---STORE---
     constant FUNCT3_STORE_SB : funct3_t := "000"; 
     constant FUNCT3_STORE_SH : funct3_t := "001";
     constant FUNCT3_STORE_SW : funct3_t := "010";
    ---OP-IMM---
    constant FUNCT3_IMM_ADDI : funct3_t := "000";
    constant FUNCT3_IMM_SLTI : funct3_t := "010";
    constant FUNCT3_IMM_SLTIU : funct3_t := "011";
    constant FUNCT3_IMM_XORI : funct3_t := "100";
    constant FUNCT3_IMM_ORI : funct3_t := "110";
    constant FUNCT3_IMM_ANDI : funct3_t := "111";
    constant FUNCT3_IMM_SLLI : funct3_t := "001";
    constant FUNCT3_IMM_SRLI_SRAI : funct3_t := "101";
    ---BRANCH---
    constant FUNCT3_BRANCH_BEQ : funct3_t := "000";
    constant FUNCT3_BRANCH_BNE : funct3_t := "001";
    constant FUNCT3_BRANCH_BLT : funct3_t := "100";
    constant FUNCT3_BRANCH_BGE : funct3_t := "101";
    constant FUNCT3_BRANCH_BLTU : funct3_t := "110";
    constant FUNCT3_BRANCH_BGEU : funct3_t := "111";
    ---LOAD---
    constant FUNCT3_LOAD_LB : funct3_t := "000";
    constant FUNCT3_LOAD_LH : funct3_t := "001";
    constant FUNCT3_LOAD_LW : funct3_t := "010";
    constant FUNCT3_LOAD_LBU : funct3_t := "100";
    constant FUNCT3_LOAD_LHU : funct3_t := "101";
    ---OP---
    constant FUNCT3_OP_ADD_SUB : funct3_t := "000";
    constant FUNCT3_OP_SLL : funct3_t := "001";
    constant FUNCT3_OP_SLT : funct3_t := "010";
    constant FUNCT3_OP_SLTU : funct3_t := "011";
    constant FUNCT3_OP_XOR : funct3_t := "100";
    constant FUNCT3_OP_SRL_SRA : funct3_t := "101";
    constant FUNCT3_OP_OR : funct3_t := "110";
    constant FUNCT3_OP_AND : funct3_t := "111";
    
    constant FUNCT7_IMM_SRLI : funct7_t := "0000000";
    constant FUNCT7_IMM_SRAI : funct7_t := "0100000";
    constant FUNCT7_OP_ADD : funct7_t := "0000000";
    constant FUNCT7_OP_SUB : funct7_t := "0100000";
    constant FUNCT7_OP_SRL : funct7_t := "0000000";
    constant FUNCT7_OP_SRA : funct7_t := "0100000";
    
    type ALU_OP is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU);
    type INSTR_FORMAT is (R_TYPE, I_TYPE, S_TYPE, B_TYPE, U_TYPE, J_TYPE);
    type BRANCH_T    is (BR_NONE, BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU, BR_JAL, BR_JALR);
    type ALU_SRC_A_T is (SRC_A_RS1, SRC_A_PC, SRC_A_ZERO);
    type ALU_SRC_B_T is (SRC_B_RS2, SRC_B_IMM);
    type WB_SEL_T    is (WB_ALU, WB_MEM, WB_PC4);   -- what gets written to rd
    subtype reg_addr is std_logic_vector(4 downto 0);
    
end package core_pkg;
    --deferred section for stage/hazard control
    --pipeline records, control-signal record, forwarding selects