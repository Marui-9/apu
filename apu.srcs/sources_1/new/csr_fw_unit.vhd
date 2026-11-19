----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11/19/2026 07:59:37 AM
-- Design Name:
-- Module Name: csr_fw_unit - Behavioral
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
use work.pipeline_pkg.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Forwards the NEW csr value of an older, not yet committed csr write to the
-- csr instruction in EX. Same idea as fw_unit but keyed on the 12-bit csr
-- address and enabled by csr_we. The gpr operand of the csr instruction is
-- still forwarded by fw_unit.
entity csr_fw_unit is
  Port (
    csr_rdata   : in unsigned(XLEN-1 downto 0); -- csr_regfile read for id_ex_reg.csr_addr
    id_ex_reg   : in id_ex_t;                   
    ex_mem_reg  : in ex_mem_t;-- producer one stage ahead
    mem_wb_reg  : in mem_wb_t; -- producer two stages ahead
    --
    old_csr_fwd : out unsigned(XLEN-1 downto 0) -- goes to csr_unit.old_csr
  );
end csr_fw_unit;

architecture Behavioral of csr_fw_unit is
begin
    -- ex_mem first because it is the younger producer. A bubble or a csr
    --instruction that does not write has csr_we = '0' and never matches.
    old_csr_fwd <= ex_mem_reg.csr_wdata
                        when ex_mem_reg.csr_we = '1'
                         and ex_mem_reg.csr_addr = id_ex_reg.csr_addr
                   else mem_wb_reg.csr_wdata
                        when mem_wb_reg.csr_we = '1'
                         and mem_wb_reg.csr_addr = id_ex_reg.csr_addr
                   else
                        csr_rdata; -- no in-flight write: regfile value is current
end Behavioral;
