----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 04:34:37 PM
-- Design Name: 
-- Module Name: tb_soc - Behavioral
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

entity tb_soc is
end tb_soc;

architecture sim of tb_soc is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
begin
    clk <= not clk after 5 ns;  -- 100 mhz
    rst <= '1', '0' after 22 ns;   -- held for 2 edges, released between edges

    dut : entity work.soc
        generic map ( INIT_FILE => "test.mem" )
        port map ( clk => clk, rst => rst );
end sim;
