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
        addr : in unsigned(15 downto 0);
        wdata : in std_logic_vector(31 downto 0); --software reads mtime, adds N for desired latency, then clint compares
        we : in std_logic_vector(3 downto 0); -- memory is byte addressed
        --
        clint_mtip: out std_logic;
        rdata : out std_logic_vector(31 downto 0)
  ); 
end clint;

architecture Behavioral of clint is
    signal mtime : unsigned(63 downto 0); --free running counter (millions of years to oveflow)
    signal mtime_cmp : unsigned(63 downto 0); -- software written
begin
    
    write_output : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mtime <= (others => '0');   -- reset to 0
                mtime_cmp <= (others => '1');
                clint_mtip <= '0';
                rdata <= (others => '0');
            else
                mtime <= mtime + 1;          -- +1 every cycle
                --mtime_cmp <= wdata; 
                if we /= "0000" then
                    case addr is    
                        when x"4000" => mtime_cmp(31 downto 0) <= unsigned(wdata);
                        when x"4004" => mtime_cmp(63 downto 32) <= unsigned(wdata);
                        when x"BFF8" => mtime(31 downto 0) <= unsigned(wdata); -- could be null for read only mtime
                        when x"BFFC" => mtime(63 downto 32) <= unsigned(wdata);-- could be null for read only mtime
                         when others => null;
                    end case;
                else 
                    case addr is
                        when x"4000" => rdata <= std_logic_vector(mtime_cmp(31 downto 0));
                        when x"4004" => rdata <= std_logic_vector(mtime_cmp(63 downto 32));
                        when x"BFF8" => rdata <= std_logic_vector(mtime(31 downto 0));
                        when x"BFFC" => rdata <= std_logic_vector(mtime(63 downto 32));
                        when others => rdata <= (others => '0');
                    end case; 
                end if;
            clint_mtip  <= '1' when mtime >= mtime_cmp else '0'; 
                -- inside clock process so it has one cycle latency
            end if;  
        end if;
    end process;
end Behavioral;
