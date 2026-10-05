----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/04/2026 08:44:52 AM
-- Design Name: 
-- Module Name: branch_unit - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;
use work.config_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity branch_unit is
    Port (
        branch_type : in  BRANCH_T;
        pc : in unsigned (XLEN-1 downto 0);
        rs1_val     : in  unsigned(XLEN-1 downto 0);
        rs2_val     : in  unsigned(XLEN-1 downto 0);
        imm         : in  unsigned(XLEN-1 downto 0);
        --
        taken       : out std_logic;
        target      : out unsigned(XLEN-1 downto 0);
        link : out unsigned(XLEN-1 downto 0); --always pc+4, into rd
        misaligned  : out std_logic
    );
end branch_unit;


architecture Behavioral of branch_unit is
begin

    process(all)
        variable jalr_sum : unsigned(XLEN-1 downto 0);
    begin
    -- target= pc +imm , and pc+4 are always computed and just
    -- ignored when they are not needed
        taken <= '0';
        target <= pc+imm; -- branches and jal
        link <= pc +4; -- value is then propagated through pipeline registers
        jalr_sum := rs1_val + imm;
        case branch_type is
            when BR_NONE => null;
            --defaults
            when BR_EQ =>
                if rs1_val = rs2_val then   
                    taken <= '1';
                end if;
            when BR_NE =>
                if rs1_val /= rs2_val then  
                    taken <= '1';
                end if;
            when BR_LT => 
                if signed(rs1_val) < signed(rs2_val) then  
                    taken <= '1';
                end if;
            when BR_GE =>
                if signed(rs1_val) >= signed(rs2_val) then  
                    taken <= '1';
                end if;
            when BR_LTU =>
                 if rs1_val < rs2_val then  
                    taken <= '1';
                end if;
            when BR_GEU =>
                if rs1_val >= rs2_val then  
                    taken <= '1';
                end if;
            --remember jal -> unconditional jump pc+imm
                    -- jalr ->unconditional jump rs1+imm, with LSB forced to 0
            when BR_JAL =>
                taken <='1';
            when BR_JALR =>
                taken <= '1';
                target <= jalr_sum(XLEN-1 downto 1) & '0';
                --target is not automatically an even address like pc+4, 
                --riscv spec defines JALR target as that sum with bit 0 forced to '0'
           -- when others => null;
            end case;
    end process;
    misaligned <= taken and target(1);
    --outside of process because otherwise it would see the previous values of taken and target
    -- a process assigns signals once it ends. Outside a process it reads the current values. 
end architecture;

