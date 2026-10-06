----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/06/2026 08:51:30 AM
-- Design Name: 
-- Module Name: core - Behavioral
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
use work.pipeline_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity core is
--  Port ( );
end core;

architecture Behavioral of core is
    signal if_id_next : if_id_t; --what is computed by IF
    signal if_id_reg : if_id_t; -- what the pip register contains
    signal id_ex_next : id_ex_t;
    signal id_ex_reg : id_ex_t;
    signal ex_mem_next : ex_mem_t;   -- what the EX stage computes (combinational)
    signal ex_mem_reg    : ex_mem_t;   -- the register itself (flip-flops)
begin


end Behavioral;
