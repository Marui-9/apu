----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2026 11:50:10 AM
-- Design Name: 
-- Module Name: mem_stage - Behavioral
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
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity mem_stage is
    port (
        ex_mem_reg  : in  ex_mem_t;
        --
        mem_wb_next : out mem_wb_t;
        dmem_addr   : out unsigned(XLEN-1 downto 0);
        dmem_wdata  : out std_logic_vector(XLEN-1 downto 0);
        dmem_we     : out std_logic_vector(3 downto 0);
        dmem_en     : out std_logic
    );
end mem_stage;

architecture Behavioral of mem_stage is
    alias addr_lo : unsigned(1 downto 0) is ex_mem_reg.ex_result(1 downto 0);
    signal sd     : std_logic_vector(XLEN-1 downto 0);
begin
    sd <= std_logic_vector(ex_mem_reg.store_data);

    dmem_addr <= ex_mem_reg.ex_result;  -- full byte address, drop bits 1:0
    dmem_en   <= ex_mem_reg.mem.memread or ex_mem_reg.mem.memwrite;

-- case is only allowed inside a process so use a with statement
    -- replicate data into different width lanes
    with ex_mem_reg.mem.mem_size(1 downto 0) select dmem_wdata <=
        sd(7 downto 0)  & sd(7 downto 0) & sd(7 downto 0) & sd(7 downto 0) when "00",   -- SB
        sd(15 downto 0) & sd(15 downto 0)                                  when "01",   -- SH
        sd                                                                 when others; -- SW

    -- byte enable for lanes, only when store
    process(all)
        variable mask : std_logic_vector(3 downto 0);
    begin
        case ex_mem_reg.mem.mem_size(1 downto 0) is
            when "00"   => mask := std_logic_vector(shift_left(unsigned'("0001"), to_integer(addr_lo)));
            when "01"   => mask := "0011" when addr_lo(1) = '0' else "1100";
            when others => mask := "1111";
        end case;
        if ex_mem_reg.mem.memwrite = '1' then
            dmem_we <= mask;
        else
            dmem_we <= "0000";
        end if;
    end process;

    mem_wb_next <= (
        valid     => ex_mem_reg.valid,
        cur_pc => ex_mem_reg.cur_pc,
        rd        => ex_mem_reg.rd,
        ex_result => ex_mem_reg.ex_result, -- WB needs bits 1:0
        mem_size  => ex_mem_reg.mem.mem_size,
        wb        => ex_mem_reg.wb,
        inst      => ex_mem_reg.inst
    );
end Behavioral;

