----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/10/2026 03:08:24 PM
-- Design Name: 
-- Module Name: mmio - Behavioral
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

entity mmio is
    generic( -- default values for when the instance is not given any
        ADDR_WIDTH : positive := 14; -- not natural because cannot be negative
        INIT_FILE : string := "test1.mem"
    );
    port (
        clk   : in  std_logic;
        rst : in std_logic;
        --bus interface
        re    : in  std_logic;
        we    : in  std_logic_vector(3 downto 0); -- byte addressed, one enable per byte
        addr  : in  std_logic_vector(31 downto 0);   -- word address
        wdata : in  std_logic_vector(31 downto 0);
        rdata : out std_logic_vector(31 downto 0)
    );
end mmio;

architecture Behavioral of mmio is
begin
    instance_clint : entity work.clint
    port map(
        clk => clk,
        rst => rst,
        re => re,
        we => we,
        addr => addr,
        wdata => wdata,
        rdata => rdata
    );
        instance_dmem : entity work.dmem
    port map(
        clk => clk,
        --rst => rst,
        re => re,
        we => we,
        addr => addr,
        wdata => wdata,
        rdata => rdata
    );
end Behavioral;
