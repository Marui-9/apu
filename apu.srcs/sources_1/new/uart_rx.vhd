----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2026 02:20:07 PM
-- Design Name: 
-- Module Name: uart_rx - Behavioral
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

entity uart_rx is
    generic(
        CLK_FREQ : integer := 100000000; --100 MHz
        BAUD_RATE : integer := 115200
        );
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        rx : in std_logic;
        --
        dout : out std_logic_vector(7 downto 0);
        stb : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLKS_PER_BIT : integer := CLK_FREQ/BAUD_RATE;
    type rx_state_t is (idle, start, data, stop);
    signal rx_state : rx_state_t := idle;
    signal msg : std_logic_vector(7 downto 0) := (others => '0');
    signal counter : integer range 0 to CLKS_PER_BIT-1:= 0;
    signal idx : integer range  0 to 7 := 0;
    signal rx_metastable : std_logic := '1';
    signal rx_clocked : std_logic := '1';
begin
    process(clk) is
    begin
        if rising_edge(clk) then
            rx_metastable <= rx; -- if rx changes at clock edge it may go metastable
            rx_clocked <= rx_metastable;
            if (rst = '1') then 
                msg <= (others => '0');
                dout <= (others => '0');
                counter <= 0;
                idx <= 0;
                stb <= '0';
                rx_state <= idle;
            else    
                case rx_state is
                when idle =>
                    msg <= (others => '0');
                    stb <= '0';
                    if (rx_clocked = '0') then
                        rx_state <= start;
                    end if;
                when start =>
                    if (counter = CLKS_PER_BIT/2) then
                        counter <= 0;
                        if (rx_clocked = '0') then    
                            rx_state <= data;
                        else
                            rx_state <= idle;
                        end if;
                    else counter <= counter +1;   
                    end if;
                when data =>
                    if (counter = CLKS_PER_BIT-1) then
                        counter <= 0;
                        msg(idx) <= rx_clocked;
                        if (idx = 7) then
                            rx_state <= stop;
                            idx <= 0;
                        else
                            idx <= idx+1;
                        end if;
                    else
                        counter <= counter+1;
                    end if;
                when stop =>
                    if (counter = CLKS_PER_BIT-1) then
                        counter <= 0;
                        dout <= msg;
                        stb <= '1';
                        rx_state <= idle;
                    else
                        counter <= counter +1;
                    end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
