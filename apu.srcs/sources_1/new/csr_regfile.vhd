----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11/09/2026 09:01:47 PM
-- Design Name:
-- Module Name: csr_regs - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- addr layout: [11:10] = "11" -> read-only, [9:8] = lowest privilege 
entity csr_regfile is
    Port ( 
        clk    : in  std_logic;
        rst    : in  std_logic;
        -- read port for ex stage
        raddr   : in  std_logic_vector(11 downto 0);
        -- write port for wb stage already does the
        -- csrrs/csrrc suppression to ignore the write when rs1 is 0
        --(by spec, the csr must not be written when x0 or immediate is 0)
        we       : in  std_logic;
        waddr    : in  std_logic_vector(11 downto 0); 
        wdata    : in  unsigned(XLEN-1 downto 0);
        -- external pending interrupts (from clint): bit 3 msip, 7 mtip, 11 meip
        mip_in   : in  unsigned(XLEN-1 downto 0);
        --
        rdata   : out unsigned(XLEN-1 downto 0);
        illegal  : out std_logic   -- read of unimplemented CSR, or access to read-only one
    );
end csr_regfile;

architecture Behavioral of csr_regfile is
    -- CSR addresses from spec
    constant A_MSTATUS : std_logic_vector(11 downto 0) := x"300";
    constant A_MISA  : std_logic_vector(11 downto 0) := x"301";
    constant A_MIE     : std_logic_vector(11 downto 0) := x"304";
    constant A_MTVEC  : std_logic_vector(11 downto 0) := x"305";
    constant A_MSCRATCH : std_logic_vector(11 downto 0) := x"340";
    constant A_MEPC   : std_logic_vector(11 downto 0) := x"341";
    constant A_MCAUSE : std_logic_vector(11 downto 0) := x"342";
    constant A_MTVAL : std_logic_vector(11 downto 0) := x"343";
    constant A_MIP  : std_logic_vector(11 downto 0) := x"344";
    constant A_MCYCLE : std_logic_vector(11 downto 0) := x"B00";
    constant A_MCYCLEH  : std_logic_vector(11 downto 0) := x"B80";
    constant A_CYCLE : std_logic_vector(11 downto 0) := x"C00";
    constant A_CYCLEH : std_logic_vector(11 downto 0) := x"C80";
    constant A_MHARTID : std_logic_vector(11 downto 0) := x"F14";

    -- masks: writable bits only
    constant MSTATUS_MASK : unsigned(XLEN-1 downto 0) := x"00000088"; -- MIE(3), MPIE(7)
    constant MIE_MASK : unsigned(XLEN-1 downto 0) := x"00000888"; -- MSIE, MTIE, MEIE
    constant MIP_MASK : unsigned(XLEN-1 downto 0) := x"00000888";
    constant MTVEC_MASK : unsigned(XLEN-1 downto 0) := x"FFFFFFFD"; -- mode 0/1 only
    constant MEPC_MASK : unsigned(XLEN-1 downto 0) := x"FFFFFFFC"; -- IALIGN=32
    constant MISA_VALUE : unsigned(XLEN-1 downto 0) := x"40000100"; -- MXL=32, I

    signal mstatus : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mie : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mtvec : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mscratch : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mepc : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mcause : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mtval : unsigned(XLEN-1 downto 0) := (others => '0');
    signal mcycle : unsigned(63 downto 0)      := (others => '0');

    signal mstatus_rd : unsigned(XLEN-1 downto 0);
    signal r_hit   : std_logic;-- wether raddr is a csr that is implemented
    signal w_ro : std_logic;-- wether waddr is read-only space
begin
    -- mpp is hardwired to machine mode (bits 12:11 = 11)
    mstatus_rd <= mstatus or x"00001800";

    --read
    process(raddr, mstatus_rd, mie, mtvec, mscratch, mepc, mcause, mtval, mcycle, mip_in)
    begin
        rdata <= (others => '0');
        r_hit <= '1';
        case raddr is
            when A_MSTATUS  => rdata <= mstatus_rd;
            when A_MISA     => rdata <= MISA_VALUE;
            when A_MIE      => rdata <= mie;
            when A_MTVEC    => rdata <= mtvec;
            when A_MSCRATCH => rdata <= mscratch;
            when A_MEPC     => rdata <= mepc;
            when A_MCAUSE   => rdata <= mcause;
            when A_MTVAL    => rdata <= mtval;
            when A_MIP      => rdata <= mip_in and MIP_MASK;
            when A_MCYCLE | A_CYCLE   => rdata <= mcycle(31 downto 0);
            when A_MCYCLEH | A_CYCLEH => rdata <= mcycle(63 downto 32);
            when A_MHARTID  => rdata <= (others => '0');
            when others     => r_hit <= '0';
        end case;
    end process;


    w_ro <= '1' when waddr(11 downto 10) = "11" else '0';

    -- illegal: read of unimplemented reg or a write in read-only field
    illegal <= (not r_hit) or (we and w_ro);

    --write
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mstatus <= (others => '0');
                mie   <= (others => '0');
                mtvec   <= (others => '0');
                mscratch <= (others => '0');
                mepc   <= (others => '0');
                mcause  <= (others => '0');
                mtval   <= (others => '0');
                mcycle  <= (others => '0');
            else
                mcycle <= mcycle + 1; -- a csr write to mcycle below overrides this

                if we = '1' and w_ro = '0' then
                    case waddr is
                        when A_MSTATUS  => mstatus  <= wdata and MSTATUS_MASK;
                        when A_MIE      => mie      <= wdata and MIE_MASK;
                        when A_MTVEC    => mtvec    <= wdata and MTVEC_MASK;
                        when A_MSCRATCH => mscratch <= wdata;
                        when A_MEPC     => mepc     <= wdata and MEPC_MASK;
                        when A_MCAUSE   => mcause   <= wdata;
                        when A_MTVAL    => mtval    <= wdata;
                        when A_MCYCLE   => mcycle(31 downto 0)  <= wdata;
                        when A_MCYCLEH  => mcycle(63 downto 32) <= wdata;
                        when others     => null;  -- misa, mip, mhartid: writes ignored (WARL)
                    end case;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
