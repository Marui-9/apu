----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11/18/2026 04:38:16 PM
-- Design Name:
-- Module Name: csr_unit - Behavioral
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
use work.core_pkg.all;
use work.config_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--   funct3(2)          : 1 = immediate form (CSRRWI/SI/CI), 0 = register form
--   funct3(1 downto 0) : 01 = write, 10 = set bits, 11 = clear bits
entity csr_unit is
  Port (
        csr_en : in  std_logic; -- instruction is a csr one
        funct3 : in  funct3_t;
        old_csr : in  unsigned(XLEN-1 downto 0); -- from csr_fw_unit 
        rs1_val : in  unsigned(XLEN-1 downto 0);-- from fw_unit.rs1_fwd 
        rs1_idx : in  std_logic_vector(4 downto 0);    --reg index or imm
        --
        new_csr : out unsigned(XLEN-1 downto 0);      
        csr_we  : out std_logic  -- =write really happens
    );
end csr_unit;

architecture Behavioral of csr_unit is
    signal operand : unsigned(XLEN-1 downto 0);
    signal op      : std_logic_vector(1 downto 0);
begin
    op <= funct3(1 downto 0);

    -- immediate forms use the zero-extended 5-bit field, register forms the rs1 value
    operand <= resize(unsigned(rs1_idx), XLEN) when funct3(2) = '1'
               else rs1_val;

    new_csr <= operand                 when op = "01" else -- CSRRW/ CSRRWI
               old_csr or operand      when op = "10" else -- CSRRS/ CSRRSI
               old_csr and not operand when op = "11" else -- CSRRC /CSRRCI
               old_csr;

    -- CSRRW/CSRRWI always write. CSRRS/C and immediat forms do not write when the
    --rs1 field (index or uimm, not the register contents) is 0.
    csr_we <= '0' when csr_en = '0' else
              '1' when op = "01" else
              '1' when op /= "00" and rs1_idx /= "00000" else
              '0';
end Behavioral;
