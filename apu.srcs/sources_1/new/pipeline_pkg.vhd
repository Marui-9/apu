----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/06/2026 06:58:22 AM
-- Design Name: 
-- Module Name: pipeline_pkg - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.config_pkg.all;
use work.core_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


--kv260 BRAM makes data available next cycle after address is requested.
-- = bram reads are synchronous. 
package pipeline_pkg is

--grouped control signal types
    type ex_ctrl_t is record -- execute stage control signals
        alu_src_a   : ALU_SRC_A_T;
        alu_src_b   : ALU_SRC_B_T;
        aluop       : ALU_OP;
        branch_type : BRANCH_T; --input! for branch unit
    end record;

    type mem_ctrl_t is record --mem stage control signals
        memread  : std_logic; --used by hazard unit for load-use (case of RAW)
        memwrite : std_logic;
        mem_size : funct3_t;
    end record;

    type wb_ctrl_t is record --writeback select and enable
        regwrite : std_logic; --used by forwarding (checks if rd will be written or not)
        wb_sel   : WB_SEL_T;     -- EX also reads it to pick ALU result vs link
    end record;
    
          --constants for bubbles
constant EX_CTRL_NOP  : ex_ctrl_t  := (alu_src_a => SRC_A_RS1, alu_src_b => SRC_B_RS2,
                               aluop => ALU_ADD, branch_type => BR_NONE);
constant MEM_CTRL_NOP : mem_ctrl_t := (memread => '0', memwrite => '0', 
                                mem_size => "000");
constant WB_CTRL_NOP  : wb_ctrl_t  := (regwrite => '0', wb_sel => WB_ALU);
  
    
--each record is the data that every stage takes and propagates
--IF/ID
--pipeline register 1: fetch-decode
type if_id_t is record
    valid      : std_logic;
    inst: std_logic_vector(31 downto 0);
    cur_pc: unsigned(XLEN-1 downto 0); --current pc, not next one
    --mux for next pc = aluoutput if (ex.opcode=branch and ex.condition satisfied), 
    -- otherwise, pc+4
end record;

--ID/EX
--pipeline register 2: decode-execute
type id_ex_t is record
    valid      : std_logic;
    cur_pc : unsigned(XLEN-1 downto 0); -- used by branch unit for target, or alu input in auipc

    inst     : std_logic_vector(31 downto 0); -- for tracking instruction completion
    --values of first and second operand from register file, immediate from decoder
    rs1_addr : reg_addr; -- for the forwarding unit, which checks if em/mem or mem/wb hold a newer rs1
    rs2_addr : reg_addr;
    rd      : reg_addr; --travels to WB, checked by hazard unit against ID for load-use
    rs1_data : unsigned(XLEN-1 downto 0); --reg read in ID, possibly replaced by forwarding
    rs2_data : unsigned(XLEN-1 downto 0);
    imm    : unsigned(XLEN-1 downto 0);
    ex : ex_ctrl_t; --alu control values consumed here, not brought further
    mem: mem_ctrl_t; --carried to mem stage, need to be carried because pipelining
    wb : wb_ctrl_t; --carried to wb stage
    csr_en   : std_logic;                     -- instruction is a csr one (must be '0' in bubbles)
    csr_op   : funct3_t;                      -- funct3: 01 write, 10 set, 11 clear; bit 2 = immediate form
    csr_addr : std_logic_vector(11 downto 0); -- csr read in EX, compared by csr_fw_unit
end record;

--EX/MEM
-- pipeline register 3: Execute-memory
type ex_mem_t is record
    valid      : std_logic;
    cur_pc : unsigned(XLEN-1 downto 0);
    inst: std_logic_vector(31 downto 0);
    rd         : reg_addr;
    ex_result  : unsigned(XLEN-1 downto 0);--address for loads/stores, or rd value for ex, or link address
    store_data : unsigned(XLEN-1 downto 0);-- value of rs2 after forwarding = what a store writes
    mem      : mem_ctrl_t; -- consumed here
    wb       : wb_ctrl_t;
    -- csr write travelling to commit; forwarded by csr_fw_unit
    csr_we    : std_logic;                       -- write really happens (rs1/uimm /= 0 rule included)
    csr_addr  : std_logic_vector(11 downto 0);
    csr_wdata : unsigned(XLEN-1 downto 0);       -- NEW csr value (not the old one that goes to rd)
end record;

--MEM/WB
--pipeline register 4: memory-writeback
type mem_wb_t is record
    cur_pc : unsigned(XLEN-1 downto 0);
    valid: std_logic; --see what instruction has finished
    rd        : reg_addr;  --register to write; forwarding compares it too
    ex_result : unsigned(XLEN-1 downto 0);
    mem_size : funct3_t; --loads: how many bytes, sign or zero extension
    wb       : wb_ctrl_t; -- enable and select for either execution result or loaded data
     inst: std_logic_vector(31 downto 0);
    csr_we    : std_logic;                       -- csr regfile write enable at commit
    csr_addr  : std_logic_vector(11 downto 0);
    csr_wdata : unsigned(XLEN-1 downto 0);
end record;


-- bubble versions
constant if_id_bubble : if_id_t :=(
    valid    => '0',
    inst     => (others => '0'),
    cur_pc   => (others => '0')
);
constant id_ex_bubble : id_ex_t := (
    valid    => '0',
    cur_pc   => (others => '0'),
    inst     => (others => '0'),
    rs1_addr => (others => '0'),
    rs2_addr => (others => '0'),
    rd       => (others => '0'),
    rs1_data => (others => '0'),
    rs2_data => (others => '0'),
    imm      => (others => '0'),
    ex       => EX_CTRL_NOP,
    mem      => MEM_CTRL_NOP,
    wb       => WB_CTRL_NOP,
    csr_en   => '0',
    csr_op   => (others => '0'),
    csr_addr => (others => '0')
);

constant ex_mem_bubble : ex_mem_t := (
    valid    => '0',
    cur_pc   => (others => '0'),
    inst     => (others => '0'),
    rd       => (others => '0'),
    ex_result => (others => '0'),
    store_data => (others => '0'),
    mem      => MEM_CTRL_NOP,
    wb       => WB_CTRL_NOP,
    csr_we    => '0',
    csr_addr  => (others => '0'),
    csr_wdata => (others => '0')
);

constant mem_wb_bubble : mem_wb_t := (
    valid    => '0',
    cur_pc   => (others => '0'),
    rd       => (others => '0'),
    mem_size => (others => '0'),
    ex_result => (others => '0'),
    wb       => WB_CTRL_NOP,
    inst     => (others => '0'),
    csr_we    => '0',
    csr_addr  => (others => '0'),
    csr_wdata => (others => '0')
);
-- csr_mask: turns the value a csr instruction wants to write (new_csr) into the value the
-- csr will really hold after the write (what a read returns). Applied in EX so that the
-- value forwarded by csr_fw_unit is the same as what csr_regfile would read back.
--   old_csr : current csr value (already forwarded), returned for ignored writes
function csr_mask(addr    : std_logic_vector(11 downto 0);
                  new_csr : unsigned(XLEN-1 downto 0);
                  old_csr : unsigned(XLEN-1 downto 0)) return unsigned;

end pipeline_pkg;

package body pipeline_pkg is
    function csr_mask(addr    : std_logic_vector(11 downto 0);
                      new_csr : unsigned(XLEN-1 downto 0);
                      old_csr : unsigned(XLEN-1 downto 0)) return unsigned is
    begin
        case addr is
            when x"300" => return (new_csr and x"00000088") or x"00001800"; -- mstatus: MIE, MPIE; MPP = 11
            when x"304" => return new_csr and x"00000888";                  -- mie: MSIE, MTIE, MEIE
            when x"305" => return new_csr and x"FFFFFFFD";                  -- mtvec: mode 0/1 only
            when x"340" => return new_csr;                                  -- mscratch
            when x"341" => return new_csr and x"FFFFFFFC";                  -- mepc: IALIGN=32
            when x"342" => return new_csr;                                  -- mcause
            when x"343" => return new_csr;                                  -- mtval
            when x"B00" => return new_csr;                                  -- mcycle
            when x"B80" => return new_csr;                                  -- mcycleh
            -- misa, mip, mhartid, cycle/cycleh (read-only) and unimplemented: write has no effect
            when others => return old_csr;
        end case;
    end function;
end package body pipeline_pkg;

