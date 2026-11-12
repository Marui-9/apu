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
              MEM_SIZE : positive := 14; -- substitutes ADDR_WIDTH
              CLK_FREQ : integer := 100000000;
              BAUD_RATE : integer := 115200
              ); 
    port (
        clk : in std_logic;
        rst : in std_logic;
        uart_tx : out std_logic
    );
end soc;

architecture Behavioral of soc is
    signal imem_addr  : unsigned(31 downto 0);
    signal imem_rdata : std_logic_vector(31 downto 0);
    --
    signal bus_re   : std_logic; 
    signal bus_we    : std_logic_vector(3 downto 0);
    signal bus_addr  : std_logic_vector(31 downto 0);
    signal bus_wdata : std_logic_vector(31 downto 0);
    signal bus_rdata : std_logic_vector(31 downto 0);
    --
    signal clint_mtip : std_logic; -- will later connect to core interrupt input

begin
    instance_core : entity work.core
        port map (
            clk => clk, rst => rst,
            imem_rdata => imem_rdata, 
            imem_addr  => imem_addr,
            --peripheral bus drives
            bus_addr => bus_addr, 
            bus_wdata => bus_wdata, 
            bus_we => bus_we,
            bus_re => bus_re,
            bus_rdata => bus_rdata
        );

    instance_imem : entity work.memory
        generic map (
            INIT_FILE  => INIT_FILE,
            ADDR_WIDTH => MEM_SIZE
             )
        port map (
            clk   => clk,
            en    =>  '1',  -- fetch every cycle  
            we    => "0000",                   -- read-only
            addr  => std_logic_vector(imem_addr),
            wdata => (others => '0'),
            rdata => imem_rdata 
        );
    instance_mmio : entity work.mmio
        generic map (
            INIT_FILE  => INIT_FILE,
            ADDR_WIDTH => MEM_SIZE
             )
        port map (
            clk => clk,
            rst => rst, 
            re => bus_re,
            we => bus_we,
            addr => bus_addr,
            wdata => bus_wdata, 
            rdata => bus_rdata,
            uart_tx => uart_tx,
            clint_mtip => clint_mtip
        );
        
end Behavioral;

