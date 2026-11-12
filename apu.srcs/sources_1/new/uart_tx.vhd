----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2026 08:45:32 PM
-- Design Name: 
-- Module Name: uart - Behavioral
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

entity uart_tx is
    generic(
        CLK_FREQ : integer := 100000000; --100 MHz
        BAUD_RATE : integer := 115200
        );
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        stb : in std_logic; --one pulse of strobe means "send din"
        din : in std_logic_vector(7 downto 0);
        --
        tx : out std_logic;
        busy : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLKS_PER_BIT : integer := CLK_FREQ/BAUD_RATE; 
    type tx_state_t is (idle, start, data, stop);
    signal tx_state : tx_state_t := idle;
    signal msg : std_logic_vector(7 downto 0) := (others => '0');
    signal counter : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal idx : integer range 0 to 7 := 0; -- to keep track of what message bit is being sent
     
begin
    process(clk) is
    begin
        if rising_edge(clk) then
            if (rst = '1') then 
                msg <= (others => '0');
                busy <= '0';
                tx <= '1';
                counter <= 0;
                idx <= 0;
                tx_state <= idle;
            else
                case tx_state is
                    when idle =>
                        tx <= '1';
                        if (stb = '1') then 
                            msg <= din;
                            busy <= '1';
                            tx_state <= start;
                        end if; --no need for else, keep the reset values for others
                    when start =>
                        tx <= '0'; --wait one bit time
                        if (counter = CLKS_PER_BIT-1) then
                            counter <= 0;
                            tx_state <= data;
                        else 
                            counter <= counter +1;
                        end if;
                    when data =>
                        tx <= msg(idx);
                        if (counter = CLKS_PER_BIT-1) then
                            counter <= 0;
                            if (idx = 7) then
                                idx <= 0;
                                tx_state <= stop;
                            else
                                idx <= idx +1;
                            end if;
                        else 
                            counter <= counter +1;
                        end if;                        
                    when stop =>
                        if (counter = CLKS_PER_BIT-1) then
                            counter <= 0;
                            busy <= '0';
                            tx_state <= idle;
                        else
                            counter <= counter+1;
                        end if;
                        tx <= '1'; 
                end case;
            end if;
        end if;
    end process;
end Behavioral;
