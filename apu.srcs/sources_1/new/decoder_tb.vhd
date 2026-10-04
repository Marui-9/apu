----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/04/2026 06:06:40 AM
-- Design Name: 
-- Module Name: decoder_tb - Behavioral
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
library work;
use work.core_pkg.all;
use work.config_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder_tb is
--  Port ( );
end decoder_tb;

architecture test of decoder_tb is
    signal inst_s : std_logic_vector(XLEN-1 downto 0);
begin
    dut: entity work.decoder
    port map(
        inst => inst_s
    );

end test;
