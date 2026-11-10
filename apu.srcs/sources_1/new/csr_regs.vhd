----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/09/2026 09:01:47 PM
-- Design Name: 
-- Module Name: csr_regs - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity csr_regs is
    Generic (
        ADDR_W : positive := 12      -- 2**ADDR_W registers =32
    );
    Port (
        clk      : in  std_logic;
        addr : in  std_logic_vector(ADDR_W-1 downto 0);
        -- write port, to be used by writeback mux in WB/mem
        we       : in  std_logic;
        rd_data  : in  unsigned(XLEN-1 downto 0);
        --
        reg_value : out unsigned(XLEN-1 downto 0);
    );
end csr_regs;

architecture Behavioral of csr_regs is
-- top 4 bits [11;8] encode privilege level, 
begin


end Behavioral;
