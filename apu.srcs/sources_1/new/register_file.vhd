----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 10/05/2026 03:41:58 PM
-- Design Name:
-- Module Name: register_file - Behavioral
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

-- 2 asynchronous read ports, 1 synchronous write port, write-through bypass.
--register 0 always reads as zero
entity register_file is
    Generic (
        ADDR_W : positive := 5      -- 2**ADDR_W registers =32
    );
    Port (
        clk      : in  std_logic;
        -- read ports to be used by decoder (ID)
        rs1_addr : in  std_logic_vector(ADDR_W-1 downto 0);
        rs2_addr : in  std_logic_vector(ADDR_W-1 downto 0);
        rs1_data : out unsigned(XLEN-1 downto 0);
        rs2_data : out unsigned(XLEN-1 downto 0);
        -- write port, to be used by writeback mux in WB/mem
        we       : in  std_logic;
        rd_addr  : in  std_logic_vector(ADDR_W-1 downto 0);
        rd_data  : in  unsigned(XLEN-1 downto 0)
    );
end register_file;

architecture Behavioral of register_file is
    type reg_array is array (0 to 2**ADDR_W-1) of unsigned(XLEN-1 downto 0);
    -- no reset on the array, so vivad omaps it to lutram
    -- the bitstream itself loads an initial value:
    signal regs : reg_array := (others => (others => '0'));

    signal rs1_raw : unsigned(XLEN-1 downto 0);
    signal rs2_raw : unsigned(XLEN-1 downto 0);
begin

    write_port: process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                -- writes to x0 land in regs(0) too, but are never visible,
                -- read side forces it to 0
                regs(to_integer(unsigned(rd_addr))) <= rd_data;
            end if;
        end if;
    end process;
-- for hazards
    rs1_raw <= regs(to_integer(unsigned(rs1_addr)));
    rs2_raw <= regs(to_integer(unsigned(rs2_addr)));

    -- x0 masking first, then write-through bypass, then the stored value.
  -- since x0 is checked first, this prevents the bipass activating for x0
    rs1_data <= (others => '0') when unsigned(rs1_addr) = 0 else
                rd_data when we = '1' and rd_addr = rs1_addr else
                rs1_raw;

    rs2_data <= (others => '0') when unsigned(rs2_addr) = 0 else
                rd_data  when we = '1' and rd_addr = rs2_addr else
                rs2_raw;

end Behavioral;
