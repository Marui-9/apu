----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/01/2026 09:29:54 AM
-- Design Name: 
-- Module Name: config_pkg - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

package config_pkg is 
    constant XLEN : integer := 32;
    constant SHAMT_W : integer := integer(ceil(log2(real(XLEN)))); 
    --log2 of real converts XLEN to a float and finds its log, then ceil rounds up to nearest integer
    -- that is for e.g. 27 bits -> 4,75 = 5 covers the whole range, then cast to integer
    constant RST_VEC : std_logic_vector(XLEN-1 downto 0) := x"00000000"; -- or 16#00000000# if it was an integer
    
end package config_pkg;

--if you need constant functions
--package body config_pkg is
 -- function/procedure implementations
--end pkg config_pkg;