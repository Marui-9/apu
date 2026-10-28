----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 04:32:41 PM
-- Design Name: 
-- Module Name: soc_top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity soc is
    generic ( INIT_FILE : string := "test.mem";
              MEM_SIZE : positive := 14 -- substitutes ADDR_WIDTH
              ); 
    port (
        clk : in std_logic;
        rst : in std_logic
    );
end soc;

architecture Behavioral of soc is
    signal imem_addr  : unsigned(31 downto 0);
    signal imem_rdata : std_logic_vector(31 downto 0);
    signal dmem_en    : std_logic;
    signal dmem_we    : std_logic_vector(3 downto 0);
    signal dmem_addr  : unsigned(31 downto 0);
    signal dmem_wdata : std_logic_vector(31 downto 0);
    signal dmem_rdata : std_logic_vector(31 downto 0);
begin
    instance_core : entity work.core
        port map (
            clk => clk, rst => rst,
            imem_rdata => imem_rdata, dmem_rdata => dmem_rdata,
            imem_addr  => imem_addr,
            dmem_en => dmem_en, dmem_we => dmem_we,
            dmem_addr => dmem_addr, dmem_wdata => dmem_wdata
        );

    instance_imem : entity work.memory
        generic map (
            INIT_FILE  => INIT_FILE,
            ADDR_WIDTH => MEM_SIZE
             )
        port map (
            clk   => clk,
            en    => '1',                      -- fetch every cycle
            we    => "0000",                   -- read-only
            addr  => std_logic_vector(imem_addr),
            wdata => (others => '0'),
            rdata => imem_rdata
        );

    instance_dmem : entity work.memory
        generic map (
            INIT_FILE  => INIT_FILE,
            ADDR_WIDTH => MEM_SIZE
        )
        port map (
            clk   => clk,
            en    => dmem_en,
            we    => dmem_we,
            addr  => std_logic_vector(dmem_addr),
            wdata => dmem_wdata,
            rdata => dmem_rdata
        );
end Behavioral;

