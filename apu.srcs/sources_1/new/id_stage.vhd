library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pipeline_pkg.all;
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity id_stage is
    port (
        clk : in std_logic; 
        if_id_reg : in if_id_t; --valid, inst, pc
        -- regfile write port is driven by writeback stage through top level core
        wb_we       : in  std_logic;
        wb_rd_addr : in reg_addr;
        wb_rd_data  : in  unsigned(XLEN-1 downto 0);
        --
        id_ex_next  : out id_ex_t --valid, pc, inst, alu-wb-regfile inputs
        --id_ex contains
    );
end id_stage;

architecture Behavioral of id_stage is
    signal rs1_addr, rs2_addr, rd   : reg_addr;
    signal rs1_data, rs2_data, imm  : unsigned(XLEN-1 downto 0);
    signal alu_src_a   : ALU_SRC_A_T;
    signal alu_src_b   : ALU_SRC_B_T;
    signal aluop       : ALU_OP;
    signal branch_type : BRANCH_T;
    signal memread, memwrite, regwrite : std_logic;
    signal mem_size    : funct3_t;
    signal wb_sel      : WB_SEL_T;
    signal uses_rs1, uses_rs2 : std_logic;-- may drop these for out ports instead
begin
        instance_regfile: entity work.register_file
        port map (
        clk => clk,
        rs1_addr => rs1_addr,
        rs2_addr => rs2_addr,
        rs1_data => rs1_data,
        rs2_data => rs2_data,
        --from writeback
        we    => wb_we,    
        rd_addr  => wb_rd_addr,  
        rd_data => wb_rd_data
        );
        
        instance_decoder : entity work.decoder
        port map(
            --package all decoder outputs into pipeline reg formats and pass them
            inst => if_id_reg.inst,
            --for regfile
            rs1 => rs1_addr,  
            rs2 => rs2_addr,  
            rd => rd,
            --for alu
            alu_src_a => alu_src_a,
            alu_src_b => alu_src_b,
            aluop => aluop,
            imm => imm,
            --mem read & write
            memread     => memread,   
            memwrite  => memwrite,  
            mem_size => mem_size,
            regwrite => regwrite,  
            wb_sel   => wb_sel,
            --other for branch, hazards, fence, control
            branch_type => branch_type,
            uses_rs1    => uses_rs1,  
            uses_rs2  => uses_rs2,   
            fence => open, 
            ecall => open, 
            ebreak => open, 
            illegal => open   -- until traps exist
    
        );
        id_ex_next <= (
    valid => if_id_reg.valid, cur_pc => if_id_reg.cur_pc, inst => if_id_reg.inst,
            rs1_addr => rs1_addr, rs2_addr => rs2_addr, rd => rd,
            rs1_data => rs1_data, rs2_data => rs2_data, imm => imm,
            ex  => (alu_src_a => alu_src_a, alu_src_b => alu_src_b, aluop => aluop, branch_type => branch_type),
            mem => (memread => memread, memwrite => memwrite, mem_size => mem_size),
            wb  => (regwrite => regwrite, wb_sel => wb_sel)
        );
end Behavioral;