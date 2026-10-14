library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pipeline_pkg.all;
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity if_stage is
    port (
        rst       : in  std_logic;
        pc         : in  unsigned(XLEN-1 downto 0);  -- pc_reg from core
        stall        : in  std_logic;
        flush        : in  std_logic;               -- from ex stage
        branch_target: in  unsigned(XLEN-1 downto 0);
        imem_rdata  : in  std_logic_vector(31 downto 0);
        --
        pc_next    : out unsigned(XLEN-1 downto 0);   -- pc_reg and imem_addr
        if_id_next  : out if_id_t
    );
end if_stage;

architecture Behavioral of if_stage is
begin
    pc_next <= unsigned(RST_VEC) when rst   = '1' else
               branch_target     when flush = '1' else
               pc                when stall = '1' else
               pc + 4;

    if_id_next <= (valid => '1', inst => imem_rdata, cur_pc => pc);
    
end Behavioral;