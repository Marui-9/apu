library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pipeline_pkg.all;
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity ex_stage is 
    port(
        id_ex_reg : in id_ex_t;
    --later also forwarding selects
    --
        ex_mem_next : out ex_mem_t;
        taken : out std_logic;
        target : out unsigned(XLEN-1 downto 0)
    );
end entity;
architecture Behavioral of ex_stage is
    --alu needs input and output muxes
    signal op_a, op_b   : unsigned(XLEN-1 downto 0);
    signal alu_result   : unsigned(XLEN-1 downto 0);
    signal ex_result : unsigned(XLEN-1 downto 0);
    --branch unit
    signal link_s : unsigned(XLEN-1 downto 0);
    signal misaligned_s : std_logic;
begin
    --operand muxes: all alu_src_a_t and b cases
    op_a <= id_ex_reg.cur_pc when id_ex_reg.ex.alu_src_a=SRC_A_PC
            else
            (others => '0') when id_ex_reg.ex.alu_src_a=SRC_A_ZERO
            else
            id_ex_reg.rs1_data;
            
    op_b <= id_ex_reg.imm when id_ex_reg.ex.alu_src_b = SRC_B_IMM else
            id_ex_reg.rs2_data;
            
    ex_result  <= link_s when id_ex_reg.wb.wb_sel = WB_PC4 else alu_result; 

    instance_alu : entity work.alu
    port map(
        op => id_ex_reg.ex.aluop,
        R => id_ex_reg.rs1_data,
        S => id_ex_reg.rs2_data,
        F => alu_result
    );
    
    instance_branch_unit : entity work.branch_unit
    port map(
        pc => id_ex_reg.cur_pc,
        branch_type => id_ex_reg.ex.branch_type,
        rs1_val => id_ex_reg.rs1_data,
        rs2_val => id_ex_reg.rs2_data,
        imm => id_ex_reg.imm,
        --
        taken => taken,
        target => target,
        link => link_s,
        misaligned => misaligned_s
    );
    
    ex_mem_next <= (
        valid => id_ex_reg.valid,
        inst => id_ex_reg.inst,
        rd => id_ex_reg.rd,
        ex_result => ex_result,
        store_data => id_ex_reg.rs2_data,
        mem        => id_ex_reg.mem,
        wb         => id_ex_reg.wb
    );
        
end Behavioral;