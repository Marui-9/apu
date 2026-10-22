----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/22/2026 06:48:26 AM
-- Design Name: 
-- Module Name: fw_unit - Behavioral
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

entity fw_unit is
  Port ( 
    --vivado removes unused fields so can use pipeline registers directly
    wb_data : in unsigned(XLEN-1 downto 0);  -- producer value: load data or ex_result)
    id_ex_reg : in id_ex_t; -- consumer instruction that needs the forwarded value
    ex_mem_reg : in ex_mem_t;-- producer one stage behind
    mem_wb_reg : in mem_wb_t;-- producer two stages behind
    --
    rs1_fwd : out unsigned(XLEN-1 downto 0);
    rs2_fwd : out unsigned(XLEN-1 downto 0)
  );
end fw_unit;
    
architecture Behavioral of fw_unit is
begin
    -- check mem first because it's the younger of the two producers
    rs1_fwd <= ex_mem_reg.ex_result 
                    when ex_mem_reg.wb.regwrite = '1' and ex_mem_reg.rd /= "00000" 
                    and id_ex_reg.rs1_addr = ex_mem_reg.rd --take alu result when consumer 1 cycle older
               else wb_data
                    when mem_wb_reg.wb.regwrite ='1' and mem_wb_reg.rd /= "00000"
                    and mem_wb_reg.rd = id_ex_reg.rs1_addr -- take mem stage value when 2 cycles
               else 
                    id_ex_reg.rs1_data; --otherwise leave the rs1 as is (write through)
               
    rs2_fwd <= ex_mem_reg.ex_result 
                    when ex_mem_reg.wb.regwrite = '1' and ex_mem_reg.rd /= "00000" 
                    and id_ex_reg.rs2_addr = ex_mem_reg.rd --take alu result when consumer 1 cycle older
               else wb_data
                    when mem_wb_reg.wb.regwrite ='1' and mem_wb_reg.rd /= "00000"
                    and mem_wb_reg.rd = id_ex_reg.rs2_addr -- take mem stage value when 2 cycles
               else 
                    id_ex_reg.rs2_data; --otherwise leave the rs1 as is (write through)
end Behavioral;
