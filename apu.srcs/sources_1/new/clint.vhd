----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/09/2026 09:31:57 PM
-- Design Name: 
-- Module Name: clint - Behavioral
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
use work.config_pkg.all;
--use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clint is
  Port ( 
        clk   : in  std_logic;
        rst : in std_logic;
        mtimecmp_val : in unsigned(63 downto 0); --software reads mtime, adds N for desired latency, then clint compares
        --
        clint_equality: out std_logic
  ); 
end clint;

architecture Behavioral of clint is
    signal mtime : unsigned(XLEN-1 downto 0); --free running counter (millions of years to oveflow)
    signal mtime_cmp : unsigned(XLEN-1 downto 0); -- software written
begin
    write_output : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
            mtime <= (others => '0');   -- reset to 0
            mtime_cmp <= (others => '1');
        else
            mtime <= mtime + 1;          -- +1 every cycle
            mtime_cmp <= mtimecmp_val;
        end if;
        clint_equality  <= '1' when mtime >= mtime_cmp else '0'; -- inside clock process so it has one cycle latency
    end process;
end Behavioral;
