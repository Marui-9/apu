----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/23/2026 07:10:41 AM
-- Design Name: 
-- Module Name: hazard_unit - Behavioral
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
use work.config_pkg.all;
use work.core_pkg.all;
use work.pipeline_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hazard_unit is
--haz unit takes care only of load then use for now
  Port ( 
        uses_rs1 : in std_logic;
        uses_rs2 : in std_logic;
        id_ex_reg : in id_ex_t;
        id_ex_next : in id_ex_t;
        --
        hazard_stall : out std_logic
        );
end hazard_unit;

architecture Behavioral of hazard_unit is
    signal rs1_hazard : std_logic;
    signal rs2_hazard : std_logic;
    signal load_in_ex : std_logic;
begin --if an instr wants to use a reg that is being written to by an in flight load
    load_in_ex <= '1' when id_ex_reg.mem.memread ='1' and id_ex_reg.rd /= "00000"
                    else '0';
    rs1_hazard <= '1' when load_in_ex='1' and uses_rs1='1' and id_ex_reg.rd = id_ex_next.rs1_addr
                    else '0';
    rs2_hazard <= '1' when load_in_ex='1' and uses_rs2='1' and id_ex_reg.rd = id_ex_next.rs2_addr
                    else '0';      
    hazard_stall <= '1' when rs1_hazard='1' or rs2_hazard='1' else '0';

end Behavioral;
