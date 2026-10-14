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
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity core is
    port(
    clk : in std_logic;
    rst: in std_logic; --active high
    imem_rdata : in std_logic_vector(31 downto 0);
    dmem_rdata : in std_logic_vector(31 downto 0); --loaded data
    --
    imem_addr : out unsigned(31 downto 0);
    dmem_en : out std_logic; -- avoids pointless reads when memread or memwrite are not active.
    dmem_we : out std_logic_vector(3 downto 0);
    dmem_addr : out unsigned(31 downto 0);
    dmem_wdata : out std_logic_vector(31 downto 0)
    );
end core;

architecture Behavioral of core is
--program counter
    signal pc_reg, pc_next : unsigned(XLEN-1 downto 0);  -- PC is its own register, in no record
--pipeline registers
    signal if_id_next : if_id_t; --next is what is computed by the stage
    signal if_id_reg : if_id_t; -- reg is what the pip register contains
    signal id_ex_next : id_ex_t;
    signal id_ex_reg : id_ex_t;
    signal ex_mem_next : ex_mem_t;  
    signal ex_mem_reg    : ex_mem_t;  
    signal mem_wb_next : mem_wb_t;
    signal mem_wb_reg : mem_wb_t;
--
    signal stall         : std_logic;                    -- hazard unit -> hold PC + IF/ID, bubble ID/EX
    signal flush         : std_logic;                    -- EX taken -> bubble IF/ID + ID/EX
    signal branch_target : unsigned(XLEN-1 downto 0);    -- EX -> pc_next when flush
    signal wb_data       : unsigned(XLEN-1 downto 0);    -- WB mux -> regfile rd_data (and MEM/WB forwarding later)
begin
    instance_if: entity work.if_stage
        port map (
        rst           => rst,
        pc            => pc_reg,
        stall         => stall,
        flush         => flush,
        branch_target => branch_target,
        imem_rdata    => imem_rdata,
        pc_next       => pc_next,
        if_id_next    => if_id_next
    );
    imem_addr <= pc_next; -- outside clocked process: combinatorial and immediate
    
    instance_id : entity work.id_stage
        port map(
            clk        => clk,
            if_id_reg  => if_id_reg,
            wb_we      => mem_wb_reg.wb.regwrite,
            wb_rd_addr => mem_wb_reg.rd,
            wb_rd_data => wb_data,
            id_ex_next => id_ex_next
        );

    --//////////////////////////////
    --defaults and placeholders for what doesn't exist yet
    -- always assign bubbles and no stall or flus
    stall         <= '0';
    flush         <= '0';
    branch_target <= (others => '0');
    ex_mem_next   <= ex_mem_bubble;
    mem_wb_next   <= mem_wb_bubble;
    
    dmem_addr  <= ex_mem_reg.ex_result;
    dmem_wdata <= std_logic_vector(ex_mem_reg.store_data);
    dmem_we    <= "0000";
    dmem_en    <= ex_mem_reg.mem.memread or ex_mem_reg.mem.memwrite;
    wb_data <= mem_wb_reg.ex_result;
--///////////////////////////////////
-- every stage takes the outputs of the stage before it and makes outputs for the
-- stage after it. 
    process (clk) --reset is synchronous so not in sensitivity list
        begin 
        if rising_edge(clk) then --remember values are assigned at clock edge
            pc_reg <= pc_next;   -- reset/stall/redirect is already in pc next
            
            --one if per pipeline register for three possible cases: reset, flush, stall, normal
            
            --fetch decode does nothing if flush or reset
             if rst = '1' or flush = '1' then
                if_id_reg <= if_id_bubble;     -- for wrong instructions fetched at branch
             elsif stall = '0' then
                if_id_reg <= if_id_next;  -- if stall =1 then do nothing
             end if;                            
             --decode execute 
             if rst = '1' or flush = '1' or stall = '1' then
                id_ex_reg <= id_ex_bubble;     -- flush: wrong branch; stall: load-then-use hazard bubble
            else
                id_ex_reg <= id_ex_next;
            end if; 
            -- memory write back and ex mem
            if rst = '1' then
            -- ex_mem only bubbled on rst because bubbling on stall or flush would delete the instruction in ex
                ex_mem_reg <= ex_mem_bubble;
                mem_wb_reg <= mem_wb_bubble;
            else
                ex_mem_reg <= ex_mem_next;
                mem_wb_reg <= mem_wb_next;
            end if;
       end if;
    end process;
end Behavioral;

