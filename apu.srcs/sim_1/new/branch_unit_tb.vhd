----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/05/2026 07:22:11 AM
-- Design Name: 
-- Module Name: branch_unit_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity branch_unit_tb is
end branch_unit_tb;

architecture Behavioral of branch_unit_tb is
        signal branch_type_t :  BRANCH_T;
        signal pc_t :  unsigned (XLEN-1 downto 0);
        signal rs1_val_t     :  unsigned(XLEN-1 downto 0);
        signal rs2_val_t     : unsigned(XLEN-1 downto 0);
        signal imm_t      : unsigned(XLEN-1 downto 0);
        --
        signal taken_t      : std_logic;
        signal target_t     : unsigned(XLEN-1 downto 0);
        signal link_t       : unsigned(XLEN-1 downto 0);
        signal misaligned_t : std_logic;
begin
dut: entity work.branch_unit
        port map(
            branch_type => branch_type_t,
            pc => pc_t,
            rs1_val => rs1_val_t,
            rs2_val => rs2_val_t,
            imm => imm_t,
            taken      => taken_t,
            target     => target_t,
            link       => link_t,
            misaligned => misaligned_t
        );
stimulus: process   
    begin
        --blt vs bltu
        branch_type_t <= BR_LT;
        pc_t <= 32x"100";
        rs1_val_t <= x"FFFFFFFF";
        rs2_val_t <= to_unsigned(1, XLEN);
        imm_t <= to_unsigned(8, XLEN);
        wait for 10 ns;
        assert taken_t ='1' report "blt wrong" severity error;
        assert target_t = x"00000108" report "blt wrong" severity error;
        assert  link_t = x"00000104" report "blt wrong" severity error;
        
        branch_type_t <= BR_LTU;
        pc_t <= 32x"100";
        rs1_val_t <= x"FFFFFFFF";
        rs2_val_t <= to_unsigned(1, XLEN);
        wait for 10 ns;
        assert taken_t ='0' report "bltu wrong" severity error;

        --equal operands: edge case for >=
        --signals keep their value, so only branch_type_t changes below
        rs1_val_t <= to_unsigned(5, XLEN);
        rs2_val_t <= to_unsigned(5, XLEN);
        branch_type_t <= BR_EQ;
        wait for 10 ns;
        assert taken_t = '1' report "beq equal not taken" severity error;

        branch_type_t <= BR_NE;
        wait for 10 ns;
        assert taken_t = '0' report "bne equal taken" severity error;

        branch_type_t <= BR_GE;
        wait for 10 ns;
        assert taken_t = '1' report "bge equal not taken" severity error;

        branch_type_t <= BR_GEU;
        wait for 10 ns;
        assert taken_t = '1' report "bgeu equal not taken" severity error;

        --jalr with odd sum: bit 0 must be cleared
        branch_type_t <= BR_JALR;
        rs1_val_t <= x"00001001";
        imm_t <= to_unsigned(0, XLEN);
        wait for 10 ns;
        assert taken_t = '1' report "jalr not taken" severity error;
        assert target_t = x"00001000" report "jalr bit 0 not cleared" severity error;
        assert link_t = x"00000104" report "jalr wrong link" severity error;
        assert misaligned_t = '0' report "jalr wrongly misaligned" severity error;

        --jalr with target bit 1 set: misaligned
        rs1_val_t <= x"00001000";
        imm_t <= to_unsigned(2, XLEN);
        wait for 10 ns;
        assert target_t = x"00001002" report "jalr wrong target" severity error;
        assert misaligned_t = '1' report "jalr misaligned not flagged" severity error;

        --beq with misaligned target pc+6: exception only if taken
        branch_type_t <= BR_EQ;
        pc_t <= 32x"100";
        imm_t <= to_unsigned(6, XLEN);
        rs1_val_t <= to_unsigned(5, XLEN);
        rs2_val_t <= to_unsigned(7, XLEN);
        wait for 10 ns;
        assert taken_t = '0' report "beq unequal taken" severity error;
        assert target_t = x"00000106" report "beq wrong target" severity error;
        assert misaligned_t = '0' report "misaligned on not-taken branch" severity error;

        rs2_val_t <= to_unsigned(5, XLEN);  -- now equal, so taken
        wait for 10 ns;
        assert taken_t = '1' and misaligned_t = '1'
            report "misaligned taken branch not flagged" severity error;

        --jal backward by 12: target = pc+imm, rs1 must be ignored
        branch_type_t <= BR_JAL;
        rs1_val_t <= x"00002000";
        imm_t <= unsigned(to_signed(-12, XLEN));
        wait for 10 ns;
        assert taken_t = '1' report "jal not taken" severity error;
        assert target_t = x"000000F4" report "jal wrong target" severity error;
        assert link_t = x"00000104" report "jal wrong link" severity error;
        assert misaligned_t = '0' report "jal wrongly misaligned" severity error;

        --none: never taken, never misaligned, even with equal operands and target pc+6
        branch_type_t <= BR_NONE;
        rs1_val_t <= to_unsigned(5, XLEN);
        rs2_val_t <= to_unsigned(5, XLEN);
        imm_t <= to_unsigned(6, XLEN);
        wait for 10 ns;
        assert taken_t = '0' and misaligned_t = '0' report "br_none taken" severity error;

        report "branch_unit_tb finished" severity note;
        wait;
    end process stimulus;
end Behavioral;
