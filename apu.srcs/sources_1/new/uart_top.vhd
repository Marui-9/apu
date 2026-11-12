----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2026 08:45:35 AM
-- Design Name: 
-- Module Name: uart_top - Behavioral
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

entity uart_top is
  Generic(
        CLK_FREQ : integer := 100000000;
        BAUD_RATE : integer := 115200
  );
  Port ( 
        clk: in std_logic;
        rst : in  std_logic;
        rx : in std_logic := '1';
        addr_uart : in std_logic_vector(3 downto 0);
        we_uart : in std_logic_vector(3 downto 0);
        wdata_uart : in std_logic_vector(31 downto 0);
        rdata_uart : out std_logic_vector(31 downto 0);
        uart_tx : out std_logic
  );
end uart_top;

architecture Behavioral of uart_top is
    signal top_stb : std_logic := '0';
    signal tx_busy : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
begin
    instance_uart_tx :entity  work.uart_tx
        generic map(
            CLK_FREQ => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map(
            clk => clk,
            rst => rst,
            din => tx_data,
            stb => top_stb,
            busy => tx_busy,
            tx => uart_tx
        ); 
    top_stb <= '1' when we_uart(0) = '1' and addr_uart = x"0" else '0';
    tx_data <= wdata_uart(7 downto 0);
    process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rdata_uart <= (others => '0');
            else
                case addr_uart is
                    when "0100" =>
                        rdata_uart <= (0 => tx_busy, others => '0');
                when others =>                            -- tx is write only, the rest is unmapped
                    rdata_uart <= (others => '0');
                end case;
            end if;
        end if;
    end process;    
    
end Behavioral;
