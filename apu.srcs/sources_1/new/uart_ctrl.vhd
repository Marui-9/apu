----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2026 08:52:16 AM
-- Design Name: 
-- Module Name: uart_ctrl - Behavioral
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

entity uart_ctrl is
    Port(
        clk : in std_logic;
        rst : in std_logic;
        tx_busy : in std_logic;
        tx_out : out std_logic_vector( 7 downto 0);
        tx_stb : out std_logic
    );
end uart_ctrl;

architecture Behavioral of uart_ctrl is
    constant msg_ascii : std_logic_vector(55 downto 0) := x"48656C6C6F2120";
    
    constant MSG_MAX : integer := msg_ascii'length -8;
    
    signal tx_ptr : integer range 0 to MSG_MAX := MSG_MAX;
    signal tx_busy_i : std_logic := '0';
    signal tx_cont : std_logic := '0';
    
    type ctrl_state_t is (idle, shift, busy);
begin


end Behavioral;
