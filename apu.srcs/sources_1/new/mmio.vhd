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
use IEEE.NUMERIC_STD.ALL;

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
        rdata : out std_logic_vector(31 downto 0);
        clint_mtip : out std_logic
    );
end mmio;

architecture Behavioral of mmio is
    signal sel_dmem_reg : std_logic;
    signal sel_clint_reg : std_logic;
    signal sel_uart_reg : std_logic;
    
    signal bus_rdata_dmem : std_logic_vector(31 downto 0);
    signal dmem_re : std_logic;
    signal dmem_we : std_logic_vector(3 downto 0);

    signal bus_rdata_clint : std_logic_vector(31 downto 0);
    signal clint_we : std_logic_vector(3 downto 0);
    signal clint_re : std_logic;
    
    signal bus_rdata_uart : std_logic_vector(31 downto 0);
    signal uart_re : std_logic;
    
    signal sel_clint_next : std_logic;
    signal sel_dmem_next : std_logic;
    signal sel_uart_next : std_logic;
begin
    instance_clint : entity work.clint
    port map(
        clk => clk,
        rst => rst,
        we_clint => clint_we,
        addr_clint => addr(15 downto 0),
        wdata_clint => wdata,
        rdata_clint => bus_rdata_clint,
        clint_mtip => clint_mtip
    );
        instance_dmem : entity work.dmem
        generic map (
            INIT_FILE  => INIT_FILE,
            ADDR_WIDTH => ADDR_WIDTH
             )
        port map(
        clk => clk,
        --rst => rst,
        re_dmem => dmem_re,
        we_dmem => dmem_we,
        addr_dmem => addr,
        wdata_dmem => wdata,
        rdata_dmem => bus_rdata_dmem
    );
    --these outside of process
    sel_dmem_next  <= '1' when addr >= x"80000000" else '0';
    sel_clint_next <= '1' when addr >= x"02000000" and addr < x"80000000" else '0';
    sel_uart_next  <= '1' when addr >= x"01000000" and addr < x"02000000" else '0';
    
    dmem_re  <= re when sel_dmem_next  = '1' else '0';
    dmem_we  <= we when sel_dmem_next  = '1' else "0000";
    clint_we <= we when sel_clint_next = '1' else "0000";
    process(clk)
        begin 
       
       --clint_mtip <= '0'; -- already assigned
            -- dmem
        if rising_edge(clk) then
            if rst = '1' then
                sel_dmem_reg  <= '0';
                sel_clint_reg <= '0';
                sel_uart_reg  <= '0';
            else
                sel_dmem_reg  <= sel_dmem_next;
                sel_clint_reg <= sel_clint_next;
                sel_uart_reg  <= sel_uart_next;

            end if;
        end if;
    end process;
     rdata <= bus_rdata_dmem  when sel_dmem_reg  = '1' else
     bus_rdata_clint when sel_clint_reg = '1' else
     (others => '0');                       -- unmapped address: reads 0
end Behavioral;
